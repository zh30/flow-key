import Foundation
import Observation
import Translation

@MainActor
@Observable
final class TranslationWorkspace {
    enum Phase: Equatable {
        case idle
        case translating
        case translated
        case failed
    }

    var sourceText = "" {
        didSet {
            guard sourceText != oldValue else { return }
            requestRevision += 1
            resetResultWithoutInvalidatingRequest()
        }
    }

    var translatedText = ""
    var sourceLanguage: TranslationLanguage? {
        didSet {
            guard sourceLanguage != oldValue else { return }
            resetResult()
        }
    }
    var targetLanguage: TranslationLanguage {
        didSet {
            guard targetLanguage != oldValue else { return }
            resetResult()
        }
    }
    private(set) var phase: Phase = .idle
    private(set) var errorMessage: String?
    private(set) var detectedSourceLanguage: String?
    private(set) var configuration: TranslationSession.Configuration?
    private(set) var requestRevision = 0

    init(targetLanguage: TranslationLanguage = .english) {
        self.targetLanguage = targetLanguage
    }

    var canTranslate: Bool {
        sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false &&
            phase != .translating
    }

    @discardableResult
    func requestTranslation() -> Bool {
        let text = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else {
            fail(message: L10n.string("Enter text to translate."))
            return false
        }

        guard sourceLanguage != targetLanguage else {
            fail(message: L10n.string("Choose different source and target languages."))
            return false
        }

        sourceText = text
        translatedText = ""
        requestRevision += 1
        phase = .translating
        errorMessage = nil
        detectedSourceLanguage = nil

        let nextConfiguration = TranslationSession.Configuration(
            source: sourceLanguage?.localeLanguage,
            target: targetLanguage.localeLanguage
        )

        if var configuration, configuration == nextConfiguration {
            configuration.invalidate()
            self.configuration = configuration
        } else {
            configuration = nextConfiguration
        }

        return true
    }

    func beginTransformation() -> String? {
        let text = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else {
            fail(message: L10n.string("Enter text to transform."))
            return nil
        }

        sourceText = text
        translatedText = ""
        requestRevision += 1
        phase = .translating
        errorMessage = nil
        detectedSourceLanguage = nil
        return text
    }

    func complete(
        translatedText: String,
        requestSourceText: String,
        detectedSourceLanguage: Locale.Language?
    ) {
        guard sourceText == requestSourceText else {
            phase = .idle
            return
        }

        self.translatedText = translatedText
        self.detectedSourceLanguage = detectedSourceLanguage?.minimalIdentifier
        phase = .translated
        errorMessage = nil
    }

    func fail(_ error: Error) {
        if error is CancellationError || (error as NSError).code == NSUserCancelledError {
            fail(
                message: L10n.string(
                    "Language download was canceled. Translate again when you're ready."
                )
            )
            return
        }

        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        fail(message: message)
    }

    func fail(message: String) {
        phase = .failed
        errorMessage = message
    }

    func swapLanguages() {
        guard let sourceLanguage else { return }

        let previousSourceText = sourceText
        let previousTranslatedText = translatedText
        self.sourceLanguage = targetLanguage
        targetLanguage = sourceLanguage

        if previousTranslatedText.isEmpty == false {
            sourceText = previousTranslatedText
            translatedText = previousSourceText
            phase = .translated
        }

        errorMessage = nil
        detectedSourceLanguage = nil
    }

    func clear() {
        requestRevision += 1
        sourceText = ""
        translatedText = ""
        phase = .idle
        errorMessage = nil
        detectedSourceLanguage = nil
    }

    func resetResult() {
        requestRevision += 1
        resetResultWithoutInvalidatingRequest()
    }

    func replaceSource(with text: String) {
        guard sourceText != text else { return }
        sourceText = text
    }

    private func resetResultWithoutInvalidatingRequest() {
        translatedText = ""
        phase = .idle
        errorMessage = nil
        detectedSourceLanguage = nil
    }
}
