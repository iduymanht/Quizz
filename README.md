<div align="center">
  <h1>Quiz Pet</h1>
  <p>
    <img src="https://img.shields.io/badge/platform-macOS%2013%2B%20%C2%B7%20Windows%2010%2F11-black" alt="macOS 13+ · Windows 10/11" />
    <img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT" />
    <img src="https://img.shields.io/badge/macOS-Swift%20%C2%B7%20WebKit-orange" alt="Swift" />
    <img src="https://img.shields.io/badge/Windows-Tauri%20%C2%B7%20Rust-informational" alt="Tauri" />
  </p>
</div>

A friendly desktop pet that quizzes you. A small animated companion floats on
your screen and asks multiple‑choice questions: the question sits on a single
bar above the pet's head, with four answers arranged two on the left and two on
the right. Answer correctly and the pet cheers and thanks you; answer wrong and
it looks disappointed and shows the explanation so you learn why.

You write the questions yourself in a built‑in **Quiz Builder** — one at a time
with a form, or many at once by pasting Markdown.

## Purpose

Quiz Pet turns idle desktop time into light, spaced practice. Instead of opening
a separate study app, your questions live with a pet that gently prompts you
while you work. It is useful for memorizing vocabulary, exam prep, onboarding
checklists, or any set of facts you want to keep fresh.

The whole experience is offline and local: questions are stored on your own
machine, and no account or network connection is required.

## How it works

- A **desktop pet overlay** floats on top of your screen and presents one
  question at a time.
- Click an answer:
  - **Correct** → the pet plays a happy animation and says thanks, then moves on.
  - **Wrong** → the pet looks disappointed, reveals the correct answer, and shows
    the explanation. Click **Next** when you're ready to continue.
- Open the **Quiz Builder** (from the pet's "Soạn câu hỏi" button or the menu‑bar
  / tray menu) to add and edit questions.
- You can **change the pet** at any time from the overlay.

## Creating questions

There are two ways to add questions. Both live in the Quiz Builder, and both
save to the same place, so questions you add either way appear together.

### 1. Form tab (one question at a time)

1. Type the **question** text.
2. Fill in up to **four answers**. Tick the checkbox on the right of an answer to
   mark it correct (you can mark more than one correct answer).
3. Optionally add an **explanation** — this is shown to the player when they
   answer wrong.
4. Click **＋ Add question**. It appears in the list below, where you can edit or
   delete it later.

### 2. Markdown tab (bulk import)

Paste many questions at once using a simple Markdown format, then click
**Add all to list**. Each question starts with a heading line (`#`); answers use
`- [ ]` for wrong and `- [x]` for correct; a line starting with `>` is the
explanation.

```markdown
# What is the capital of Vietnam?
- [ ] Ho Chi Minh City
- [x] Hanoi
- [ ] Da Nang
- [ ] Hue
> Hanoi has been the capital of Vietnam since 1010 (the Ly dynasty).

# What is 2 + 2?
- [ ] 3
- [x] 4
- [ ] 5
- [ ] 22
> Basic addition: 2 + 2 = 4.
```

Use **Preview** first to check parsing and catch any invalid questions, then
import. You can also **Export** your whole set back to Markdown or JSON.

### Saving

Click **💾 Save** in the builder. Questions are written to a real file on disk so
they persist across restarts and are shared with the pet overlay:

- **macOS**: `~/Library/Application Support/Quiz/questions.json`
- **Windows**: `questions.json` in the app data directory

When you save, the pet reloads immediately — no restart needed.

## Build & run

The user interface is shared web code (HTML/CSS/JS). Each platform wraps it in a
native shell: a transparent, always‑on‑top window for the pet overlay and a
normal window for the builder.

### macOS (Swift Package)

Requirements: macOS 13+ and Swift 6 / Xcode 16.

```bash
# from the repository root
swift run              # build and launch (debug)

# release build
swift build -c release
.build/release/Quiz
```

The app runs as a menu‑bar item. Use the menu bar icon to show/hide the pet, open
the Quiz Builder, or quit.

### Windows (Tauri)

Requirements: Node.js 18+, the Rust toolchain, and the Tauri prerequisites
(WebView2 is bundled with Windows 10/11).

```bash
cd windows
npm install
npm run tauri dev      # develop with hot reload

# release installers (.nsis / .msi)
npm run tauri build
```

The main window is the transparent pet overlay; the Quiz Builder opens in a
separate window.

## Project layout

- `app/` — the shared web UI: `overlay.html` (pet + quiz), `index.html` (Quiz
  Builder), `quiz-core.js` (Markdown parsing / validation), `pet-sprite.js`
  (sprite slicing & animation), `quiz-store.js` (durable save/load), and bundled
  pets under `app/pets/`.
- `Sources/App/` — the macOS Swift shell (AppKit + WebKit) that hosts the web UI.
- `windows/` — the Windows Tauri shell (Rust + TypeScript/Vite).

## License

MIT — see [LICENSE](LICENSE). This is a fork; the original copyright notice is
kept in the license file as required. Pet sprite art is owned by its respective
creators and is not part of this repository's license.
