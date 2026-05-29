import XCTest
@testable import LatencyGraphForClashXMeta

final class DatabaseManagementTests: XCTestCase {
    func testClearHistoryForSingleNodeKeepsOtherNodes() {
        let keep = ProbeRecord(
            timestamp: Date(timeIntervalSince1970: 10),
            proxyName: "B",
            target: "https://example.com",
            latencyMs: 20,
            success: true,
            errorDescription: nil
        )
        let records = [
            ProbeRecord(
                timestamp: Date(timeIntervalSince1970: 1),
                proxyName: "A",
                target: "https://example.com",
                latencyMs: 10,
                success: true,
                errorDescription: nil
            ),
            keep
        ]

        let cleared = ProbeHistoryManager.clearing(records: records, proxyName: "A")

        XCTAssertEqual(cleared, [keep])
    }

    func testClearHistoryIgnoresBlankProxyName() {
        let records = [
            ProbeRecord(
                timestamp: Date(timeIntervalSince1970: 1),
                proxyName: "A",
                target: "https://example.com",
                latencyMs: 10,
                success: true,
                errorDescription: nil
            )
        ]

        XCTAssertEqual(ProbeHistoryManager.clearing(records: records, proxyName: "  "), records)
    }
}
