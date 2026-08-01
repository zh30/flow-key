# FlowKey

[简体中文](README.zh-CN.md)

FlowKey is a native macOS text workspace rebuilt around one complete user job: turn the text you have into the text you need with the fewest possible actions.

## What works now

- Real translation through Apple's Translation framework.
- Automatic source-language detection.
- English, Simplified Chinese, Spanish, Hindi, and Arabic targets.
- Native language-download, loading, success, cancellation, and error states.
- Side-by-side source and result editors with paste, copy, clear, and language swap actions.
- A draggable native split view and a Transform menu with Command-1/2 workspace switching.
- Command-Return runs the current transformation through the focused window.
- A native Rewrite workspace with Improve, Shorten, Formalize, and Proofread actions.
- Private rewriting through Apple's on-device Foundation Models framework when the Mac and system model support it; there is no server fallback.
- Click-to-start dictation through Apple's Speech framework, with explicit microphone, speech-recognition, unavailable-language, and error states.
- A focused local terminology list used only as context for on-device rewrites.
- A configurable global Quick Action shortcut (Option-Space by default).
- Selected-text capture through macOS Accessibility, with explicit permission and recovery states.
- A compact floating panel that can translate or rewrite, with explicit Copy and Replace Selection actions.
- A clipboard fallback that does not require Accessibility access.
- An optional, independently built InputMethodKit input source with explicit installation.
- A deliberate compose mode (`Control-Option-F`) with marked text, native candidates, commit, and cancel behavior; ordinary typing passes through.
- A concise menu bar entry and a dedicated Settings window.
- Native system-language UI in English and Simplified Chinese, including menus, settings, permission recovery, and the embedded input method; there is no duplicate in-app language switch.
- Persisted default target language, shortcut, and optional main-window automatic copy.
- Thirty-five focused unit tests for preferences, translation and rewrite state, quick-capture recovery, terminology persistence, dictation text merging, and input composition.

## What is intentionally not claimed yet

The app embeds a real InputMethodKit bundle, but it is not installed or enabled without an explicit user action. Production signing, notarization, and the user-authorized cross-app input-source acceptance matrix are not claimed yet. This development Mac is not eligible for Apple's on-device language model, so the real rewrite-generation path is implemented and availability-gated but cannot be accepted on this hardware. Dictation permissions and successful selected-text replacement also remain user-authorized acceptance steps. General personal knowledge and iCloud sync are intentionally absent. The old prototype code remains in `Sources/FlowKey`; the active targets compile only `Sources/FlowKey/Rebuilt`, `Sources/FlowKeyInputMethod/Rebuilt`, and the small input-method core.

See [plan.md](plan.md) for the first-principles product model and phased roadmap.

## Requirements

- macOS 15 or later.
- Rewriting requires macOS 26, an eligible Mac, Apple Intelligence, and a ready on-device model.
- Full Xcode is recommended.
- Swift Package Manager is used for the current application target.

The repository scripts also handle the current Swift 6.4 Command Line Tools installation, whose default build backend and newest SDK are incomplete for SwiftUI.

## Build, test, and run

```bash
# Build, create dist/FlowKey.app, and launch it
./script/build_and_run.sh

# Build, launch, and verify the process
./script/build_and_run.sh --verify

# Run all unit tests
./script/test.sh

# Create an optimized app bundle without launching it
./build.sh
```

The Codex desktop Run action is configured in `.codex/environments/environment.toml` and calls the same build-and-run script.

## Project structure

```text
Sources/FlowKey/Rebuilt/
├── App/        # SwiftUI scenes and app lifecycle
├── Models/     # Preferences, language options, workspace state
├── Services/   # Small macOS system boundaries
└── Views/      # Translator, menu bar, and Settings UI

Sources/FlowKeyTests/UnitTests/  # Swift Testing suites
Sources/FlowKeyInputMethod/      # Independent IMKServer executable target
Sources/FlowKeyInputMethodCore/  # Testable composition state and candidates
script/                         # Stable local build, run, and test entrypoints
```

## Privacy

FlowKey uses Apple's Translation, Foundation Models, and Speech frameworks and does not add its own language server. Accessibility access is checked only when Quick Action is invoked; it reads the current selection and, after a separate user click, can replace that same selection. Capturing a selection never modifies the clipboard. Dictation starts only after a click. Preferences are stored in `UserDefaults`; terminology is stored as a local JSON file in FlowKey's Application Support directory.
