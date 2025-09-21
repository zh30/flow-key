# Repository Guidelines

## Project Structure & Module Organization
FlowKey ships as a Swift Package targeting macOS 14+. Primary app code lives under `Sources/FlowKey`, organized by feature folders (`App`, `Services`, `Views`, `Utilities`, `Resources`). New Swift files should sit with their peers; e.g., an input-method update belongs in `Sources/FlowKey/InputMethod`. Tests mirror the structure under `Sources/FlowKeyTests/UnitTests`, while shared docs live in `Documentation/` and reusable scripts (`run_app.sh`, `test_project.sh`, `build.sh`) stay at the repo root.

## Build, Test, and Development Commands
- `swift build`: compile the debug binary into `.build/debug/FlowKey`.
- `swift run`: rebuild if necessary and launch the SwiftUI shell for manual QA.
- `swift build -c release`: produce an optimized build; pair with `./build.sh` to bundle the app and input method.
- `./run_app.sh`: restart the debug binary in the background for UI iteration.
- `swift test`: execute the XCTest suite; run `./test_project.sh` when you need an environment sanity check.

## Coding Style & Naming Conventions
Target Swift 5.9 defaults: four-space indentation, braces on new lines for types, trailing commas on multiline literals. Use `UpperCamelCase` for types, `lowerCamelCase` for members, and lowercase enum cases. Keep UI state in SwiftUI views or `@MainActor` observable objects, and push side effects into services within `Sources/FlowKey/Services`. Store localized strings using `LocalizationKey` dictionaries and add assets to `Resources/` to receive SwiftPM bundling.

## Testing Guidelines
Unit coverage relies on XCTest. Place new specs alongside the feature under `Sources/FlowKeyTests/UnitTests`. Name methods `test<Scenario>` and adopt async expectations for translation or input workflows. Always run `swift test` locally; document any manual verification when UI behaviour changes.

## Commit & Pull Request Guidelines
Write sentence-case commit subjects focused on the primary change, and mention impacted modules plus scripts/tests executed in the body. Pull requests should explain the problem, summarize the solution, include screenshots for UI tweaks, and confirm `swift build` and `swift test` completed. Note localization or bundle updates so reviewers can validate resources and Info.plist entries.
