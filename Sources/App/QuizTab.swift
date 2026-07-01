import SwiftUI

/// In-app localization table for the quiz UI. Reads AppLanguage directly so it
/// always follows the language setting (the file-based .strings path is
/// unreliable in the SwiftPM run build). Views observe AppLanguage to refresh.
@MainActor
enum QL {
    private static func pick(_ vi: String, _ en: String, _ zh: String, _ zht: String) -> String {
        switch AppLanguage.shared.lang {
        case .vi: return vi
        case .en: return en
        case .zh: return zh
        case .zhHant: return zht
        case .system:
            let id = Locale.current.identifier
            if id.hasPrefix("vi") { return vi }
            if id.contains("Hant") || id.hasPrefix("zh-TW") || id.hasPrefix("zh_HK") { return zht }
            if id.hasPrefix("zh") { return zh }
            return en
        }
    }
    static var stats: String { pick("Thông số", "Stats", "状态", "狀態") }
    static var scoreboard: String { pick("Bảng điểm", "Scoreboard", "记分板", "記分板") }
    static var question: String { pick("Câu hỏi", "Question", "问题", "問題") }
    static var score: String { pick("Điểm", "Score", "分数", "分數") }
    static var correct: String { pick("Chính xác 💯", "Correct 💯", "完全正确 💯", "完全正確 💯") }
    static var useless: String { pick("Mình thật vô dụng", "I'm so useless", "我真没用", "我真沒用") }
    static var autoQuiz: String { pick("Hỏi tự động", "Auto quiz", "自动提问", "自動提問") }
    static var askIdle: String { pick("Tự hỏi khi pet đang rảnh", "Ask automatically while the pet is idle", "宠物空闲时自动提问", "寵物空閒時自動提問") }
    static var interval: String { pick("Khoảng thời gian ngẫu nhiên:", "Random interval:", "随机间隔：", "隨機間隔：") }
    static func fromMin(_ n: Int) -> String { pick("từ \(n) phút", "from \(n) min", "从 \(n) 分钟", "從 \(n) 分鐘") }
    static func toMin(_ n: Int) -> String { pick("đến \(n) phút", "to \(n) min", "到 \(n) 分钟", "到 \(n) 分鐘") }
    static var idleHelp: String { pick(
        "Khi pet ở trạng thái rảnh, sau một khoảng ngẫu nhiên trong phạm vi trên, pet sẽ đưa ra một câu hỏi.",
        "When the pet is idle, it asks a question after a random interval in the range above.",
        "宠物空闲时，会在上述范围内的随机间隔后提出一个问题。",
        "寵物空閒時，會在上述範圍內的隨機間隔後提出一個問題。") }
    static var askNow: String { pick("Thử hỏi ngay", "Ask now", "立即提问", "立即提問") }
    static var addQuestionTitle: String { pick("Thêm câu hỏi", "Add a question", "添加问题", "新增問題") }
    static var questionPlaceholder: String { pick("Nội dung câu hỏi", "Question text", "问题内容", "問題內容") }
    static func answerPlaceholder(_ l: String) -> String { pick("Đáp án \(l)", "Answer \(l)", "选项 \(l)", "選項 \(l)") }
    static var correctToggle: String { pick("đúng", "correct", "正确", "正確") }
    static var explanationPlaceholder: String { pick("Giải thích (hiện khi trả lời sai)", "Explanation (shown on a wrong answer)", "解析（答错时显示）", "解析（答錯時顯示）") }
    static var formError: String { pick(
        "Cần nội dung câu hỏi, ít nhất 2 đáp án và 1 đáp án đúng.",
        "Need a question, at least 2 answers and 1 correct answer.",
        "需要问题内容、至少 2 个选项和 1 个正确答案。",
        "需要問題內容、至少 2 個選項和 1 個正確答案。") }
    static var addBtn: String { pick("＋ Thêm câu hỏi", "＋ Add question", "＋ 添加问题", "＋ 新增問題") }
    static var bulkTitle: String { pick("Nhập hàng loạt (Markdown)", "Bulk import (Markdown)", "批量导入（Markdown）", "批次匯入（Markdown）") }
    static var bulkHelp: String { pick(
        "Mỗi câu bắt đầu bằng #, đáp án - [ ] / - [x], dòng > là giải thích.",
        "Each question starts with #; answers use - [ ] / - [x]; a > line is the explanation.",
        "每题以 # 开头；选项用 - [ ] / - [x]；以 > 开头的行是解析。",
        "每題以 # 開頭；選項用 - [ ] / - [x]；以 > 開頭的行是解析。") }
    static var addAll: String { pick("Thêm tất cả", "Add all", "全部添加", "全部新增") }
    static func listTitle(_ n: Int) -> String { pick("Danh sách câu hỏi (\(n))", "Question list (\(n))", "问题列表（\(n)）", "問題清單（\(n)）") }
    static var noQuestions: String { pick("Chưa có câu hỏi nào.", "No questions yet.", "还没有问题。", "還沒有問題。") }
    static func added(_ n: Int) -> String { pick("Đã thêm \(n) câu hỏi.", "Added \(n) questions.", "已添加 \(n) 道题。", "已新增 \(n) 道題。") }
    static var noValid: String { pick(
        "Không có câu nào hợp lệ (cần ≥2 đáp án và 1 đáp án đúng).",
        "No valid questions (need ≥2 answers and 1 correct).",
        "没有有效问题（需 ≥2 个选项和 1 个正确答案）。",
        "沒有有效問題（需 ≥2 個選項和 1 個正確答案）。") }
    static var noContent: String { pick("Chưa có nội dung để thêm.", "Nothing to add.", "没有可添加的内容。", "沒有可新增的內容。") }
    static var mdPlaceholder: String { pick(
        "# Thủ đô của Việt Nam là gì?\n- [ ] TP. Hồ Chí Minh\n- [x] Hà Nội\n- [ ] Đà Nẵng\n- [ ] Huế\n> Hà Nội là thủ đô từ năm 1010.",
        "# What is the capital of Vietnam?\n- [ ] Ho Chi Minh City\n- [x] Hanoi\n- [ ] Da Nang\n- [ ] Hue\n> Hanoi has been the capital since 1010.",
        "# 越南的首都是哪里？\n- [ ] 胡志明市\n- [x] 河内\n- [ ] 岘港\n- [ ] 顺化\n> 河内自 1010 年起为首都。",
        "# 越南的首都是哪裡？\n- [ ] 胡志明市\n- [x] 河內\n- [ ] 峴港\n- [ ] 順化\n> 河內自 1010 年起為首都。") }
}

/// The pet's right-click HUD: stats (level, tokens) + a scoreboard tab.
struct PetHUDView: View {
    var petID: String? = nil
    @State private var seg = 0
    @ObservedObject private var appLang = AppLanguage.shared

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $seg) {
                Text(QL.stats).tag(0)
                Text(QL.scoreboard).tag(1)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 12).padding(.top, 10).padding(.bottom, 6)
            Divider()
            if seg == 0 {
                PetStatsView(petID: petID)
            } else {
                ScoreboardTab().frame(width: 300, height: 340)
            }
        }
        .frame(width: 300)
        .preferredColorScheme(.dark)
    }
}

/// The word/question list with a Score column, sorted lowest first.
struct ScoreboardTab: View {
    @ObservedObject private var store = QuizStore.shared
    @ObservedObject private var appLang = AppLanguage.shared

    var body: some View {
        let sorted = store.questions.sorted {
            $0.score != $1.score ? $0.score < $1.score : $0.text < $1.text
        }
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(QL.question).font(.headline)
                Spacer()
                Text(QL.score).font(.headline)
            }.padding(.horizontal, 4)
            Divider()
            if sorted.isEmpty {
                Text(QL.noQuestions).font(.caption).foregroundStyle(.secondary).padding(.top, 8)
            }
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(sorted) { q in
                        HStack(alignment: .top) {
                            Text(q.text).font(.system(size: 13)).lineLimit(3)
                            Spacer(minLength: 12)
                            Text("\(q.score)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(q.score < 0 ? Color.red : q.score > 0 ? Color.green : Color.secondary)
                                .frame(minWidth: 32, alignment: .trailing)
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.12)))
                    }
                }
            }
        }
        .padding(16)
    }
}

/// Settings tab: schedule (random interval while the pet is idle) + question builder.
struct QuizTab: View {
    @ObservedObject private var store = QuizStore.shared
    @ObservedObject private var appLang = AppLanguage.shared

    @State private var enabled = QuizSettings.enabled
    @State private var minMin = QuizSettings.minMinutes
    @State private var maxMin = QuizSettings.maxMinutes

    @State private var qText = ""
    @State private var aText = ["", "", "", ""]
    @State private var aCorrect = [false, false, false, false]
    @State private var explanation = ""
    @State private var formError = ""

    @State private var mdText = ""
    @State private var mdStatus = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                schedule
                Divider()
                builder
                Divider()
                markdown
                Divider()
                list
            }
            .padding(16)
        }
    }

    private var schedule: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(QL.autoQuiz).font(.headline)
            Toggle(QL.askIdle, isOn: $enabled)
                .onChange(of: enabled) { QuizSettings.enabled = $0 }
            HStack {
                Text(QL.interval)
                Stepper(QL.fromMin(Int(minMin)), value: $minMin, in: 1...240)
                    .onChange(of: minMin) { QuizSettings.minMinutes = $0 }
                Stepper(QL.toMin(Int(maxMin)), value: $maxMin, in: 1...240)
                    .onChange(of: maxMin) { QuizSettings.maxMinutes = $0 }
            }
            Text(QL.idleHelp).font(.caption).foregroundStyle(.secondary)
            Button(QL.askNow) { QuizController.shared.showNow() }
        }
    }

    private var builder: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(QL.addQuestionTitle).font(.headline)
            TextField(QL.questionPlaceholder, text: $qText, axis: .vertical)
            ForEach(0..<4, id: \.self) { i in
                let letter = String(UnicodeScalar(65 + i)!)
                HStack {
                    Text(letter).frame(width: 18)
                    TextField(QL.answerPlaceholder(letter), text: $aText[i])
                    Toggle(QL.correctToggle, isOn: $aCorrect[i]).labelsHidden()
                    Text(QL.correctToggle).font(.caption).foregroundStyle(.secondary)
                }
            }
            TextField(QL.explanationPlaceholder, text: $explanation, axis: .vertical)
            if !formError.isEmpty {
                Text(formError).font(.caption).foregroundStyle(.red)
            }
            HStack {
                Spacer()
                Button(QL.addBtn) { addQuestion() }.buttonStyle(.borderedProminent)
            }
        }
    }

    private func addQuestion() {
        let opts = (0..<4).map { QuizOption(text: aText[$0].trimmingCharacters(in: .whitespaces), correct: aCorrect[$0]) }
        let q = QuizQuestion(text: qText.trimmingCharacters(in: .whitespaces),
                             options: opts.filter { !$0.text.isEmpty },
                             explanation: explanation.trimmingCharacters(in: .whitespaces))
        guard q.isValid else { formError = QL.formError; return }
        formError = ""
        store.add(q)
        qText = ""; aText = ["", "", "", ""]; aCorrect = [false, false, false, false]; explanation = ""
    }

    private var markdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(QL.bulkTitle).font(.headline)
            Text(QL.bulkHelp).font(.caption).foregroundStyle(.secondary)
            ZStack(alignment: .topLeading) {
                TextEditor(text: $mdText).font(.system(.body, design: .monospaced))
                if mdText.isEmpty {
                    Text(QL.mdPlaceholder)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary.opacity(0.55))
                        .padding(.horizontal, 5).padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 150)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.15)))
            HStack {
                Text(mdStatus).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button(QL.addAll) {
                    let all = QuizStore.parseMarkdown(mdText)
                    let valid = all.filter { $0.isValid }
                    valid.forEach { store.add($0) }
                    if valid.isEmpty {
                        mdStatus = all.isEmpty ? QL.noContent : QL.noValid
                    } else {
                        mdStatus = QL.added(valid.count)
                        mdText = ""
                    }
                }
            }
        }
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(QL.listTitle(store.questions.count)).font(.headline)
            if store.questions.isEmpty {
                Text(QL.noQuestions).font(.caption).foregroundStyle(.secondary)
            }
            ForEach(store.questions) { q in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(q.text).font(.system(size: 13, weight: .semibold))
                        ForEach(q.options.indices, id: \.self) { i in
                            Text((q.options[i].correct ? "✓ " : "○ ") + q.options[i].text)
                                .font(.caption)
                                .foregroundStyle(q.options[i].correct ? Color.green : Color.secondary)
                        }
                    }
                    Spacer()
                    Button(role: .destructive) { store.delete(q) } label: { Image(systemName: "trash") }
                        .buttonStyle(.borderless)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.12)))
            }
        }
    }
}
