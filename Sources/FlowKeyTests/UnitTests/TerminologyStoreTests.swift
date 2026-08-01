import Foundation
import Testing
@testable import FlowKey

@MainActor
struct TerminologyStoreTests {
    @Test
    func testTermsPersistAcrossInstances() {
        let storageURL = makeStorageURL()
        defer { try? FileManager.default.removeItem(at: storageURL.deletingLastPathComponent()) }
        let store = TerminologyStore(storageURL: storageURL)

        #expect(store.add(term: "FlowKey", guidance: "Keep unchanged"))

        let reloaded = TerminologyStore(storageURL: storageURL)
        #expect(reloaded.entries.map(\.term) == ["FlowKey"])
        #expect(reloaded.entries.first?.guidance == "Keep unchanged")
    }

    @Test
    func testDuplicateTermsAreRejectedCaseInsensitively() {
        let storageURL = makeStorageURL()
        defer { try? FileManager.default.removeItem(at: storageURL.deletingLastPathComponent()) }
        let store = TerminologyStore(storageURL: storageURL)
        #expect(store.add(term: "FlowKey", guidance: ""))

        #expect(store.add(term: "flowkey", guidance: "") == false)
        #expect(store.entries.count == 1)
        #expect(store.lastErrorMessage?.contains("already") == true)
    }

    @Test
    func testRemoveIsPersisted() {
        let storageURL = makeStorageURL()
        defer { try? FileManager.default.removeItem(at: storageURL.deletingLastPathComponent()) }
        let store = TerminologyStore(storageURL: storageURL)
        #expect(store.add(term: "FlowKey", guidance: ""))
        let entry = store.entries[0]

        #expect(store.remove(entry))
        #expect(TerminologyStore(storageURL: storageURL).entries.isEmpty)
    }

    private func makeStorageURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("TerminologyStoreTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("terminology.json", isDirectory: false)
    }
}
