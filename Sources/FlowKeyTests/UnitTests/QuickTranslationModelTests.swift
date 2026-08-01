import Testing
@testable import FlowKey

@MainActor
struct QuickTranslationModelTests {
    @Test
    func testCaptureFailureExplainsTheRecoveryPath() {
        let model = QuickTranslationModel(targetLanguage: .english)

        model.prepare(
            captureResult: .failed(.permissionRequired),
            targetLanguage: .simplifiedChinese
        )

        #expect(model.contextState == .captureFailed(.permissionRequired))
        #expect(model.contextState.message?.contains("Privacy & Security") == true)
        #expect(model.workspace.targetLanguage == .simplifiedChinese)
        #expect(model.workspace.sourceText.isEmpty)
    }

    @Test
    func testClipboardFallbackDoesNotPretendItCanReplaceTheSelection() {
        let model = QuickTranslationModel(targetLanguage: .english)

        #expect(model.useClipboard("Clipboard text"))

        #expect(model.contextState == .clipboard)
        #expect(model.workspace.sourceText == "Clipboard text")
        #expect(model.canReplaceSelection == false)
    }

    @Test
    func testEmptyClipboardIsAnExplicitFailure() {
        let model = QuickTranslationModel(targetLanguage: .english)

        #expect(model.useClipboard(nil) == false)
        #expect(model.actionStatus == .failed("The clipboard does not contain text."))
        #expect(model.workspace.sourceText.isEmpty)
    }

    @Test
    func testSecureFieldsHaveAPrivacySpecificExplanation() {
        #expect(SelectionCaptureFailure.secureField.title.contains("private"))
        #expect(
            SelectionCaptureFailure.secureField.recoverySuggestion.contains("never reads")
        )
    }

    @Test
    func testChangingActionClearsACompletedResultAndAdvancesRevision() {
        let model = QuickTranslationModel(targetLanguage: .english)
        model.workspace.sourceText = "A sentence"
        model.workspace.complete(
            translatedText: "A better sentence",
            requestSourceText: "A sentence",
            detectedSourceLanguage: nil
        )

        model.action = .improve

        #expect(model.workspace.translatedText.isEmpty)
        #expect(model.workspace.phase == .idle)
        #expect(model.actionRevision == 1)
    }

    @Test
    func testQuickActionsMapOnlyRewriteChoicesToRewriteActions() {
        #expect(QuickTransformAction.translate.rewriteAction == nil)
        #expect(QuickTransformAction.improve.rewriteAction == .improve)
        #expect(QuickTransformAction.shorten.rewriteAction == .shorten)
        #expect(QuickTransformAction.formalize.rewriteAction == .formalize)
        #expect(QuickTransformAction.proofread.rewriteAction == .proofread)
    }
}
