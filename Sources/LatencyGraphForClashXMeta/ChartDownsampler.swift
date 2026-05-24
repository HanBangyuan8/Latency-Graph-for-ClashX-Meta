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

    static func reduceAlignedBatches(
        _ records: [ProbeRecord],
        maxTotalPoints: Int,
        seriesCount: Int
    ) -> [ProbeRecord] {
        let effectiveSeriesCount = max(seriesCount, 1)
        let maxBatchCount = max(1, maxTotalPoints / effectiveSeriesCount)
        let batches = Dictionary(grouping: records, by: \.timestamp)
            .map { timestamp, records in
                ProbeRecordBatch(timestamp: timestamp, records: records)
            }
            .sorted { $0.timestamp < $1.timestamp }

        guard batches.count > maxBatchCount else {
            return batches.flatMap(\.records).sorted(by: timestampThenProxy)
        }

        let reducedBatches = reduceBatches(batches, maxBatchCount: maxBatchCount)
        return reducedBatches.flatMap(\.records).sorted(by: timestampThenProxy)
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

    private static func reduceBatches(_ batches: [ProbeRecordBatch], maxBatchCount: Int) -> [ProbeRecordBatch] {
        guard batches.count > maxBatchCount,
              let start = batches.first?.timestamp,
              let end = batches.last?.timestamp
        else {
            return batches
        }

        let bucketCount = max(1, maxBatchCount / 6)
        let duration = max(end.timeIntervalSince(start), 1)
        let bucketSize = max(duration / Double(bucketCount), 0.001)
        var buckets = Array(repeating: [ProbeRecordBatch](), count: bucketCount)

        for batch in batches {
            let rawIndex = Int(batch.timestamp.timeIntervalSince(start) / bucketSize)
            let index = min(bucketCount - 1, max(0, rawIndex))
            buckets[index].append(batch)
        }

        var selected: [Date: ProbeRecordBatch] = [:]
        selected.reserveCapacity(maxBatchCount)

        for bucket in buckets where !bucket.isEmpty {
            keep(bucket.first, in: &selected)
            keep(bucket.last, in: &selected)
            keep(bucket.min(by: batchLatencyAscending), in: &selected)
            keep(bucket.max(by: batchLatencyAscending), in: &selected)
            keep(bucket.first(where: \.hasFailure), in: &selected)
            keep(bucket.last(where: \.hasFailure), in: &selected)
        }

        return selected.values.sorted { $0.timestamp < $1.timestamp }
    }

    private static func keep(_ record: ProbeRecord?, in selected: inout [UUID: ProbeRecord]) {
        guard let record else { return }
        selected[record.id] = record
    }

    private static func keep(_ batch: ProbeRecordBatch?, in selected: inout [Date: ProbeRecordBatch]) {
        guard let batch else { return }
        selected[batch.timestamp] = batch
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

    private static func batchLatencyAscending(_ lhs: ProbeRecordBatch, _ rhs: ProbeRecordBatch) -> Bool {
        switch (lhs.maxLatency, rhs.maxLatency) {
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

    private static func timestampThenProxy(_ lhs: ProbeRecord, _ rhs: ProbeRecord) -> Bool {
        if lhs.timestamp == rhs.timestamp {
            return lhs.proxyName < rhs.proxyName
        }
        return lhs.timestamp < rhs.timestamp
    }
}

private struct ProbeRecordBatch {
    let timestamp: Date
    let records: [ProbeRecord]

    var hasFailure: Bool {
        records.contains { !$0.success }
    }

    var maxLatency: Int? {
        records.compactMap(\.latencyMs).max()
    }
}
