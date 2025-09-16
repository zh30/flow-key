# Repository Guidelines

## Project Structure & Module Organization
FlowKey ships as a Swift Package targeting macOS 14+. Core app code lives in `Sources/FlowKey`, split into feature folders (`App`, `InputMethod`, `Models`, `Services`, `Views`, `Utilities`, `Resources`) so keep new files with their peers. Tests reside in `Sources/FlowKeyTests/UnitTests` alongside asynchronous XCTest cases, while supporting docs are under `Documentation/` and reusable scripts live at the repository root (`run_app.sh`, `test_project.sh`, `build.sh`).
```
Sources/
  FlowKey/
    App/ … SwiftUI entry point and UI
    Services/ … localization, AI, sync and helpers
    Resources/ … processed by SwiftPM
  FlowKeyTests/UnitTests/
Documentation/
Extensions/
```

## Build, Test, and Development Commands
- `swift build` — compile the debug binary into `.build/debug/FlowKey`.
- `swift run` — build and launch the simplified SwiftUI shell for manual QA.
- `swift build -c release` — optimize for distribution; pair with `build.sh` to assemble `.app` and input-method bundles.
- `./run_app.sh` — rebuild if needed, restart the debug binary, and background the process for UI testing.
- `swift test` — execute the XCTest suite; run `./test_project.sh` when you need an environment sanity check and dependency summary.

## Coding Style & Naming Conventions
- Use Swift 5.9 defaults: four-space indentation, braces on new lines for types, trailing commas for multiline literals.
- Follow Swift naming: `UpperCamelCase` for types (`LocalizationService`), `lowerCamelCase` for methods/properties, enum cases in lowercase (see `SupportedLanguage`).
- Prefer SwiftUI and `@MainActor` observable objects for UI state; keep side effects in services (`Services/`).
- Store localized strings in dictionaries keyed by `LocalizationKey` and add assets inside `Resources/` so SwiftPM bundles them automatically.

## Testing Guidelines
- Place new tests under `Sources/FlowKeyTests/UnitTests`, mirroring the feature under test.
- Name methods `test<Scenario>` and leverage `async` expectations to match existing coverage around translation and input services.
- Run `swift test` locally before pushing; if UI or process behaviour changes, document manual verification in the PR and optionally run `./test_project.sh` for structural checks.

## Commit & Pull Request Guidelines
- Commit summaries are sentence-style and descriptive (e.g., `Add multilingual support with new README files for Arabic, Spanish, and Hindi`); keep them focused on the primary change.
- Reference related issues in the body, list major modules touched, and note any scripts/tests executed.
- Pull requests should include: concise problem statement, implementation notes, screenshots for UI tweaks, and confirmation that `swift build`/`swift test` completed. Mention localisation updates or bundle changes so reviewers can verify resources and Info.plist updates.
