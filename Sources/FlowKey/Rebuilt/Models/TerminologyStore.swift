import Foundation
import Observation

@MainActor
@Observable
final class TerminologyStore {
    enum StoreError: Error, LocalizedError {
        case emptyTerm
        case termTooLong
        case guidanceTooLong
        case duplicateTerm
        case entryLimitReached

        var errorDescription: String? {
            switch self {
            case .emptyTerm:
                return L10n.string("Enter a term.")
            case .termTooLong:
                return L10n.string("Terms can contain at most 80 characters.")
            case .guidanceTooLong:
                return L10n.string("Guidance can contain at most 240 characters.")
            case .duplicateTerm:
                return L10n.string("That term is already in the list.")
            case .entryLimitReached:
                return L10n.string(
                    "FlowKey supports up to 100 focused terminology entries."
                )
            }
        }
    }

    private(set) var entries: [TerminologyEntry] = []
    private(set) var lastErrorMessage: String?

    @ObservationIgnored
    private let storageURL: URL

    convenience init() {
        self.init(storageURL: TerminologyStore.defaultStorageURL)
    }

    init(storageURL: URL) {
        self.storageURL = storageURL
        load()
    }

    @discardableResult
    func add(term: String, guidance: String) -> Bool {
        do {
            let normalizedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedGuidance = guidance.trimmingCharacters(in: .whitespacesAndNewlines)
            try validate(term: normalizedTerm, guidance: normalizedGuidance)

            var updatedEntries = entries
            updatedEntries.append(
                TerminologyEntry(term: normalizedTerm, guidance: normalizedGuidance)
            )
            updatedEntries.sort {
                $0.term.localizedCaseInsensitiveCompare($1.term) == .orderedAscending
            }
            try persist(updatedEntries)
            entries = updatedEntries
            lastErrorMessage = nil
            return true
        } catch {
            lastErrorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func remove(_ entry: TerminologyEntry) -> Bool {
        do {
            let updatedEntries = entries.filter { $0.id != entry.id }
            try persist(updatedEntries)
            entries = updatedEntries
            lastErrorMessage = nil
            return true
        } catch {
            lastErrorMessage = error.localizedDescription
            return false
        }
    }

    func clearError() {
        lastErrorMessage = nil
    }

    private func validate(term: String, guidance: String) throws {
        guard term.isEmpty == false else { throw StoreError.emptyTerm }
        guard term.count <= 80 else { throw StoreError.termTooLong }
        guard guidance.count <= 240 else { throw StoreError.guidanceTooLong }
        guard entries.count < 100 else { throw StoreError.entryLimitReached }
        guard entries.contains(where: { $0.term.caseInsensitiveCompare(term) == .orderedSame }) == false else {
            throw StoreError.duplicateTerm
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }

        do {
            let data = try Data(contentsOf: storageURL)
            entries = try JSONDecoder().decode([TerminologyEntry].self, from: data)
            entries.sort {
                $0.term.localizedCaseInsensitiveCompare($1.term) == .orderedAscending
            }
        } catch {
            lastErrorMessage = L10n.format(
                "FlowKey could not read the terminology file: %@",
                error.localizedDescription
            )
        }
    }

    private func persist(_ entries: [TerminologyEntry]) throws {
        try FileManager.default.createDirectory(
            at: storageURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(entries).write(to: storageURL, options: .atomic)
    }

    private static var defaultStorageURL: URL {
        let baseURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support", isDirectory: true)

        return baseURL
            .appendingPathComponent("FlowKey", isDirectory: true)
            .appendingPathComponent("terminology.json", isDirectory: false)
    }
}
