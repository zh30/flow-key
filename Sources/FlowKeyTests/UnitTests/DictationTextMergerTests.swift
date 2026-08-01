import Testing
@testable import FlowKey

struct DictationTextMergerTests {
    @Test
    func testTranscriptUsesExistingWhitespace() {
        #expect(
            DictationTextMerger.merge(prefix: "Existing ", transcript: "dictation") ==
                "Existing dictation"
        )
    }

    @Test
    func testTranscriptAddsASeparatorWhenNeeded() {
        #expect(
            DictationTextMerger.merge(prefix: "Existing", transcript: "dictation") ==
                "Existing dictation"
        )
    }

    @Test
    func testEmptyTranscriptPreservesTheDraft() {
        #expect(DictationTextMerger.merge(prefix: "Draft", transcript: "") == "Draft")
    }
}
