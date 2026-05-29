import XCTest
@testable import AgentPetCore

final class AgentCatalogTests: XCTestCase {
    func testClaudeSupportedOthersComingSoon() {
        let byKind = Dictionary(uniqueKeysWithValues: AgentCatalog.all.map { ($0.kind, $0) })
        XCTAssertEqual(byKind[.claude]?.isSupported, true)
        XCTAssertEqual(byKind[.codex]?.isSupported, false)
        XCTAssertEqual(byKind[.codex]?.note, "Coming soon")
        XCTAssertEqual(byKind[.gemini]?.isSupported, false)
    }
}
