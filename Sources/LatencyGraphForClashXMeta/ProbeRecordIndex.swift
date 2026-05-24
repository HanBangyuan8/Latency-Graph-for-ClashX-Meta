import Foundation

struct ProbeRecordIndex {
    private(set) var allRecords: [ProbeRecord]
    private var recordsByProxy: [String: [ProbeRecord]]

    init(records: [ProbeRecord]) {
        let sortedRecords = records.sorted { $0.timestamp < $1.timestamp }
        self.allRecords = sortedRecords
        self.recordsByProxy = Self.groupSortedRecords(sortedRecords)
    }

    mutating func replace(with records: [ProbeRecord]) {
        let sortedRecords = records.sorted { $0.timestamp < $1.timestamp }
        allRecords = sortedRecords
        recordsByProxy = Self.groupSortedRecords(sortedRecords)
    }

    mutating func appending(
        _ newRecords: [ProbeRecord],
        to records: [ProbeRecord],
        retentionDays: Int,
        now: Date = Date()
    ) -> [ProbeRecord] {
        guard !newRecords.isEmpty else { return records }

        let cutoff = now.addingTimeInterval(-TimeInterval(retentionDays) * 24 * 60 * 60)
        var updatedRecords = records
        updatedRecords.reserveCapacity(records.count + newRecords.count)
        updatedRecords.append(contentsOf: newRecords)

        if !Self.isSortedByTimestamp(updatedRecords) {
            updatedRecords.sort { $0.timestamp < $1.timestamp }
        }

        let startIndex = Self.lowerBound(in: updatedRecords, cutoff: cutoff)
        if startIndex > 0 {
            updatedRecords.removeFirst(startIndex)
        }

        allRecords = updatedRecords
        appendToProxyIndex(newRecords, cutoff: cutoff)
        return updatedRecords
    }

    func stats(for proxies: [String]?, now: Date = Date()) -> StatsSummary {
        let cutoff = now.addingTimeInterval(-24 * 60 * 60)
        var totalSamples = 0
        var successCount = 0
        var failureCount = 0
        var latencySum = 0
        var latencyCount = 0
        var maxLatency: Int?
        var lastRecord: ProbeRecord?

        for series in selectedSeries(for: proxies) {
            if let candidate = series.last,
               lastRecord == nil || candidate.timestamp > lastRecord!.timestamp {
                lastRecord = candidate
            }

            let startIndex = Self.lowerBound(in: series, cutoff: cutoff)
            guard startIndex < series.count else { continue }

            for record in series[startIndex...] {
                totalSamples += 1
                if record.success {
                    successCount += 1
                    if let latency = record.latencyMs {
                        latencySum += latency
                        latencyCount += 1
                        maxLatency = max(maxLatency ?? latency, latency)
                    }
                } else {
                    failureCount += 1
                }
            }
        }

        let average = latencyCount == 0 ? nil : Double(latencySum) / Double(latencyCount)
        let availability = totalSamples == 0 ? 0 : Double(successCount) / Double(totalSamples)
        let packetLoss = totalSamples == 0 ? 0 : Double(failureCount) / Double(totalSamples)

        return StatsSummary(
            lastLatency: lastRecord?.latencyMs,
            avgLatency24h: average,
            maxLatency24h: maxLatency,
            availability24h: availability,
            packetLoss24h: packetLoss,
            totalSamples24h: totalSamples,
            failureCount24h: failureCount
        )
    }

    func chartData(
        hours: Double,
        proxies: [String]?,
        maxTotalPoints: Int,
        minimumPointsPerSeries: Int
    ) -> [ProbeRecord] {
        let cutoff = Date().addingTimeInterval(-(hours * 60 * 60))
        var filtered: [ProbeRecord] = []
        filtered.reserveCapacity(min(maxTotalPoints * 2, allRecords.count))

        for series in selectedSeries(for: proxies) {
            let startIndex = Self.lowerBound(in: series, cutoff: cutoff)
            guard startIndex < series.count else { continue }
            filtered.append(contentsOf: series[startIndex...])
        }

        if let proxies, proxies.count > 1 {
            filtered = Self.recordsInCompleteBatches(filtered, proxies: proxies)
            return ChartDownsampler.reduceAlignedBatches(
                filtered,
                maxTotalPoints: maxTotalPoints,
                seriesCount: proxies.count
            )
        }

        return ChartDownsampler.reduce(
            filtered,
            maxTotalPoints: maxTotalPoints,
            minimumPointsPerSeries: minimumPointsPerSeries
        )
    }

    func recentRecords(for proxy: String? = nil, limit: Int) -> [ProbeRecord] {
        let source = proxy.map { recordsByProxy[$0] ?? [] } ?? allRecords
        return Array(source.suffix(limit).reversed())
    }

    private func selectedSeries(for proxies: [String]?) -> [[ProbeRecord]] {
        guard let proxies, !proxies.isEmpty else {
            return [allRecords]
        }

        var seen = Set<String>()
        return proxies.compactMap { proxy in
            guard seen.insert(proxy).inserted else { return nil }
            return recordsByProxy[proxy]
        }
    }

    private mutating func appendToProxyIndex(_ newRecords: [ProbeRecord], cutoff: Date) {
        for record in newRecords where record.timestamp >= cutoff {
            var series = recordsByProxy[record.proxyName] ?? []
            let needsSorting = series.last.map { $0.timestamp > record.timestamp } ?? false
            series.append(record)
            if needsSorting {
                series.sort { $0.timestamp < $1.timestamp }
            }
            recordsByProxy[record.proxyName] = series
        }

        for proxyName in Array(recordsByProxy.keys) {
            guard var series = recordsByProxy[proxyName] else { continue }
            let startIndex = Self.lowerBound(in: series, cutoff: cutoff)
            if startIndex >= series.count {
                recordsByProxy.removeValue(forKey: proxyName)
            } else if startIndex > 0 {
                series.removeFirst(startIndex)
                recordsByProxy[proxyName] = series
            }
        }
    }

    private static func lowerBound(in records: [ProbeRecord], cutoff: Date) -> Int {
        var low = 0
        var high = records.count
        while low < high {
            let middle = (low + high) / 2
            if records[middle].timestamp < cutoff {
                low = middle + 1
            } else {
                high = middle
            }
        }
        return low
    }

    private static func recordsInCompleteBatches(_ records: [ProbeRecord], proxies: [String]) -> [ProbeRecord] {
        let requiredProxies = Set(proxies)
        guard !requiredProxies.isEmpty else { return records }

        let grouped = Dictionary(grouping: records, by: \.timestamp)
        return grouped.values
            .filter { batch in
                requiredProxies.isSubset(of: Set(batch.map(\.proxyName)))
            }
            .flatMap { $0 }
            .sorted { $0.timestamp < $1.timestamp }
    }

    private static func groupSortedRecords(_ records: [ProbeRecord]) -> [String: [ProbeRecord]] {
        Dictionary(grouping: records, by: \.proxyName)
    }

    private static func isSortedByTimestamp(_ records: [ProbeRecord]) -> Bool {
        guard records.count > 1 else { return true }
        for index in 1..<records.count where records[index - 1].timestamp > records[index].timestamp {
            return false
        }
        return true
    }
}

struct ProbeStatsCacheKey: Hashable {
    let proxies: [String]?
    let minuteBucket: Int
}

struct ProbeChartCacheKey: Hashable {
    let hours: Double
    let proxies: [String]?
    let maxTotalPoints: Int
    let minimumPointsPerSeries: Int
    let minuteBucket: Int
}
