import Foundation

enum RewriteAction: String, CaseIterable, Identifiable {
    case improve
    case shorten
    case formalize
    case proofread

    var id: String { rawValue }

    var title: String {
        switch self {
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

    var instruction: String {
        switch self {
        case .improve:
            return "Improve clarity and flow while preserving the original meaning and tone."
        case .shorten:
            return "Make the text concise without removing facts, commitments, or necessary context."
        case .formalize:
            return "Use a professional, polished tone while preserving the original meaning."
        case .proofread:
            return "Fix grammar, spelling, punctuation, and awkward phrasing without otherwise changing the text."
        }
    }
}
