import Foundation
import Observation

@MainActor
@Observable
final class RewriteWorkspace {
    enum Phase: Equatable {
        case idle
        case rewriting
        case rewritten
        case failed
    }

    var sourceText = "" {
        didSet {
            guard sourceText != oldValue else { return }
            requestRevision += 1
            resetResult()
        }
    }

    var resultText = ""
    var action: RewriteAction = .improve {
        didSet {
            guard action != oldValue else { return }
            requestRevision += 1
            resetResult()
        }
    }
    private(set) var requestRevision = 0
    private(set) var phase: Phase = .idle
    private(set) var errorMessage: String?

    var canRewrite: Bool {
        sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false &&
            phase != .rewriting
    }

    func beginRewrite() -> String? {
        let text = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else {
            fail(message: L10n.string("Enter text to rewrite."))
            return nil
        }

        sourceText = text
        resultText = ""
        requestRevision += 1
        phase = .rewriting
        errorMessage = nil
        return text
    }

    func complete(result: String, requestSourceText: String) {
        guard sourceText == requestSourceText else {
            phase = .idle
            return
        }

        resultText = result
        phase = .rewritten
        errorMessage = nil
    }

    func fail(_ error: Error) {
        if error is CancellationError {
            phase = .idle
            return
        }
        fail(message: (error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
    }

    func fail(message: String) {
        phase = .failed
        errorMessage = message
    }

    func useResultAsSource() {
        guard resultText.isEmpty == false else { return }
        sourceText = resultText
        resultText = ""
        phase = .idle
        errorMessage = nil
    }

    func clear() {
        sourceText = ""
        resultText = ""
        phase = .idle
        errorMessage = nil
    }

    func replaceSource(with text: String) {
        guard sourceText != text else { return }
        sourceText = text
    }

    private func resetResult() {
        resultText = ""
        phase = .idle
        errorMessage = nil
    }
}
