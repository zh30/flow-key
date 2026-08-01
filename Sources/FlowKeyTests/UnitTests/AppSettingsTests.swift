import Foundation
import Testing
@testable import FlowKey

@MainActor
struct AppSettingsTests {
    @Test
    func testDefaultsAreSimpleAndPrivate() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = AppSettings(defaults: defaults)

        #expect(settings.defaultTargetLanguage == .english)
        #expect(settings.automaticallyCopiesTranslations == false)
        #expect(settings.quickTranslationShortcut == .optionSpace)
    }

    @Test
    func testChangesPersistAcrossInstances() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = AppSettings(defaults: defaults)

        settings.defaultTargetLanguage = .simplifiedChinese
        settings.automaticallyCopiesTranslations = true
        settings.quickTranslationShortcut = .controlOptionSpace

        let reloaded = AppSettings(defaults: defaults)
        #expect(reloaded.defaultTargetLanguage == .simplifiedChinese)
        #expect(reloaded.automaticallyCopiesTranslations)
        #expect(reloaded.quickTranslationShortcut == .controlOptionSpace)
    }

    @Test
    func testChangingShortcutNotifiesSystemBoundary() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = AppSettings(defaults: defaults)
        var observedShortcut: QuickTranslationShortcut?
        settings.quickTranslationShortcutDidChange = { shortcut in
            observedShortcut = shortcut
        }

        settings.quickTranslationShortcut = .optionT

        #expect(observedShortcut == .optionT)
    }

    private func makeDefaults() -> (UserDefaults, String) {
        let suiteName = "AppSettingsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }
}
