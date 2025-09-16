import AppKit
import SwiftUI

// Modern input method controller for macOS 26
@MainActor
public class FlowInputController: NSObject, ObservableObject {

    // Singleton instance for app-wide access
    public static let shared = FlowInputController()

    // Modern state management
    @Published private(set) var isActive = false
    @Published private(set) var composedText = ""
    @Published private(set) var candidateWindowVisible = false

    // Modern window management
    private var candidateWindow: NSWindow?
    private var textSelectionObserver: NSObjectProtocol?

    // Modern gesture recognition
    private var gestureRecognizer: NSGestureRecognizer?

    private override init() {
        super.init()
        setupModernInputMethod()
    }

    deinit {
        removeObservers()
    }

    // MARK: - Modern Setup

    private func setupModernInputMethod() {
        setupTextSelectionObserver()
        setupModernGestures()
        registerForModernNotifications()
    }

    private func setupTextSelectionObserver() {
        // Modern observation using Combine-like publishers
        textSelectionObserver = NotificationCenter.default.addObserver(
            forName: NSTextInputContext.selectionDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleTextSelectionDidChange()
        }
    }

    private func setupModernGestures() {
        // Create modern gesture recognizer for triple-space shortcut
        gestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTripleSpaceGesture)
        )
        gestureRecognizer?.numberOfTapsRequired = 3
    }

    private func registerForModernNotifications() {
        // Register for modern app lifecycle notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillBecomeActive),
            name: NSApplication.willBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: NSApplication.willResignActiveNotification,
            object: nil
        )
    }

    // MARK: - Modern Event Handling

    @objc private func appWillBecomeActive() {
        activateInputMethod()
    }

    @objc private func appWillResignActive() {
        deactivateInputMethod()
    }

    private func handleTextSelectionDidChange() {
        let selectedText = getSelectedText()
        if !selectedText.isEmpty {
            Task {
                await handleSelectedText(selectedText)
            }
        }
    }

    private func handleSelectedText(_ text: String) async {
        // Modern async/await pattern
        let translatedText = await TranslationService.shared.translate(text: text)

        await MainActor.run {
            showModernTranslationPopup(original: text, translated: translatedText)
        }
    }

    // MARK: - Modern Translation Display

    private func showModernTranslationPopup(original: String, translated: String) {
        guard candidateWindow == nil else { return }

        // Create modern window with latest AppKit features
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 180),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Modern window configuration
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.hasShadow = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]

        // Create modern SwiftUI view
        let contentView = ModernTranslationPopupView(
            originalText: original,
            translatedText: translated,
            onClose: { [weak self] in
                self?.hideCandidateWindow()
            }
        )

        window.contentView = NSHostingView(rootView: contentView)

        // Position window using modern screen management
        positionWindowModern(window)

        // Show window with modern animation
        animateWindowAppearance(window)

        candidateWindow = window
        candidateWindowVisible = true

        // Auto-hide after delay
        scheduleWindowAutoHide()
    }

    private func positionWindowModern(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }

        let screenRect = screen.visibleFrame
        let windowSize = window.frame.size

        // Center the window with modern offset calculation
        let centerX = screenRect.midX - windowSize.width / 2
        let centerY = screenRect.midY - windowSize.height / 2

        window.setFrameOrigin(NSPoint(x: centerX, y: centerY))
    }

    private func animateWindowAppearance(_ window: NSWindow) {
        // Modern fade-in animation
        window.alphaValue = 0.0
        window.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 1.0
        })
    }

    private func scheduleWindowAutoHide() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds

            if let window = candidateWindow {
                hideCandidateWindow()
            }
        }
    }

    private func hideCandidateWindow() {
        guard let window = candidateWindow else { return }

        // Modern fade-out animation
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 0.0
        }, completionHandler: {
            window.close()
        })

        candidateWindow = nil
        candidateWindowVisible = false
    }

    // MARK: - Modern Input Method State

    public func activateInputMethod() {
        isActive = true
        composedText = ""
    }

    public func deactivateInputMethod() {
        isActive = false
        composedText = ""
        hideCandidateWindow()
    }

    // MARK: - Modern Keyboard Shortcuts

    @objc private func handleTripleSpaceGesture() {
        let selectedText = getSelectedText()
        if !selectedText.isEmpty {
            Task {
                await handleSelectedText(selectedText)
            }
        }
    }

    // MARK: - Modern Text Selection

    private func getSelectedText() -> String {
        // Modern pasteboard access
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string) ?? ""
    }

    // MARK: - Modern Menu Integration

    public func createModernMenu() -> NSMenu {
        let menu = NSMenu(title: "FlowKey")

        // Modern menu items with SwiftUI integration
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let aboutItem = NSMenuItem(
            title: "About FlowKey",
            action: #selector(openAbout),
            keyEquivalent: ""
        )
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

    // MARK: - Cleanup

    private func removeObservers() {
        if let observer = textSelectionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Modern Translation Popup View

struct ModernTranslationPopupView: View {
    let originalText: String
    let translatedText: String
    let onClose: () -> Void

    @State private var isAnimating = false
    @State private var copiedToClipboard = false

    var body: some View {
        VStack(spacing: 16) {
            headerView

            Divider()

            contentView

            actionButtonsView
        }
        .padding(20)
        .frame(width: 320, height: 180)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .primary.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isAnimating ? 1.0 : 0.8)
        .opacity(isAnimating ? 1.0 : 0.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isAnimating)
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
    }

    private var headerView: some View {
        HStack {
            Text("Translation")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Original:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(originalText)
                    .font(.body)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Translation:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(translatedText)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }
        }
    }

    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            Button(action: copyToClipboard) {
                HStack {
                    Image(systemName: copiedToClipboard ? "checkmark.circle.fill" : "doc.on.doc")
                    Text(copiedToClipboard ? "Copied!" : "Copy")
                }
            }
            .buttonStyle(.bordered)
            .disabled(copiedToClipboard)

            Spacer()

            Button("More") {
                // Show additional options
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(translatedText, forType: .string)

        withAnimation(.easeInOut(duration: 0.2)) {
            copiedToClipboard = true
        }

        // Reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.2)) {
                copiedToClipboard = false
            }
        }
    }
}

// MARK: - Modern Notification Extensions

extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
    static let inputMethodActivated = Notification.Name("inputMethodActivated")
    static let inputMethodDeactivated = Notification.Name("inputMethodDeactivated")
}