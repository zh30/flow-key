# FlowKey Verification Report

Date: 2026-08-01

Platform: macOS, Apple Silicon

Compiler: Apple Swift 6.4, Swift 5 language mode

## Automated verification

Command:

```bash
./script/test.sh
```

Result: 35 tests in 7 suites passed.

Covered behavior:

- Preference defaults.
- Preference persistence across instances.
- Global-shortcut defaults, persistence, and change notification.
- Empty source validation.
- Translation configuration creation.
- Same-language rejection.
- Friendly recovery after canceling a language download.
- Protection against stale translation responses.
- Request-version invalidation when a source draft changes mid-operation.
- View-owned rewrite tasks are canceled when their draft, action, panel, or window context disappears; stale responses remain revision-gated.
- Invalidating stale results when the language pair changes.
- Language and text swapping.
- Quick-capture permission recovery copy.
- Clipboard fallback state and empty-clipboard failure.
- Secure-field privacy guidance.
- Quick Action mapping and stale-result invalidation when switching transformations.
- Rewrite validation, action instructions, stale-response protection, and result reuse.
- Dictation transcript merging.
- Local terminology validation, case-insensitive duplicate prevention, atomic persistence, and removal.
- Input composition explicit-start behavior.
- Composition editing, commit, cancellation, and deduplicated candidates.

## Build verification

Command:

```bash
./script/build_and_run.sh --verify
```

Result:

- Swift target compiled successfully.
- `dist/FlowKey.app` was generated with a valid Info.plist.
- English was declared as the development language and Simplified Chinese resources were packaged in the host app and nested input-method bundle.
- The app bundle was ad-hoc signed.
- The independent `FlowKeyInputMethod` target compiled successfully.
- `FlowKey Compose.app` was embedded with a valid input-source Info.plist and its own ad-hoc signature.
- Strict deep signature verification passed for the host and nested input-method bundles.
- The nested bundle launched an `IMKServer` process successfully, then the smoke-test process was terminated.
- FlowKey launched as a foreground macOS process.

## Manual UI verification

Verified in dark appearance:

- Main window opens at 780 × 520 and supports resizing.
- Source editor receives focus at launch.
- Paste, clear, settings, language pickers, swap, and Translate controls are visible.
- Empty, ready, translating, cancellation, and error states render correctly.
- Command-Return opens Apple's language-download flow for a new language pair.
- Canceling the system download returns control to FlowKey.
- Settings opens with Command-comma and displays working preferences only.
- Menu bar scene is present while the app remains a normal Dock application.
- Option-Space registers globally and invokes FlowKey while TextEdit is frontmost.
- The compact Quick Action panel appears near the pointer as a single floating panel and exposes translation plus rewrite choices.
- The denied-permission state explains how to grant access and offers an explicit clipboard fallback.
- Opening FlowKey Settings dismisses the floating panel so it cannot cover configuration.
- Settings reports the actual “Not installed” input-method state and explains the explicit installation boundary.
- The install action is gated by a native confirmation dialog.
- The main window switches cleanly between native Translate and Rewrite workspaces.
- The active source draft follows the user when switching between Translate and Rewrite.
- The native Transform menu exposes checked Translate/Rewrite modes, follows the focused window, and updates its primary action label.
- Two simultaneous windows can hold different modes; raising each window changes the Transform menu from Translate to Improve and back without cross-window state leakage.
- Command-1 and Command-2 switch workspaces; Command-Return follows the same validation path as the visible primary button.
- The source/result divider is an accessible native splitter and accepts a changed split position.
- Copy feedback uses one cancelable reset task per workspace, preventing overlapping timers from clearing newer feedback.
- This Mac's real Foundation Models state (`deviceNotEligible`) is shown without a network fallback or fake result.
- General, Terms, and About settings use a conventional macOS toolbar; the empty terminology state and input constraints are visible.
- A process launched with `-AppleLanguages '(zh-Hans)'` localized the native menu bar, Translate and Rewrite workspaces, the real Foundation Models unavailable state, Terms settings, and the denied-permission Quick Action panel. Product and language names intentionally retain their native names.

Not performed:

- Language packages were not downloaded automatically because that changes system-managed state and was not required for structural verification.
- Accessibility access was not granted automatically. Successful selection capture and replacement still need the user-authorized TextEdit, Safari, Mail, and third-party editor matrix.
- Microphone and Speech Recognition access were not requested automatically. Live dictation remains a user-authorized acceptance step.
- The development Mac is not eligible for Apple's on-device language model, so successful rewrite generation must be accepted on eligible hardware.
- FlowKey Compose was not installed or selected automatically. End-to-end marked-text and candidate verification in first- and third-party apps remains a user-authorized acceptance step.
- Production signing and notarization were not performed.
