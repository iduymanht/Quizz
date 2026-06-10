import XCTest
@testable import AgentPetCore

final class ClaudeHookPayloadTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 100)

    private func payload(_ json: String) -> ClaudeHookPayload? {
        ClaudeHookPayload.decode(from: Data(json.utf8))
    }

    func testDecodesSessionStart() {
        let event = payload(#"{"session_id":"abc","cwd":"/Users/x/proj","hook_event_name":"SessionStart"}"#)?
            .makeEvent(now: now)
        XCTAssertEqual(event?.sessionId, "abc")
        XCTAssertEqual(event?.project, "/Users/x/proj")
        XCTAssertEqual(event?.eventName, "SessionStart")
        XCTAssertEqual(event?.agentKind, .claude)
    }

    func testDecodesNotificationWithMessage() {
        let p = payload(#"{"session_id":"s","cwd":"/p","hook_event_name":"Notification","message":"needs permission"}"#)
        let event = p?.makeEvent(now: now)
        XCTAssertEqual(event?.message, "needs permission")
        XCTAssertEqual(StateMapper.state(for: .claude, eventName: event!.eventName), .waiting)
    }

    func testIgnoresUnknownFields() {
        // Real Claude payloads carry extra keys (transcript_path, stop_hook_active, ...).
        let event = payload(#"{"session_id":"s","hook_event_name":"Stop","transcript_path":"/t","stop_hook_active":false}"#)?
            .makeEvent(now: now)
        XCTAssertEqual(event?.eventName, "Stop")
        XCTAssertNil(event?.project)
    }

    func testNilWhenMissingEssentialFields() {
        XCTAssertNil(payload(#"{"cwd":"/p"}"#)?.makeEvent(now: now))
        XCTAssertNil(payload("not json"))
    }

    // MARK: - Other agents routed through ClaudeHookPayload (claudeNested style)

    func testCodexPreToolUseActivityMessage() {
        let json = #"{"session_id":"cx1","cwd":"/proj","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"npm test"}}"#
        let event = payload(json)?.makeEvent(now: now, kind: .codex)
        XCTAssertEqual(event?.agentKind, .codex)
        XCTAssertTrue(ActivityTheme.chef.running.contains(event?.message ?? ""), "got \(event?.message ?? "nil")")
    }

    func testGeminiBeforeToolActivityMessage() {
        let json = #"{"session_id":"gm1","cwd":"/proj","hook_event_name":"BeforeTool","tool_name":"run_shell_command","tool_input":{"command":"ls"}}"#
        let event = payload(json)?.makeEvent(now: now, kind: .gemini)
        XCTAssertEqual(event?.agentKind, .gemini)
        XCTAssertTrue(ActivityTheme.chef.running.contains(event?.message ?? ""), "got \(event?.message ?? "nil")")
    }
}
