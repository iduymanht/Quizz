import AppKit
import SwiftUI
import QuizCore

// MARK: - Model

struct QuizOption: Codable, Hashable {
    var text: String
    var correct: Bool
}

struct QuizQuestion: Codable, Identifiable, Hashable {
    var id: String
    var text: String
    var options: [QuizOption]
    var explanation: String
    var score: Int   // +1 per correct answer, -1 per wrong; drives which is asked next

    init(id: String = UUID().uuidString, text: String = "",
         options: [QuizOption] = [], explanation: String = "", score: Int = 0) {
        self.id = id; self.text = text; self.options = options; self.explanation = explanation; self.score = score
    }

    enum CodingKeys: String, CodingKey { case id, text, options, explanation, score }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        text = (try? c.decode(String.self, forKey: .text)) ?? ""
        options = (try? c.decode([QuizOption].self, forKey: .options)) ?? []
        explanation = (try? c.decode(String.self, forKey: .explanation)) ?? ""
        score = (try? c.decode(Int.self, forKey: .score)) ?? 0   // older files have no score
    }

    var isValid: Bool {
        let filled = options.filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty }
        return !text.trimmingCharacters(in: .whitespaces).isEmpty
            && filled.count >= 2
            && filled.contains { $0.correct }
    }
}

// MARK: - Store (shared JSON file, same one the web builder uses)

@MainActor
final class QuizStore: ObservableObject {
    static let shared = QuizStore()
    @Published var questions: [QuizQuestion] = []

    private var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = base.appendingPathComponent("Quiz", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("questions.json")
    }

    init() { load(); seedIfNeeded() }

    /// On the very first launch (no saved file yet), seed one starter question.
    private func seedIfNeeded() {
        let key = "quiz.seededDefault"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        guard questions.isEmpty else { return }
        questions = [
            QuizQuestion(
                text: "Thủ đô của Việt Nam là gì?",
                options: [
                    QuizOption(text: "TP. Hồ Chí Minh", correct: false),
                    QuizOption(text: "Hà Nội", correct: true),
                    QuizOption(text: "Đà Nẵng", correct: false),
                    QuizOption(text: "Huế", correct: false),
                ],
                explanation: "Hà Nội là thủ đô của Việt Nam từ năm 1010 (thời Lý)."
            )
        ]
        save()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let qs = try? JSONDecoder().decode([QuizQuestion].self, from: data) else { return }
        questions = qs
    }
    func save() {
        if let data = try? JSONEncoder().encode(questions) { try? data.write(to: fileURL) }
    }
    func add(_ q: QuizQuestion) { questions.append(q); save() }
    func delete(_ q: QuizQuestion) { questions.removeAll { $0.id == q.id }; save() }

    func bumpScore(id: String, by delta: Int) {
        guard let i = questions.firstIndex(where: { $0.id == id }) else { return }
        questions[i].score += delta
        save()
    }

    /// Next question to ask: among valid questions, take those with the lowest
    /// score and pick one at random (ties broken randomly).
    func pickQuestion() -> QuizQuestion? {
        let qs = questions.filter { $0.isValid }
        guard let minScore = qs.map({ $0.score }).min() else { return nil }
        return qs.filter { $0.score == minScore }.randomElement()
    }

    /// Parse bulk questions from Markdown (same format as the web builder).
    /// Robust manual parser (no regex): heading `#`, options `- [ ]` / `- [x]`
    /// (or `* [...]`), explanation lines starting with `>`.
    static func parseMarkdown(_ md: String) -> [QuizQuestion] {
        var out: [QuizQuestion] = []
        var cur: QuizQuestion?
        func push() { if let c = cur, !c.text.isEmpty { out.append(c) }; cur = nil }
        for raw in md.replacingOccurrences(of: "\r", with: "").components(separatedBy: "\n") {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("#") {
                push()
                let title = line.drop(while: { $0 == "#" }).trimmingCharacters(in: .whitespaces)
                cur = QuizQuestion(text: String(title))
            } else if (line.hasPrefix("- [") || line.hasPrefix("* [")), let close = line.firstIndex(of: "]") {
                let openIdx = line.index(line.startIndex, offsetBy: 2) // after "- "
                let inside = line[line.index(after: openIdx)..<close]  // between [ and ]
                let correct = inside.lowercased().contains("x")
                let text = String(line[line.index(after: close)...]).trimmingCharacters(in: .whitespaces)
                if cur == nil { cur = QuizQuestion(text: "") }
                cur?.options.append(QuizOption(text: text, correct: correct))
            } else if line.hasPrefix(">"), cur != nil {
                let t = String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
                let existing = cur!.explanation
                cur!.explanation = existing.isEmpty ? t : (existing + " " + t)
            }
        }
        push()
        return out
    }
}

// MARK: - Settings (random interval, in minutes)

enum QuizSettings {
    private static let minKey = "quiz.minMinutes"
    private static let maxKey = "quiz.maxMinutes"
    private static let enabledKey = "quiz.enabled"

    static var minMinutes: Double {
        get { UserDefaults.standard.object(forKey: minKey) as? Double ?? 5 }
        set { UserDefaults.standard.set(newValue, forKey: minKey) }
    }
    static var maxMinutes: Double {
        get { UserDefaults.standard.object(forKey: maxKey) as? Double ?? 15 }
        set { UserDefaults.standard.set(newValue, forKey: maxKey) }
    }
    static var enabled: Bool {
        get { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }
}

// MARK: - Controller (timer + shows the question when the pet is idle)

@MainActor
final class QuizController: ObservableObject {
    static let shared = QuizController()

    @Published private(set) var current: QuizQuestion?
    @Published private(set) var selectedIndex: Int?
    @Published private(set) var answeredWrong = false

    private var pending: DispatchWorkItem?
    private let panel = QuizPanelController()

    func start() { scheduleNext() }

    static func correctLine() -> String { QL.correct }

    private func scheduleNext() {
        pending?.cancel()
        let lo = min(QuizSettings.minMinutes, QuizSettings.maxMinutes)
        let hi = max(QuizSettings.minMinutes, QuizSettings.maxMinutes)
        let minutes = Double.random(in: lo...max(lo, hi))
        schedule(after: max(minutes * 60, 10))
    }
    private func schedule(after seconds: TimeInterval) {
        pending?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.fire() }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }

    private func fire() {
        guard QuizSettings.enabled, current == nil else { scheduleNext(); return }
        let qs = QuizStore.shared.questions.filter { $0.isValid }
        guard !qs.isEmpty else { scheduleNext(); return }
        // Only interrupt while the pet is idle; otherwise wait and retry soon.
        guard PetController.shared.mood == .idle else { schedule(after: 30); return }
        current = QuizStore.shared.pickQuestion()   // lowest-score group, random within it
        selectedIndex = nil
        answeredWrong = false
        panel.present()   // question drawn in the overlay panel; pet never resizes
    }

    func answer(_ index: Int) {
        guard let q = current, selectedIndex == nil, index < q.options.count else { return }
        selectedIndex = index
        if q.options[index].correct {
            QuizStore.shared.bumpScore(id: q.id, by: 1)                  // correct -> score +1
            PetController.shared.flashMoodOnly(.celebrate, duration: 3)  // animate only, pet stays put
            // Root bubble shows "Chính xác 💯" briefly, then the question hides.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in self?.close() }
        } else {
            QuizStore.shared.bumpScore(id: q.id, by: -1)                // wrong -> score -1
            // Pet goes sleepy FIRST, then show the explanation bubble so the
            // sleepy redraw doesn't paint the question bubble over the hint.
            PetController.shared.flashMoodOnly(.sleepy, duration: 30)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.answeredWrong = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in self?.close() }
        }
    }

    /// Manually show a question now (used by the "test" button in settings).
    func showNow() {
        guard current == nil else { return }
        guard let q = QuizStore.shared.pickQuestion() else { return }
        current = q; selectedIndex = nil; answeredWrong = false
        panel.present()
    }

    func close() {
        current = nil
        selectedIndex = nil
        answeredWrong = false
        panel.dismiss()
        scheduleNext()
    }
}

// MARK: - Floating question panel (positioned above the pet)

@MainActor
final class QuizPanelController {
    private var panel: NSPanel?
    private var followTimer: Timer?
    private let size = NSSize(width: 640, height: 380)

    func present() {
        // A wide, transparent overlay centered on the pet: the question shows in
        // the pet's bubble, two answer bubbles on each side, pet in the gap.
        let p = panel ?? {
            let np = NSPanel(contentRect: NSRect(origin: .zero, size: size),
                             styleMask: [.borderless, .nonactivatingPanel],
                             backing: .buffered, defer: false)
            np.isOpaque = false
            np.backgroundColor = .clear
            np.hasShadow = false
            np.level = .floating
            np.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            let host = NSHostingView(rootView: QuizCardView())
            host.wantsLayer = true
            host.layer?.backgroundColor = NSColor.clear.cgColor
            np.contentView = host
            panel = np
            return np
        }()
        p.setContentSize(size)
        reposition()
        p.orderFrontRegardless()
        startFollowing()   // keep the bubbles centered on the pet while it's dragged
    }

    /// Re-center the overlay on the pet's current position.
    private func reposition() {
        guard let p = panel else { return }
        if let pf = PetWindowController.shared.primaryPetFrame {
            p.setFrameOrigin(NSPoint(x: pf.midX - size.width / 2, y: pf.midY - size.height / 2))
        } else if let vf = NSScreen.main?.visibleFrame {
            p.setFrameOrigin(NSPoint(x: vf.midX - size.width / 2, y: vf.midY - size.height / 2))
        }
    }

    private func startFollowing() {
        followTimer?.invalidate()
        let t = Timer(timeInterval: 0.03, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.reposition() }
        }
        RunLoop.main.add(t, forMode: .common)   // keep firing during window drag tracking
        followTimer = t
    }

    func dismiss() {
        followTimer?.invalidate(); followTimer = nil
        panel?.orderOut(nil)
    }
}

// MARK: - Question card UI

struct QuizCardView: View {
    @ObservedObject private var quiz = QuizController.shared
    @ObservedObject private var bubbleSettings = BubbleSettings.shared

    private var q: QuizQuestion? { quiz.current }
    private var answerPt: CGFloat { bubbleSettings.fontSize.primaryPt }
    // Gap between the two answer columns tracks the pet size, so answers stay
    // close to the pet even when it's small.
    private var petGap: CGFloat { PetController.shared.petPoint + 16 }

    var body: some View {
        if let q {
            ZStack {
                // Answer bubbles flank the pet, vertically centered on it. Two
                // equal-width halves keep the pet gap centered no matter how long
                // each answer is (so both sides sit equally close to the pet).
                let half = (640 - petGap) / 2
                HStack(spacing: petGap) {
                    VStack(alignment: .trailing, spacing: 10) { answerBubble(q, 0); answerBubble(q, 1) }
                        .frame(width: half, alignment: .trailing)
                    VStack(alignment: .leading, spacing: 10) { answerBubble(q, 2); answerBubble(q, 3) }
                        .frame(width: half, alignment: .leading)
                }
                .frame(width: 640)

                // Bubble sits BELOW the pet's feet (offset down by half the pet
                // height + margin). Question / "Chính xác 💯"; on wrong, only the
                // explanation.
                Group {
                    if quiz.answeredWrong {
                        let expl = q.explanation.isEmpty
                            ? ("Đáp án đúng: " + (q.options.first { $0.correct }?.text ?? ""))
                            : q.explanation
                        bubble("💡 " + expl, bold: false)
                    } else {
                        bubble(rootText(q), bold: true)
                    }
                }
                .frame(maxWidth: 460)
                .offset(y: PetController.shared.petPoint / 2 + 44)
            }
            .frame(width: 640, height: 380)
            .preferredColorScheme(.dark)
        } else {
            Color.clear
        }
    }

    // Root bubble text: "Chính xác 💯" when answered correctly, otherwise the
    // question. (Wrong answers show only the explanation, not this bubble.)
    private func rootText(_ q: QuizQuestion) -> String {
        if let i = quiz.selectedIndex, i < q.options.count, q.options[i].correct { return QL.correct }
        return q.text
    }

    private func bubble(_ text: String, bold: Bool) -> some View {
        Text(text)
            .font(.system(size: answerPt + (bold ? 1 : 0), weight: bold ? .bold : .regular))
            .multilineTextAlignment(.center)
            .foregroundStyle(bold ? Color.white : Color.white.opacity(0.9))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.13)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12)))
            .shadow(color: .black.opacity(0.35), radius: 8, y: 3)
    }

    @ViewBuilder
    private func answerBubble(_ q: QuizQuestion, _ i: Int) -> some View {
        if i < q.options.count {
            let opt = q.options[i]
            let answered = quiz.selectedIndex != nil
            let isPicked = quiz.selectedIndex == i
            let showCorrect = answered && opt.correct
            let showWrong = answered && isPicked && !opt.correct
            Button { quiz.answer(i) } label: {
                Text(opt.text)
                    // Match the pet's chat-bubble (question) text size.
                    .font(.system(size: answerPt, weight: .medium))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: true, vertical: true)   // bubble width hugs the text
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 12).fill(
                        showCorrect ? Color.green.opacity(0.28)
                        : showWrong ? Color.red.opacity(0.28)
                        : Color(white: 0.13)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                        showCorrect ? Color.green : showWrong ? Color.red : Color.white.opacity(0.12)))
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 3)
            }
            .buttonStyle(.plain)
            .disabled(answered)
        } else {
            EmptyView()
        }
    }
}
