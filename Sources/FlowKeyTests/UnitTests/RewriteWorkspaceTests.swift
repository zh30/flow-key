import Testing
@testable import FlowKey

@MainActor
struct RewriteWorkspaceTests {
    @Test
    func testEmptyTextCannotStartRewrite() {
        let workspace = RewriteWorkspace()

        #expect(workspace.beginRewrite() == nil)
        #expect(workspace.phase == .failed)
    }

    @Test
    func testBeginRewriteTrimsText() {
        let workspace = RewriteWorkspace()
        workspace.sourceText = "  Clear this up.  "

        #expect(workspace.beginRewrite() == "Clear this up.")
        #expect(workspace.phase == .rewriting)
    }

    @Test
    func testChangingActionInvalidatesThePreviousResult() {
        let workspace = RewriteWorkspace()
        workspace.sourceText = "Original"
        workspace.complete(result: "Improved", requestSourceText: "Original")
        let previousRevision = workspace.requestRevision

        workspace.action = .shorten

        #expect(workspace.resultText.isEmpty)
        #expect(workspace.phase == .idle)
        #expect(workspace.requestRevision > previousRevision)
    }

    @Test
    func testReplacingSourceCancelsTheCurrentRewriteState() {
        let workspace = RewriteWorkspace()
        workspace.sourceText = "First"
        #expect(workspace.beginRewrite() == "First")
        let activeRevision = workspace.requestRevision

        workspace.replaceSource(with: "Second")

        #expect(workspace.phase == .idle)
        #expect(workspace.resultText.isEmpty)
        #expect(workspace.requestRevision > activeRevision)
    }

    @Test
    func testStaleRewriteDoesNotReplaceANewerDraft() {
        let workspace = RewriteWorkspace()
        workspace.sourceText = "First draft"
        #expect(workspace.beginRewrite() != nil)

        workspace.sourceText = "Second draft"
        workspace.complete(result: "First result", requestSourceText: "First draft")

        #expect(workspace.resultText.isEmpty)
        #expect(workspace.phase == .idle)
    }

    @Test
    func testResultCanBecomeTheNextSource() {
        let workspace = RewriteWorkspace()
        workspace.sourceText = "Draft"
        workspace.complete(result: "Polished", requestSourceText: "Draft")

        workspace.useResultAsSource()

        #expect(workspace.sourceText == "Polished")
        #expect(workspace.resultText.isEmpty)
        #expect(workspace.phase == .idle)
    }

    @Test
    func testRewriteActionsHaveDistinctInstructions() {
        #expect(Set(RewriteAction.allCases.map(\.instruction)).count == RewriteAction.allCases.count)
    }
}
