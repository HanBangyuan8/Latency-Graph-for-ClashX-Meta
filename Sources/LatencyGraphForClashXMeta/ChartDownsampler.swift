import Foundation

enum ChartDownsampler {
    static func reduce(
        _ records: [ProbeRecord],
        maxTotalPoints: Int = 1_600,
        minimumPointsPerSeries: Int = 220
    ) -> [ProbeRecord] {
        guard records.count > maxTotalPoints else {
            return records.sorted { $0.timestamp < $1.timestamp }
        }

        let grouped = Dictionary(grouping: records, by: \.proxyName)
        let perProxyLimit = max(minimumPointsPerSeries, maxTotalPoints / max(grouped.count, 1))

        return grouped.values
            .flatMap { reduceSingleProxy(Array($0), maxPoints: perProxyLimit) }
            .sorted { $0.timestamp < $1.timestamp }
    }

    private static func reduceSingleProxy(_ records: [ProbeRecord], maxPoints: Int) -> [ProbeRecord] {
        let sorted = records.sorted { $0.timestamp < $1.timestamp }
        guard sorted.count > maxPoints,
              let start = sorted.first?.timestamp,
              let end = sorted.last?.timestamp
        else {
            return sorted
        }

        let bucketCount = max(1, maxPoints / 6)
        let duration = max(end.timeIntervalSince(start), 1)
        let bucketSize = max(duration / Double(bucketCount), 0.001)
        var buckets = Array(repeating: [ProbeRecord](), count: bucketCount)

        for record in sorted {
            let rawIndex = Int(record.timestamp.timeIntervalSince(start) / bucketSize)
            let index = min(bucketCount - 1, max(0, rawIndex))
            buckets[index].append(record)
        }

        var selected: [UUID: ProbeRecord] = [:]
        selected.reserveCapacity(maxPoints)

        for bucket in buckets where !bucket.isEmpty {
            keep(bucket.first, in: &selected)
            keep(bucket.last, in: &selected)
            keep(bucket.min(by: latencyAscending), in: &selected)
            keep(bucket.max(by: latencyAscending), in: &selected)

            let failures = bucket.filter { !$0.success }
            keep(failures.first, in: &selected)
            keep(failures.last, in: &selected)
        }

        return selected.values.sorted { $0.timestamp < $1.timestamp }
    }

    private static func keep(_ record: ProbeRecord?, in selected: inout [UUID: ProbeRecord]) {
        guard let record else { return }
        selected[record.id] = record
    }

    private static func latencyAscending(_ lhs: ProbeRecord, _ rhs: ProbeRecord) -> Bool {
        switch (lhs.latencyMs, rhs.latencyMs) {
        case (.some(let left), .some(let right)):
            return left < right
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            return lhs.timestamp < rhs.timestamp
        }
    }
}
