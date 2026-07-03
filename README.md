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

### Build a double‑clickable `.app`

`swift build` produces a plain executable, not a `.app`. Use the bundled script
to assemble a proper menu‑bar app — it builds a **universal binary** (Apple
Silicon + Intel), embeds the icon, localizations, and the Sparkle auto‑update
framework, and ad‑hoc signs it for local use:

```bash
./scripts/build-app.sh          # release build → build/Quiz.app
./scripts/build-app.sh debug    # debug build, if you need it
```

The result is `build/Quiz.app`. Run it directly with:

```bash
open build/Quiz.app
```

### Install on macOS

Copy the app into your Applications folder, then launch it:

```bash
cp -R build/Quiz.app /Applications/
open /Applications/Quiz.app
```

Because the app is **ad‑hoc signed** (not notarized), the first launch is
blocked by Gatekeeper. Allow it once with either:

- **Right‑click** `Quiz.app` → **Open** → **Open** in the dialog, **or**
- run `xattr -dr com.apple.quarantine /Applications/Quiz.app` then open it.

Once running, Quiz lives in the **menu bar** (no Dock icon). The pet appears on
your desktop; the menu‑bar icon opens Settings, toggles the pet, or quits. To
launch it automatically at login, enable **Open at Login** in Settings.

### Distributable DMG (maintainers)

For a signed + notarized DMG you can hand to other users, see
[`scripts/release.sh`](scripts/release.sh). It requires an Apple Developer ID
and a one‑time `xcrun notarytool store-credentials` setup (documented at the top
of the script).

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
