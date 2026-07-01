<div align="center">
  <h1>Quiz Pet</h1>
  <p>
    <img src="https://img.shields.io/badge/platform-macOS%2013%2B%20%C2%B7%20Windows%2010%2F11-black" alt="macOS 13+ · Windows 10/11" />
    <img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT" />
    <img src="https://img.shields.io/badge/macOS-Swift%20%C2%B7%20SwiftUI-orange" alt="Swift" />
  </p>
</div>

A friendly desktop pet that quizzes you. A small animated companion floats on
your screen; while it is idle it will, at a random interval you choose, pop up a
multiple‑choice question — four answer bubbles flank the pet, with the question
bubble below its feet.

- **Correct** → the pet celebrates and the bubble shows “Chính xác 💯”.
- **Wrong** → the pet turns sleepy for 30 seconds and the explanation appears, so
  you learn why.

Questions are ranked by a **score**: every question starts at 0, gains +1 when
answered correctly and −1 when wrong. The pet always picks from the lowest‑score
questions, so the ones you struggle with come back more often.

## Features

- **Desktop pet overlay** — a transparent, always‑on‑top companion you can drag
  anywhere. Left‑click to pet it; right‑click for its board.
- **Idle quiz prompts** — asks a question after a random interval (configurable
  range, in minutes) whenever the pet is idle.
- **Right‑click board** with two tabs: **Stats** (level, tokens, XP…) and a
  **Scoreboard** listing every question with its score (lowest first).
- **Question builder** in Settings → Quiz: add questions with a form, or paste
  many at once in **Markdown**. Questions are saved to disk and shared with the
  pet.
- **Pick your pet** from a bundled library, resize it, toggle animation.
- **Multi‑language UI** (Vietnamese / English / 简体中文 / 繁體中文), switchable live.

## Requirements

- **macOS 13 Ventura or later**, with **Swift 6 / Xcode 16** to build from source.
- (Optional Windows build lives under [`windows/`](windows/): Tauri + Rust.)

## Build & run (macOS)

From the repository root:

```bash
# Build and run in one step (debug)
swift run

# — or — build then run the binary
swift build
.build/debug/Quiz
```

### Release build

```bash
swift build -c release
.build/release/Quiz
```

The app runs as a **menu‑bar item** (no Dock icon): the pet floats on your
desktop, and the menu‑bar icon opens Settings / toggles the pet / quits.

### Open as a normal .app (optional)

`swift build` produces a plain executable, not a double‑clickable `.app`. To make
one, wrap the release binary in a minimal bundle:

```bash
swift build -c release
APP="Quiz.app/Contents/MacOS"
mkdir -p "$APP" "Quiz.app/Contents/Resources"
cp .build/release/Quiz "$APP/Quiz"
cp -R .build/release/Quiz_Quiz.bundle "Quiz.app/Contents/Resources/" 2>/dev/null || true
cat > Quiz.app/Contents/Info.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Quiz</string>
  <key>CFBundleDisplayName</key><string>Quiz</string>
  <key>CFBundleExecutable</key><string>Quiz</string>
  <key>CFBundleIdentifier</key><string>com.quiz.app</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
open Quiz.app
```

(For distribution you would also code‑sign and notarize the bundle.)

## Windows (Tauri)

```bash
cd windows
npm install
npm run tauri dev      # develop
npm run tauri build    # release installers (.nsis / .msi)
```

## Creating questions

Open **Settings → Quiz** (menu‑bar icon → Settings). Two ways to add questions:

1. **Form** — type the question, fill up to four answers, tick the correct
   one(s), add an optional explanation, then **Add question**.
2. **Markdown** — paste many at once and click **Add all**:

```markdown
# What is the capital of Vietnam?
- [ ] Ho Chi Minh City
- [x] Hanoi
- [ ] Da Nang
- [ ] Hue
> Hanoi has been the capital of Vietnam since 1010.
```

Each question starts with `#`; answers use `- [ ]` (wrong) / `- [x]` (correct); a
line starting with `>` is the explanation (shown on a wrong answer).

Questions are stored at `~/Library/Application Support/Quiz/questions.json`. On
first launch the app seeds one starter question ("Thủ đô của Việt Nam là gì?").

## Project layout

- `Sources/App/` — the macOS app (SwiftUI + AppKit): pet overlay, quiz controller
  (`Quiz.swift`), Settings incl. the Quiz builder & Scoreboard (`QuizTab.swift`).
- `Sources/QuizCore/` — shared core.
- `app/` — bundled pet packs and shared web assets.
- `windows/` — the Windows (Tauri) build.

## License

MIT — see [LICENSE](LICENSE). This is a fork; the original copyright notice is
kept in the license file. Pet sprite art is owned by its respective creators and
is not covered by this repository's license.
