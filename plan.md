# FlowKey Product and Rebuild Plan

## Product in one sentence

FlowKey helps a Mac user turn the text they are writing into the text they want with the fewest possible actions.

The product is not a collection of AI feature demos. Translation, rewriting, voice input, personal terminology, and an input method are delivery mechanisms for the same job: transform text without breaking the user's flow.

## First-principles product model

### Core user job

1. Capture text from the current writing context.
2. Choose the intended transformation.
3. Review a trustworthy result.
4. Put the result back where the user was working.

Every feature must make one of these four steps faster, safer, or more accurate. A feature that cannot do that does not belong in the primary interface.

### Product principles

- One obvious primary action per surface.
- Never present a mock result as a working capability.
- Prefer macOS frameworks and conventions over custom infrastructure.
- Keep text local unless a user explicitly selects a network-backed provider.
- Use progressive disclosure: common actions first, advanced configuration in Settings.
- Treat keyboard, pointer, menu bar, and accessibility as first-class input methods.
- Build one complete workflow at a time, including empty, loading, success, error, and permission states.

## What the repository actually contains

| Capability | Previous claim | Verified state before rebuild | Decision |
| --- | --- | --- | --- |
| Translation | Local, online, smart translation | Compiled target returned prefixed mock text | Rebuild with Apple's Translation framework |
| Input method | Working macOS input method | Compiled target only toggled an in-memory Boolean | Build later as a real InputMethodKit target |
| Voice | Whisper recognition and commands | Replaced with click-to-start Apple Speech dictation and explicit permission states | Keep as a small source-text input aid |
| Knowledge base | Semantic personal search | Replaced with a bounded local terminology list and atomic JSON persistence | Feed only proven terms into on-device rewrite context |
| Recommendations | Context-aware suggestions | Replaced with explicit Improve, Shorten, Formalize, and Proofread actions | Keep intent visible and user-selected |
| Sync and backup | Secure iCloud sync | Excluded from the target; unfinished merge paths | Add only when real user data exists |
| Localization | Five UI languages | Manual dictionary in the simplified shell | Follow the system language with packaged English and Simplified Chinese resources; add another locale only from demonstrated user need |

## Information architecture

### Main window

- A compact Translate / Rewrite mode switch.
- A source editor shared by the user's mental model, with click-to-start dictation.
- Translation language controls only in Translate mode.
- Explicit rewrite intent only in Rewrite mode.
- One result surface and one mode-specific primary action.
- Inline progress and errors.
- A draggable native source/result split and a focused-window Transform command menu.

### Menu bar

- Open Quick Action and show its current shortcut.
- Open FlowKey.
- Open Settings.
- Quit FlowKey.

The menu bar is an entry point, not a miniature dashboard.

### Settings

- Default target language.
- Whether completed translations copy automatically.
- Configurable global Quick Action shortcut and registration status.
- Selected-text permission status and direct recovery actions.
- A focused local terminology editor.
- Optional input-method installation and actual system state.
- Clear privacy explanation.

Only settings with working behavior are shown.

## Implementation phases

### Phase 1: trustworthy translation foundation

- Build a clean Swift Package target from `Sources/FlowKey/Rebuilt`.
- Use Apple's Translation framework on macOS 15 or later.
- Implement the complete manual translation state machine.
- Add native main-window, menu-bar, and Settings scenes.
- Add isolated preference and workspace tests.
- Remove fake feature states from the executable product.

Exit criteria:

- `swift build` succeeds from a clean scratch path.
- `swift test` passes.
- A user can type, translate, copy, swap languages, clear, and recover from errors.
- No visible control claims to activate an input method, AI service, sync, or voice feature.

### Phase 2: system-wide quick translation

- Add a global shortcut with a visible, configurable binding.
- Capture selected text through a clearly explained Accessibility permission flow.
- Present a compact translation panel near the active context.
- Copy or replace text only after explicit user action.
- Test permission denied, no selection, secure fields, and unsupported applications.

Exit criteria:

- The workflow works in at least TextEdit, Safari, Mail, and a third-party editor.
- Permission and failure states tell the user exactly how to recover.

Implementation status (2026-08-01): the configurable Carbon hotkey, Accessibility selection reader, explicit replacement path, clipboard fallback, compact `NSPanel`, permission states, and unit coverage are implemented. The denied-permission path and global invocation from TextEdit are verified. The authorized TextEdit/Safari/Mail/third-party matrix remains a manual acceptance step because FlowKey will not grant itself privacy access.

### Phase 3: real input method integration

- Keep the reproducible Swift Package workflow while introducing separate host-app, input-method, and testable composition targets; move to an Xcode workspace only when production signing requires it.
- Create a real `IMKServer` entry point.
- Subclass `IMKInputController` per client session.
- Define composition, candidate, commit, and cancellation behavior.
- Share transformation contracts with the host app without sharing UI state.

Exit criteria:

- The signed input method installs and appears in macOS Input Sources.
- Activation state comes from the system, not an app Boolean.
- Text composition is verified across first-party and third-party apps.

Implementation status (2026-08-01): `FlowKeyInputMethod` is a separate executable target with a real `IMKServer` entry point and per-session `IMKInputController`. `Control-Option-F` starts deliberate marked composition, a native candidate panel exposes deterministic local variants, Return commits, Escape cancels, and unrelated typing passes through. The build embeds and signs `FlowKey Compose.app`; Settings reads Text Input Sources state and requires confirmation before copying it to the user Input Methods directory. Bundle launch is smoke-tested, but installation, enabling, and cross-app composition remain a user-authorized acceptance step.

### Phase 4: transformation actions

- Add concise rewrite actions: improve, shorten, formalize, and fix grammar.
- Reuse the same source/result workspace and insertion path.
- Introduce a provider boundary only when a real model or API is selected.
- Display privacy and cost implications before enabling a network provider.

Implementation status (2026-08-01): Improve, Shorten, Formalize, and Proofread are implemented in the main workspace and Quick Action panel through Apple's Foundation Models framework. Every request uses a fresh on-device session; availability is mapped to explicit UI states, terminology is bounded, and stale responses cannot cross an action change. There is deliberately no network provider. This Mac reports `deviceNotEligible`, so successful generation requires acceptance on eligible hardware.

### Phase 5: personal context and sync

- Add a small terminology list before attempting a general knowledge base.
- Measure whether terminology improves translation or rewrite quality.
- Persist only proven user data.
- Add CloudKit sync after the local data model and conflict rules are stable.

Implementation status (2026-08-01): the terminology slice is implemented as a maximum of 100 local entries with validation, case-insensitive duplicate prevention, atomic JSON writes, explicit deletion, and unit coverage. It is consumed only by on-device rewrite. CloudKit sync remains deferred because cross-device value and conflict rules have not been proven.

## Architecture

```text
FlowKeyApp
├── WindowGroup("translator")
│   └── FlowKeyWorkspaceView
│       ├── TranslationWorkspaceView → Apple Translation
│       ├── RewriteWorkspaceView → Apple Foundation Models
│       ├── DictationControl → Apple Speech
│       └── Clipboard (system boundary)
├── MenuBarExtra
│   └── quick action / open / settings / quit
├── SystemQuickTranslation
│   ├── GlobalShortcutService (Carbon boundary)
│   ├── AccessibilitySelectionService (selection boundary)
│   └── NSPanel → QuickTranslationView (small AppKit bridge)
├── InputMethodManager
│   └── Text Input Sources status / explicit user installation
├── FlowKeyInputMethod (separate process)
│   ├── IMKServer
│   ├── FlowKeyInputController (one per client session)
│   └── native marked text / candidates / commit / cancel
└── Settings
    ├── AppSettings (persisted preferences)
    └── TerminologyStore (local atomic JSON)
```

State ownership:

- Editor content, language pair, progress, result, and error are window-scoped.
- Default language and auto-copy are app preferences.
- Translation sessions are created by the SwiftUI translation task for the active window.
- Clipboard access is a small explicit system boundary.
- Quick Action owns a separate window-scoped workspace and never mutates the main window state.
- AppKit owns only the long-lived utility panel; SwiftUI remains the source of truth for its content.
- The main mode switch transfers the active source draft between Translate and Rewrite instead of creating two disconnected documents.
- Scene-focused command values keep Command-1/2 and Command-Return routed to the active window without coupling menu code to feature views.
- Translation tasks use SwiftUI's managed lifecycle; rewrite and copy-feedback tasks are explicitly canceled when their owning view or request becomes stale.
- The input method is a separate process and shares only a deterministic composition contract, never SwiftUI state.

## Required interaction states

| State | User sees | Recovery |
| --- | --- | --- |
| Empty | A clear prompt in the source editor | Type or paste text |
| Ready | Enabled Translate button | Press the button or Command-Return |
| Translating | Progress in result and footer | Wait; duplicate submission is disabled |
| Success | Selectable result and Copy action | Copy, swap, edit, or translate again |
| Invalid pair | Inline explanation | Choose different languages |
| Empty clipboard | Inline explanation | Copy text, then retry Paste |
| Accessibility denied | Permission explanation and actions | Allow FlowKey, return to the source app, invoke again |
| No selection | Selection-specific explanation | Select text or use the clipboard |
| Secure field | Privacy explanation, no capture | Use non-sensitive text |
| Unsupported app | Capability explanation | Copy text and use the clipboard |
| Framework error | Apple's localized error | Change pair, install language support, or retry |
| Rewrite unavailable | Exact system eligibility state | Update/enable/wait, or continue using translation |
| Dictation permission denied | Permission-specific explanation | Open the matching Privacy & Security pane |

## Explicitly not in the current executable scope

- Fake activation switches for an input method.
- Simulated model downloads or performance metrics.
- Placeholder embeddings and semantic search.
- A third-party language server or silent network fallback.
- Cloud sync before a stable local data model.
- Notifications for actions already visible in the active window.
- Custom cards, pulse animations, floating plus buttons, and version claims that do not help the text workflow.

## Verification

Automated:

- Preference defaults and persistence.
- Empty input validation.
- Same-language validation.
- Translation request configuration.
- Stale result protection.
- Language and text swapping.
- Shortcut preference persistence and live re-registration notification.
- Quick-capture permission, clipboard, and secure-field recovery states.
- Input-method composition editing, candidates, commit, and cancellation.
- Rewrite validation, intent mapping, stale-response protection, and result reuse.
- Dictation transcript merging.
- Terminology validation and persistence.

Manual:

- Window opens and resizes correctly in light and dark appearances.
- Full keyboard navigation works.
- Command-Return starts translation.
- Paste, clear, copy, swap, Settings, and menu-bar actions work.
- First-use language download and unsupported-pair errors are understandable.
- Global shortcut opens the compact panel while another app is active.
- Authorized selection capture, copy, and explicit replacement pass in TextEdit, Safari, Mail, and a third-party editor.
- User-authorized live dictation works for representative languages.
- On-device rewrite generates valid results on eligible Apple Intelligence hardware.
