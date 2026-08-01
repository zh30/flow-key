import Foundation

enum WorkspaceMode: String, CaseIterable, Identifiable {
    case translate
    case rewrite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .translate:
            return L10n.string("Translate")
        case .rewrite:
            return L10n.string("Rewrite")
        }
    }
}
