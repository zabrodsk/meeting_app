# Task: Implement the AI voice input design in SwiftUI (Meeting Notes)

You are given a task to implement an existing **UI design** in the **Meeting Notes** SwiftUI app. The reference was originally specified as a React + shadcn component; **this document replaces that stack** with Swift-native equivalents.

## Target codebase

- **Framework:** SwiftUI (multiplatform: iOS, iPadOS, macOS)
- **Language:** Swift
- **Project:** `MeetingNotes/` (Xcode project generated from `project.yml`)
- **No** React, shadcn, Tailwind, TypeScript, or npm in this app.

### Project layout (defaults)

| Concern | Path |
|--------|------|
| Reusable UI components | `MeetingNotes/Views/Components/` |
| App screens / composition | `MeetingNotes/Views/` or top-level `MeetingNotes/` |
| Shared styling helpers | `MeetingNotes/Utilities/` or extensions in `MeetingNotes/Extensions/` |

**Why a dedicated Components folder:** Same idea as `/components/ui` on the web—keeps reusable controls out of screen files, avoids duplication, and matches how the Xcode target groups Swift files. Create `Views/Components/` if it does not exist.

---

## Design spec (behavior + look)

Implement a control **equivalent** to the reference `AIVoiceInput`:

### Visual

- Full-width vertical padding (`py-4` → ~16pt vertical padding around the block).
- Centered column, max content width ~`max-w-xl` (~576pt cap on wide layouts); on iPhone use nearly full width with horizontal padding.
- **Primary control:** ~64×64pt rounded rectangle (`rounded-xl` → ~12pt corner radius), centered.
  - **Idle:** SF Symbol `mic` (Lucide `Mic` equivalent), ~24pt, color **secondary label** (adapts light/dark).
  - **Active (recording):** Replace icon with a **small square** (~24pt) that **rotates slowly** (reference used ~3s per rotation); use `primary` fill for the square so it reads in light and dark mode.
  - Button background: transparent; optional hover/focus: subtle fill (`hover:bg-black/10` → `Color.primary.opacity(0.06)` in light, `Color.white.opacity(0.06)` in dark—or use `Material` sparingly).
- **Timer:** Monospaced digits, `text-sm`, below the button. Full opacity when recording, muted when idle (`text-black/30` → `.secondary` or `.opacity(0.4)` when not recording).
- **Visualizer:** Row of **48** thin vertical bars (default), ~256pt total width, ~16pt height area. Bars: very narrow width (~2pt), small gap (~2pt), rounded caps.
  - Idle: short, low-contrast bars (fixed low height).
  - Recording: bars animate height with **pulse**-like variation (reference used random heights + staggered delay per bar); use SwiftUI `TimelineView`, `phaseAnimator`, or `animation` with per-bar `delay`.
- **Caption:** Single line under visualizer—idle: **"Click to speak"** (on iOS prefer **"Tap to speak"**); recording: **"Listening..."**. `text-xs`, secondary label color.

### Interaction & state

- **Toggle recording** on tap/click of the main button (same as reference `submitted` flag).
- **Callbacks:**
  - `onStart`: when recording **starts**.
  - `onStop(duration:)`: when recording **stops**, pass elapsed seconds (`TimeInterval` or `Int` seconds—match app conventions).
- **Optional `demoMode`:** Auto cycle record/stop for previews; can be implemented with `Task` + delays or omitted if only Preview needs static mocks.
- **Configurable `visualizerBars`:** default **48**.

### SwiftUI mapping (no npm)

| Web | SwiftUI |
|-----|---------|
| `lucide-react` Mic | `Image(systemName: "mic")` |
| `cn(...)` | View modifiers + `extension View` helper if desired |
| Tailwind spacing/colors | `padding`, `frame`, semantic `Color` / `foregroundStyle` |
| `dark:` variants | Automatic with `.primary` / `.secondary` / asset colors, or `@Environment(\.colorScheme)` |
| `animate-spin` | `.rotationEffect` + `withAnimation` or `Animation.linear(duration: 3).repeatForever` |

**Do not** add Unsplash or stock images for this component; the reference did not require imagery.

---

## Files to add

1. **`MeetingNotes/Views/Components/AIVoiceInput.swift`**
   - Public API roughly:
     - `onStart: (() -> Void)?`
     - `onStop: ((TimeInterval) -> Void)?` or `((Int) -> Void)?` for seconds
     - `visualizerBars: Int = 48`
     - `demoMode: Bool = false`
     - `className` → SwiftUI: optional `View` extension or ignore; use `var body: some View` + trailing `modifier` if needed.
   - Wire internal timer to match reference: increment every **1 second** while “recording”.

2. **Integration point**
   - Replace or compose with existing `IdleView` / `RecordingView` in `ContentView.swift`, or embed `AIVoiceInput` and connect to existing `AudioRecorder` (`start` / `stop`) and `UploadQueue`.

3. **Preview / demo (optional)**
   - `AIVoiceInput` `#Preview` or small `AIVoiceInputDemo` struct in the same file or `MeetingNotes/Views/AIVoiceInputDemo.swift` showing last few stop durations in a list (mirror `demo.tsx` intent).

---

## Implementation guidelines

1. Analyze the reference structure: button, timer, bar row, caption—reproduce in a `VStack` / `HStack`.
2. List bindings: `isRecording` (or internal state), elapsed `time`, optional demo loop.
3. No extra “context providers”; use `@EnvironmentObject` only if the app already injects `AudioRecorder`—prefer **callbacks** for a dumb presentational component, parent connects to `AudioRecorder`.
4. **Questions to resolve before coding**
   - What props/callbacks does the parent pass? (Usually: bridge to `AudioRecorder` + upload queue.)
   - Any global state beyond local recording? (Queue is separate.)
   - Icons: SF Symbol `mic` only; no asset catalog SVGs required.
   - **Responsive:** cap max width on iPad/Mac; full width minus padding on iPhone.
   - **Best place:** Main screen center stack, replacing the current idle/recording split if product wants one unified control.

## Steps to integrate

0. Create `Views/Components/` if missing; add `AIVoiceInput.swift`.
1. No package installs—SwiftUI + AVFoundation already in the app.
2. Skip Unsplash; no image assets for this UI.
3. Use **SF Symbols** for the microphone; use `Canvas` or small `RoundedRectangle` views for the rotating stop indicator and bars.

## Acceptance

- Matches the reference layout: mic / spinner, `MM:SS` timer, 48-bar strip, caption line.
- Respects Light/Dark Mode without hard-coded black/white only (semantic colors).
- `onStart` / `onStop(duration:)` fire at the correct transitions.
- Builds for **MeetingNotes** iOS and macOS targets without platform-specific APIs inside the component except where needed (e.g. use `#if os(iOS)` only if `AudioRecorder` requires it—recording is already split in `AudioRecorder`).
