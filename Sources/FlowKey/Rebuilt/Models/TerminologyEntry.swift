import Foundation

struct TerminologyEntry: Codable, Equatable, Identifiable {
    let id: UUID
    var term: String
    var guidance: String

    init(id: UUID = UUID(), term: String, guidance: String) {
        self.id = id
        self.term = term
        self.guidance = guidance
    }
}
