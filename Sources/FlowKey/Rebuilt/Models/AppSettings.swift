import Foundation
import Observation

@MainActor
@Observable
final class AppSettings {
    private enum Key {
        static let defaultTargetLanguage = "defaultTargetLanguage"
        static let automaticallyCopiesTranslations = "automaticallyCopiesTranslations"
        static let quickTranslationShortcut = "quickTranslationShortcut"
    }

    @ObservationIgnored
    private let defaults: UserDefaults

    @ObservationIgnored
    var quickTranslationShortcutDidChange: ((QuickTranslationShortcut) -> Void)?

    var defaultTargetLanguage: TranslationLanguage {
        didSet {
            defaults.set(defaultTargetLanguage.rawValue, forKey: Key.defaultTargetLanguage)
        }
    }

    var automaticallyCopiesTranslations: Bool {
        didSet {
            defaults.set(
                automaticallyCopiesTranslations,
                forKey: Key.automaticallyCopiesTranslations
            )
        }
    }

    var quickTranslationShortcut: QuickTranslationShortcut {
        didSet {
            defaults.set(quickTranslationShortcut.rawValue, forKey: Key.quickTranslationShortcut)
            quickTranslationShortcutDidChange?(quickTranslationShortcut)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.defaultTargetLanguage = defaults
            .string(forKey: Key.defaultTargetLanguage)
            .flatMap(TranslationLanguage.init(rawValue:)) ?? .english
        self.quickTranslationShortcut = defaults
            .string(forKey: Key.quickTranslationShortcut)
            .flatMap(QuickTranslationShortcut.init(rawValue:)) ?? .optionSpace

        if defaults.object(forKey: Key.automaticallyCopiesTranslations) == nil {
            self.automaticallyCopiesTranslations = false
        } else {
            self.automaticallyCopiesTranslations = defaults.bool(
                forKey: Key.automaticallyCopiesTranslations
            )
        }
    }
}
