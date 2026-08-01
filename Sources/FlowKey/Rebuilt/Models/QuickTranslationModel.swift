import Foundation
import Observation

@MainActor
@Observable
final class QuickTranslationModel {
    enum ContextState: Equatable {
        case capturedSelection
        case clipboard
        case captureFailed(SelectionCaptureFailure)

        var label: String {
            switch self {
            case .capturedSelection:
                return L10n.string("Selected text")
            case .clipboard:
                return L10n.string("Clipboard text")
            case .captureFailed(let failure):
                return failure.title
            }
        }

        var message: String? {
            switch self {
            case .capturedSelection, .clipboard:
                return nil
            case .captureFailed(let failure):
                return failure.recoverySuggestion
            }
        }

        var systemImage: String {
            switch self {
            case .capturedSelection:
                return "selection.pin.in.out"
            case .clipboard:
                return "doc.on.clipboard"
            case .captureFailed(.permissionRequired):
                return "hand.raised"
            case .captureFailed(.noSelection):
                return "selection.pin.in.out"
            case .captureFailed(.secureField):
                return "lock.shield"
            case .captureFailed(.unsupportedApplication), .captureFailed(.unavailable):
                return "exclamationmark.triangle"
            }
        }
    }

    enum ActionStatus: Equatable {
        case copied
        case failed(String)
    }

    let workspace: TranslationWorkspace
    var action: QuickTransformAction = .translate {
        didSet {
            guard action != oldValue else { return }
            actionRevision += 1
            workspace.resetResult()
            actionStatus = nil
        }
    }
    private(set) var actionRevision = 0
    private(set) var contextState: ContextState = .captureFailed(.noSelection)
    private(set) var actionStatus: ActionStatus?

    @ObservationIgnored
    private var capturedSelection: CapturedSelection?

    init(targetLanguage: TranslationLanguage) {
        workspace = TranslationWorkspace(targetLanguage: targetLanguage)
    }

    var canReplaceSelection: Bool {
        capturedSelection?.canReplace == true && workspace.phase == .translated
    }

    func prepare(
        captureResult: SelectionCaptureResult,
        targetLanguage: TranslationLanguage
    ) {
        workspace.clear()
        workspace.sourceLanguage = nil
        workspace.targetLanguage = targetLanguage
        actionStatus = nil

        switch captureResult {
        case .captured(let selection):
            capturedSelection = selection
            workspace.sourceText = selection.text
            contextState = .capturedSelection
        case .failed(let failure):
            capturedSelection = nil
            contextState = .captureFailed(failure)
        }
    }

    @discardableResult
    func useClipboard(_ text: String?) -> Bool {
        guard let text, text.isEmpty == false else {
            workspace.clear()
            capturedSelection = nil
            contextState = .captureFailed(.unavailable)
            actionStatus = .failed(L10n.string("The clipboard does not contain text."))
            return false
        }

        workspace.clear()
        workspace.sourceLanguage = nil
        workspace.sourceText = text
        capturedSelection = nil
        contextState = .clipboard
        actionStatus = nil
        return true
    }

    @discardableResult
    func copyTranslation() -> Bool {
        guard workspace.translatedText.isEmpty == false else { return false }

        if Clipboard.write(workspace.translatedText) {
            actionStatus = .copied
            return true
        }

        actionStatus = .failed(L10n.string("FlowKey could not write to the clipboard."))
        return false
    }

    @discardableResult
    func replaceSelection() -> Bool {
        guard let capturedSelection, workspace.translatedText.isEmpty == false else {
            actionStatus = .failed(
                L10n.string("The original selection is no longer available.")
            )
            return false
        }

        do {
            try capturedSelection.replace(with: workspace.translatedText)
            actionStatus = nil
            return true
        } catch {
            actionStatus = .failed(error.localizedDescription)
            return false
        }
    }

    func clearActionStatus() {
        actionStatus = nil
    }
}
