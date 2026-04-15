import Foundation

struct RecordRetentionPolicy {
    let retentionDays: Int

    func trim(_ records: [ProbeRecord], now: Date = Date()) -> [ProbeRecord] {
        let cutoff = now.addingTimeInterval(-TimeInterval(retentionDays) * 24 * 60 * 60)
        return records.filter { $0.timestamp >= cutoff }
    }
}
