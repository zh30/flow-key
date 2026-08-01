import Foundation

enum TranslationLanguage: String, CaseIterable, Codable, Identifiable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case spanish = "es"
    case hindi = "hi"
    case arabic = "ar"

    var id: String { rawValue }

    var localeLanguage: Locale.Language {
        Locale.Language(identifier: rawValue)
    }

    var displayName: String {
        Locale.current.localizedString(forIdentifier: rawValue) ?? nativeName
    }

    var nativeName: String {
        switch self {
        case .english:
            "English"
        case .simplifiedChinese:
            "简体中文"
        case .spanish:
            "Español"
        case .hindi:
            "हिन्दी"
        case .arabic:
            "العربية"
        }
    }
}
