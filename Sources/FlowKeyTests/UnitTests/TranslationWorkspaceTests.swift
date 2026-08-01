import Foundation
import Testing
@testable import FlowKey

@MainActor
struct TranslationWorkspaceTests {
    @Test
    func testEmptySourceCannotStartTranslation() {
        let workspace = TranslationWorkspace(targetLanguage: .simplifiedChinese)

        #expect(workspace.requestTranslation() == false)
        #expect(workspace.phase == .failed)
        #expect(workspace.errorMessage != nil)
    }

    @Test
    func testRequestTrimsInputAndCreatesConfiguration() {
        let workspace = TranslationWorkspace(targetLanguage: .simplifiedChinese)
        workspace.sourceText = "  Hello  "

        #expect(workspace.requestTranslation())
        #expect(workspace.sourceText == "Hello")
        #expect(workspace.phase == .translating)
        #expect(workspace.configuration != nil)
    }

    @Test
    func testTransformationTrimsInputAndClearsAStaleResult() {
        let workspace = TranslationWorkspace(targetLanguage: .english)
        workspace.sourceText = "Previous"
        workspace.complete(
            translatedText: "Old result",
            requestSourceText: "Previous",
            detectedSourceLanguage: nil
        )
        workspace.sourceText = "  New text  "

        #expect(workspace.beginTransformation() == "New text")
        #expect(workspace.sourceText == "New text")
        #expect(workspace.translatedText.isEmpty)
        #expect(workspace.phase == .translating)
    }

    @Test
    func testSameExplicitLanguageIsRejected() {
        let workspace = TranslationWorkspace(targetLanguage: .english)
        workspace.sourceLanguage = .english
        workspace.sourceText = "Hello"

        #expect(workspace.requestTranslation() == false)
        #expect(workspace.phase == .failed)
    }

    @Test
    func testChangingLanguageInvalidatesThePreviousResult() {
        let workspace = TranslationWorkspace(targetLanguage: .simplifiedChinese)
        workspace.sourceText = "Hello"
        workspace.complete(
            translatedText: "你好",
            requestSourceText: "Hello",
            detectedSourceLanguage: .init(identifier: "en")
        )

        workspace.targetLanguage = .spanish

        #expect(workspace.translatedText.isEmpty)
        #expect(workspace.phase == .idle)
    }

    @Test
    func testEditingSourceCancelsTheCurrentRequestState() {
        let workspace = TranslationWorkspace(targetLanguage: .simplifiedChinese)
        workspace.sourceText = "First"
        #expect(workspace.requestTranslation())
        let activeRevision = workspace.requestRevision

        workspace.replaceSource(with: "Second")

        #expect(workspace.phase == .idle)
        #expect(workspace.translatedText.isEmpty)
        #expect(workspace.requestRevision > activeRevision)
    }

    @Test
    func testCancelledDownloadExplainsHowToRecover() {
        let workspace = TranslationWorkspace(targetLanguage: .english)

        workspace.fail(CancellationError())

        #expect(workspace.phase == .failed)
        #expect(workspace.errorMessage?.contains("Translate again") == true)
    }

    @Test
    func testStaleTranslationDoesNotReplaceNewInput() {
        let workspace = TranslationWorkspace(targetLanguage: .simplifiedChinese)
        workspace.sourceText = "First"
        #expect(workspace.requestTranslation())

        workspace.sourceText = "Second"
        workspace.complete(
            translatedText: "第一",
            requestSourceText: "First",
            detectedSourceLanguage: .init(identifier: "en")
        )

        #expect(workspace.translatedText.isEmpty)
        #expect(workspace.phase == .idle)
    }

    @Test
    func testSwapMovesResultBackIntoSource() {
        let workspace = TranslationWorkspace(targetLanguage: .simplifiedChinese)
        workspace.sourceLanguage = .english
        workspace.sourceText = "Hello"
        workspace.complete(
            translatedText: "你好",
            requestSourceText: "Hello",
            detectedSourceLanguage: .init(identifier: "en")
        )

        workspace.swapLanguages()

        #expect(workspace.sourceLanguage == .simplifiedChinese)
        #expect(workspace.targetLanguage == .english)
        #expect(workspace.sourceText == "你好")
        #expect(workspace.translatedText == "Hello")
    }
}
