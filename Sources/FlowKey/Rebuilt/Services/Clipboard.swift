import AppKit

@MainActor
enum Clipboard {
    static var text: String? {
        NSPasteboard.general.string(forType: .string)
    }

    @discardableResult
    static func write(_ text: String) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
    }
}
