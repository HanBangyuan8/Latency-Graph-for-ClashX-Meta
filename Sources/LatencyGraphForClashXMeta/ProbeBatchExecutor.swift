import Foundation

struct ProbeBatchConfiguration: Sendable {
    let sampleCount: Int
    let sampleConcurrencyLimit: Int
    let baseURLString: String
    let secret: String
    let target: String
    let timeoutMs: Int
}

struct ProbeBatchExecutor: Sendable {
    let client: ClashAPIClient
    let proxyConcurrencyLimit: Int

    func run(proxyNames: [String], configuration: ProbeBatchConfiguration) async -> [ProbeBatchResult] {
        let concurrencyLimit = max(1, proxyConcurrencyLimit)
        if proxyNames.count > concurrencyLimit {
            var results: [ProbeBatchResult] = []
            results.reserveCapacity(proxyNames.count)
            for chunk in proxyNames.chunked(into: concurrencyLimit) {
                results.append(contentsOf: await run(proxyNames: chunk, configuration: configuration))
            }
            return ordered(results, by: proxyNames)
        }

        return await withTaskGroup(of: ProbeBatchResult.self, returning: [ProbeBatchResult].self) { group in
            for proxyName in proxyNames {
                group.addTask {
                    do {
                        let delay = try await stableDelay(proxyName: proxyName, configuration: configuration)
                        return ProbeBatchResult(proxyName: proxyName, latencyMs: delay, errorDescription: nil)
                    } catch {
                        return ProbeBatchResult(proxyName: proxyName, latencyMs: nil, errorDescription: error.localizedDescription)
                    }
                }
            }

            var results: [ProbeBatchResult] = []
            results.reserveCapacity(proxyNames.count)
            for await result in group {
                results.append(result)
            }
            return ordered(results, by: proxyNames)
        }
    }

    private func stableDelay(proxyName: String, configuration: ProbeBatchConfiguration) async throws -> Int {
        let sampleCount = max(1, configuration.sampleCount)
        let sampleConcurrencyLimit = max(1, configuration.sampleConcurrencyLimit)

        if sampleCount > sampleConcurrencyLimit {
            var allResults: [DelaySampleResult] = []
            allResults.reserveCapacity(sampleCount)
            var remaining = sampleCount
            while remaining > 0 {
                let currentCount = min(sampleConcurrencyLimit, remaining)
                allResults.append(contentsOf: await runSamples(count: currentCount, proxyName: proxyName, configuration: configuration))
                remaining -= currentCount
            }
            return try bestDelay(from: allResults)
        }

        return try await bestDelay(from: runSamples(count: sampleCount, proxyName: proxyName, configuration: configuration))
    }

    private func runSamples(count: Int, proxyName: String, configuration: ProbeBatchConfiguration) async -> [DelaySampleResult] {
        await withTaskGroup(of: DelaySampleResult.self, returning: [DelaySampleResult].self) { group in
            for _ in 0 ..< count {
                group.addTask {
                    do {
                        let delay = try await client.testDelay(
                            baseURLString: configuration.baseURLString,
                            secret: configuration.secret,
                            proxyName: proxyName,
                            target: configuration.target,
                            timeoutMs: configuration.timeoutMs
                        )
                        return DelaySampleResult(latencyMs: delay, errorDescription: nil)
                    } catch {
                        return DelaySampleResult(latencyMs: nil, errorDescription: error.localizedDescription)
                    }
                }
            }

            var results: [DelaySampleResult] = []
            results.reserveCapacity(count)
            for await result in group {
                results.append(result)
            }
            return results
        }
    }

    private func bestDelay(from results: [DelaySampleResult]) throws -> Int {
        let delays = results.compactMap(\.latencyMs)
        guard let bestDelay = delays.min() else {
            throw AppError.custom(results.compactMap(\.errorDescription).last ?? "全部探测失败")
        }
        return bestDelay
    }

    private func ordered(_ results: [ProbeBatchResult], by proxyNames: [String]) -> [ProbeBatchResult] {
        results.sorted { lhs, rhs in
            (proxyNames.firstIndex(of: lhs.proxyName) ?? .max) < (proxyNames.firstIndex(of: rhs.proxyName) ?? .max)
        }
    }
}
