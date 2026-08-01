import Foundation

public struct FlowKeyComposition: Equatable {
    public private(set) var isActive = false
    public private(set) var text = ""

    public init() {}

    public mutating func start() {
        isActive = true
        text = ""
    }

    public mutating func append(_ input: String) {
        guard isActive else { return }
        text.append(contentsOf: input)
    }

    public mutating func deleteBackward() {
        guard isActive, text.isEmpty == false else { return }
        text.removeLast()
    }

    @discardableResult
    public mutating func commit(candidate: String? = nil) -> String? {
        guard isActive else { return nil }

        let committedText = candidate ?? text
        isActive = false
        text = ""
        return committedText
    }

    public mutating func cancel() {
        isActive = false
        text = ""
    }

    public var candidates: [String] {
        guard isActive, text.isEmpty == false else { return [] }

        let proposed = [
            text,
            text.uppercased(),
            text.lowercased(),
            text.capitalized,
        ]
        var seen = Set<String>()
        return proposed.filter { seen.insert($0).inserted }
    }
}
