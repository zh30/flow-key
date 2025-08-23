import Foundation
import AppKit

public class GlobalHotkeyManager {
    public static let shared = GlobalHotkeyManager()
    
    private init() {}
    
    public func setupGlobalHotkey() {
        // Setup global hotkey for voice command (Command+Shift+V)
        print("Global hotkey manager initialized")
    }
}