import Foundation

actor ProbePersistenceWorker {
    private let store = ProbeStore()
    private var scheduledSave: Task<Void, Never>?

    func save(records: [ProbeRecord]) {
        scheduledSave?.cancel()
        scheduledSave = nil
        store.save(records: records)
    }

    func scheduleSave(records: [ProbeRecord], debounceNanoseconds: UInt64) {
        scheduledSave?.cancel()
        scheduledSave = Task { [store] in
            if debounceNanoseconds > 0 {
                try? await Task.sleep(nanoseconds: debounceNanoseconds)
            }
            guard !Task.isCancelled else { return }
            store.save(records: records)
        }
    }
}
