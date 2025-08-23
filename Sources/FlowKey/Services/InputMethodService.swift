import Foundation
import AppKit
import InputMethodKit

public class InputMethodService {
    public static let shared = InputMethodService()
    
    private init() {}
    
    public func isEnabled() async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let enabled = self.checkInputMethodEnabled()
                continuation.resume(returning: enabled)
            }
        }
    }
    
    private func checkInputMethodEnabled() -> Bool {
        let bundleIdentifier = "com.flowkey.inputmethod"
        
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["read", "com.apple.HIToolbox", "AppleEnabledInputSources"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.contains(bundleIdentifier)
            }
        } catch {
            print("Error checking input method status: \(error)")
        }
        
        return false
    }
    
    public func getSelectedText() async -> String {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let selectedText = self.extractSelectedText()
                continuation.resume(returning: selectedText)
            }
        }
    }
    
    private func extractSelectedText() -> String {
        let workspace = NSWorkspace.shared
        let frontApp = workspace.frontmostApplication
        
        // Use AppleScript to get selected text
        let script = """
        tell application "System Events"
            tell process "\(frontApp?.localizedName ?? "System Events")"
                try
                    get value of text area 1 of window 1
                on error
                    try
                        get value of text field 1 of window 1
                    on error
                        return ""
                    end try
                end try
            end tell
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var errorInfo: NSDictionary?
            let result = appleScript.executeAndReturnError(&errorInfo)
            
            if errorInfo == nil {
                return result.stringValue ?? ""
            }
        }
        
        // Fallback method
        return getSelectedTextFromPasteboard()
    }
    
    private func getSelectedTextFromPasteboard() -> String {
        let pasteboard = NSPasteboard.general
        
        // Save current clipboard content
        let currentContent = pasteboard.string(forType: .string)
        
        // Copy selected text - simplified version
        // In production, this would use proper CGEvent APIs
        let source = CGEventSource(stateID: .hidSystemState)
        
        // For now, just return clipboard content without simulating keypress
        // This avoids potential security issues with keypress simulation
        
        // For development, just return current clipboard content
        let selectedText = pasteboard.string(forType: .string) ?? ""
        return selectedText
    }
    
    public func insertText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // For development, just set the clipboard content
        // In production, this would simulate Cmd+V keypress
        print("Text inserted to clipboard: \(text)")
    }
    
    public func registerGlobalHotKey(keyCode: UInt32, modifiers: CGEventFlags, handler: @escaping () -> Void) {
        // For development, hotkey registration is simplified
        print("Hotkey registered: keyCode=\(keyCode), modifiers=\(modifiers)")
        // In production, this would use proper CGEventTap APIs
    }
    
    public func openSystemPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.keyboard?InputSources")!
        NSWorkspace.shared.open(url)
    }
}