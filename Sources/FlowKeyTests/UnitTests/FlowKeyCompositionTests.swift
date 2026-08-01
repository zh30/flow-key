import FlowKeyInputMethodCore
import Testing

struct FlowKeyCompositionTests {
    @Test
    func testCompositionRequiresAnExplicitStart() {
        var composition = FlowKeyComposition()

        composition.append("ignored")

        #expect(composition.isActive == false)
        #expect(composition.text.isEmpty)
    }

    @Test
    func testCompositionSupportsEditingAndCommit() {
        var composition = FlowKeyComposition()
        composition.start()
        composition.append("FlowKeu")
        composition.deleteBackward()
        composition.append("y")

        let committed = composition.commit()

        #expect(committed == "FlowKey")
        #expect(composition.isActive == false)
        #expect(composition.text.isEmpty)
    }

    @Test
    func testCandidatesAreStableAndDeduplicated() {
        var composition = FlowKeyComposition()
        composition.start()
        composition.append("flow key")

        #expect(composition.candidates == ["flow key", "FLOW KEY", "Flow Key"])
    }

    @Test
    func testCancelNeverCommitsBufferedText() {
        var composition = FlowKeyComposition()
        composition.start()
        composition.append("private draft")

        composition.cancel()

        #expect(composition.commit() == nil)
        #expect(composition.text.isEmpty)
    }
}
