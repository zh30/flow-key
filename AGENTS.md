# Repository Guidelines

## Project Structure & Module Organization
FlowKey is a Swift Package targeting macOS 14 or later. The executable target lives under `Sources/FlowKey`, with features grouped into `App/`, `Services/`, `Views/`, and `InputMethod/`. Shared assets belong in `Sources/FlowKey/Resources`, while long-form docs sit in `Documentation/`. Tests mirror the source tree under `Sources/FlowKeyTests/UnitTests`, so add new specs beside the code they exercise.

## Build, Test, and Development Commands
Use `swift build` to compile the debug binary at `.build/debug/FlowKey`. Run `swift run` for a rebuild plus interactive SwiftUI shell. `./run_app.sh` rebuilds if needed, terminates any running instance, and relaunches the debug app. Execute `swift build -c release` for an optimized binary, and pair it with `./build.sh` to assemble the distributable bundle. Run `swift test` for XCTest coverage; fall back to `./test_project.sh` when environments drift.

## Coding Style & Naming Conventions
Follow Swift 5.9 defaults: four spaces per indent, braces on new lines for types, trailing commas in multiline literals. Name types in UpperCamelCase, members in lowerCamelCase, and enum cases in lowercase. Keep SwiftUI state in the view or an `@MainActor` observable object, and route side effects through services in `Sources/FlowKey/Services`. Localized strings belong in `LocalizationService` dictionaries, and new assets must be added to `Resources/` for bundling.

## Testing Guidelines
Tests use XCTest with async expectations for translation and speech flows. Name methods `test<Scenario>` and colocate mocks with their features under `Sources/FlowKeyTests`. Always run `swift test` before committing, and document any manual UI checks in your change description.

## Commit & Pull Request Guidelines
Write sentence-case commit subjects that capture the primary change, then mention touched modules and executed scripts in the body (e.g., "Run: swift test"). Pull requests should state the issue, summarize the solution, link verification steps, and attach screenshots or recordings for UI changes. Call out localization and resource updates so reviewers can validate bundle contents and Info.plist edits.

## Security & Configuration Tips
Never commit secrets. Use environment variables or the system keychain for credentials, and document mock values in `Documentation/`. Guard new network-facing code against missing entitlements and surface errors through the existing logging utilities.
