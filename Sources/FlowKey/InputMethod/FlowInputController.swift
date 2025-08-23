import AppKit
import SwiftUI

// Mock IMKInputController for development
// In production, this would use the actual InputMethodKit framework
public class FlowInputController: NSObject {
    
    private var candidateWindow: NSWindow?
    private var composedText: String = ""
    private var selectedRange: NSRange = NSRange(location: 0, length: 0)
    
    public init(server: Any?, delegate: Any?, client: Any?) {
        super.init()
        setupInputMethod()
    }
    
    private func setupInputMethod() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textSelectionDidChange),
            name: Notification.Name("NSTextInputContextSelectionDidChange"),
            object: nil
        )
    }
    
    @objc private func textSelectionDidChange() {
        // Mock text selection handling
        let selectedText = getSelectedTextFromPasteboard()
        if !selectedText.isEmpty {
            handleTextSelection(text: selectedText)
        }
    }
    
    private func handleTextSelection(text: String) {
        if !text.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showTranslationPopup(text: text)
            }
        }
    }
    
    private func getSelectedTextFromPasteboard() -> String {
        return NSPasteboard.general.string(forType: .string) ?? ""
    }
    
    private func showTranslationPopup(text: String) {
        Task {
            let translatedText = await TranslationService.shared.translate(text: text)
            await MainActor.run {
                self.displayTranslationPopup(original: text, translated: translatedText)
            }
        }
    }
    
    private func displayTranslationPopup(original: String, translated: String) {
        guard candidateWindow == nil else { return }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 150),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        
        let contentView = TranslationPopupView(
            originalText: original,
            translatedText: translated,
            onClose: { [weak self] in
                self?.candidateWindow?.close()
                self?.candidateWindow = nil
            }
        )
        
        window.contentView = NSHostingView(rootView: contentView)
        
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            window.setFrameOrigin(
                CGPoint(
                    x: screenRect.midX - window.frame.width / 2,
                    y: screenRect.midY - window.frame.height / 2
                )
            )
        }
        
        window.makeKeyAndOrderFront(nil)
        candidateWindow = window
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if self.candidateWindow == window {
                window.close()
                self.candidateWindow = nil
            }
        }
    }
    
    // MARK: - Mock IMKInputController Methods
    
    public func activateServer(_ sender: Any?) {
        composedText = ""
        selectedRange = NSRange(location: 0, length: 0)
    }
    
    public func deactivateServer(_ sender: Any?) {
        composedText = ""
        selectedRange = NSRange(location: 0, length: 0)
        candidateWindow?.close()
        candidateWindow = nil
    }
    
    @objc public func handleEvent(_ event: NSEvent?) -> Bool {
        guard let event = event else { return false }
        
        switch event.type {
        case .keyDown:
            return handleKeyDown(event: event)
        case .flagsChanged:
            return handleFlagsChanged(event: event)
        default:
            return false
        }
    }
    
    private func handleKeyDown(event: NSEvent) -> Bool {
        let keyCode = event.keyCode
        let modifiers = event.modifierFlags
        
        // Triple space shortcut for translation
        if keyCode == 49 && modifiers.contains(.shift) {
            return handleTripleSpaceShortcut()
        }
        
        // Escape key to cancel composition
        if keyCode == 53 {
            if !composedText.isEmpty {
                composedText = ""
                selectedRange = NSRange(location: 0, length: 0)
                return true
            }
        }
        
        return false
    }
    
    private func handleFlagsChanged(event: NSEvent) -> Bool {
        return false
    }
    
    private func handleTripleSpaceShortcut() -> Bool {
        let selectedText = getSelectedTextFromPasteboard()
        if !selectedText.isEmpty {
            showTranslationPopup(text: selectedText)
            return true
        }
        return false
    }
    
    public func menu() -> NSMenu? {
        let menu = NSMenu(title: "FlowKey")
        
        let settingsItem = NSMenuItem(title: "设置...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let aboutItem = NSMenuItem(title: "关于 FlowKey", action: #selector(openAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        return menu
    }
    
    @objc private func openSettings() {
        NotificationCenter.default.post(name: .openSettings, object: nil)
    }
    
    @objc private func openAbout() {
        NSApp.orderFrontStandardAboutPanel(options: [:])
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Translation Popup View
struct TranslationPopupView: View {
    let originalText: String
    let translatedText: String
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("翻译")
                    .font(.headline)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("原文:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(originalText)
                    .font(.body)
                    .lineLimit(3)
                
                Divider()
                
                Text("译文:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(translatedText)
                    .font(.body)
                    .lineLimit(3)
            }
            
            HStack {
                Button("复制") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(translatedText, forType: .string)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("更多") {
                    // Show more options
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300, height: 150)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 10)
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
}