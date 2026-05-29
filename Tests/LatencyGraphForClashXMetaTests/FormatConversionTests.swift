import XCTest
@testable import LatencyGraphForClashXMeta

final class FormatConversionTests: XCTestCase {
    func testCSVExportEscapesCommasQuotesAndNewlines() {
        let record = ProbeRecord(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            timestamp: Date(timeIntervalSince1970: 1_700_000_000.123),
            proxyName: "Proxy, \"A\"",
            target: "https://example.com/generate_204",
            latencyMs: 42,
            success: true,
            errorDescription: "line 1\nline 2"
        )

        let csv = ProbeRecordCSVFormatter.csv(records: [record])

        XCTAssertTrue(csv.hasPrefix("timestamp,proxy_name,target,latency_ms,success,error_description\n"))
        XCTAssertTrue(csv.contains("\"Proxy, \"\"A\"\"\""))
        XCTAssertTrue(csv.contains("\"line 1\nline 2\""))
        XCTAssertTrue(csv.hasSuffix("\n"))
    }

    func testCSVExportUsesEmptyLatencyForFailures() {
        let record = ProbeRecord(
            timestamp: Date(timeIntervalSince1970: 1_700_000_100),
            proxyName: "DIRECT",
            target: "https://example.com",
            latencyMs: nil,
            success: false,
            errorDescription: "HTTP 504"
        )

        let csv = ProbeRecordCSVFormatter.csv(records: [record])

        XCTAssertTrue(csv.contains(",DIRECT,https://example.com,,false,HTTP 504\n"))
    }
}
