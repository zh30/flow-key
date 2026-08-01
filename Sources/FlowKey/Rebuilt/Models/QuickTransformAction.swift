import Foundation

enum QuickTransformAction: String, CaseIterable, Identifiable {
    case translate
    case improve
    case shorten
    case formalize
    case proofread

    var id: String { rawValue }

    var title: String {
        switch self {
        case .translate:
            return L10n.string("Translate")
        case .improve:
            return L10n.string("Improve")
        case .shorten:
            return L10n.string("Shorten")
        case .formalize:
            return L10n.string("Formalize")
        case .proofread:
            return L10n.string("Proofread")
        }
    }

    var systemImage: String {
        switch self {
        case .translate:
            return "character.bubble"
        case .improve:
            return "wand.and.sparkles"
        case .shorten:
            return "text.badge.minus"
        case .formalize:
            return "briefcase"
        case .proofread:
            return "checkmark.circle"
        }
    }

    var rewriteAction: RewriteAction? {
        switch self {
        case .translate:
            return nil
        case .improve:
            return .improve
        case .shorten:
            return .shorten
        case .formalize:
            return .formalize
        case .proofread:
            return .proofread
        }
    }
}
