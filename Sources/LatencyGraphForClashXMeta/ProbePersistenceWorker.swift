import Foundation

actor ProbePersistenceWorker {
    private let store = ProbeStore()

    func save(records: [ProbeRecord]) {
        store.save(records: records)
    }
}
