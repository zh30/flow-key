import Foundation

enum QuickTranslationShortcut: String, CaseIterable, Identifiable {
    case optionSpace
    case controlSpace
    case optionT
    case controlOptionSpace
    case disabled

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .optionSpace:
            return L10n.string("Option-Space")
        case .controlSpace:
            return L10n.string("Control-Space")
        case .optionT:
            return L10n.string("Option-T")
        case .controlOptionSpace:
            return L10n.string("Control-Option-Space")
        case .disabled:
            return L10n.string("Off")
        }
    }

    var symbols: String {
        switch self {
        case .optionSpace:
            return "⌥ Space"
        case .controlSpace:
            return "⌃ Space"
        case .optionT:
            return "⌥ T"
        case .controlOptionSpace:
            return "⌃⌥ Space"
        case .disabled:
            return L10n.string("Off")
        }
    }
}
