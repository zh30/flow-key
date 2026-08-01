import AppKit
import Observation
import SwiftUI

@MainActor
@Observable
final class SystemQuickTranslation {
    enum ShortcutStatus: Equatable {
        case registered
        case disabled
        case unavailable

        var label: String {
            switch self {
            case .registered:
                return L10n.string("Ready")
            case .disabled:
                return L10n.string("Off")
            case .unavailable:
                return L10n.string("Shortcut unavailable")
            }
        }
    }

    private(set) var shortcutStatus: ShortcutStatus = .disabled
    private(set) var accessibilityAuthorized: Bool

    @ObservationIgnored
    private let settings: AppSettings

    @ObservationIgnored
    private let terminologyStore: TerminologyStore

    @ObservationIgnored
    private let shortcutService = GlobalShortcutService()

    @ObservationIgnored
    private let model: QuickTranslationModel

    // The panel has one deliberate owner because it must survive SwiftUI view
    // recreation and behave as a single system utility window.
    @ObservationIgnored
    private var panel: NSPanel?

    init(settings: AppSettings, terminologyStore: TerminologyStore) {
        self.settings = settings
        self.terminologyStore = terminologyStore
        self.accessibilityAuthorized = AccessibilitySelectionService.isAuthorized
        self.model = QuickTranslationModel(
            targetLanguage: settings.defaultTargetLanguage
        )
    }

    func start() {
        let shortcutServiceStarted = shortcutService.start { [weak self] in
            self?.showPanel()
        }

        settings.quickTranslationShortcutDidChange = { [weak self] shortcut in
            self?.registerShortcut(shortcut)
        }

        if shortcutServiceStarted {
            registerShortcut(settings.quickTranslationShortcut)
        } else {
            shortcutStatus = .unavailable
        }
    }

    func stop() {
        settings.quickTranslationShortcutDidChange = nil
        shortcutService.stop()
        panel?.orderOut(nil)
    }

    func showPanel() {
        // Capture before activating FlowKey so the focused accessibility
        // element still belongs to the app where the shortcut was pressed.
        let captureResult = AccessibilitySelectionService.captureFocusedSelection()
        let pointerLocation = NSEvent.mouseLocation

        accessibilityAuthorized = AccessibilitySelectionService.isAuthorized
        model.prepare(
            captureResult: captureResult,
            targetLanguage: settings.defaultTargetLanguage
        )

        let panel = makePanelIfNeeded()
        position(panel, near: pointerLocation)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func dismissPanel() {
        panel?.orderOut(nil)
    }

    func requestAccessibilityAccess() {
        accessibilityAuthorized = AccessibilitySelectionService.requestAuthorization()
    }

    func openAccessibilitySettings() {
        AccessibilitySelectionService.openPrivacySettings()
    }

    func refreshAccessibilityStatus() {
        accessibilityAuthorized = AccessibilitySelectionService.isAuthorized
    }

    private func registerShortcut(_ shortcut: QuickTranslationShortcut) {
        if shortcut == .disabled {
            _ = shortcutService.register(shortcut)
            shortcutStatus = .disabled
            return
        }

        switch shortcutService.register(shortcut) {
        case .success:
            shortcutStatus = .registered
        case .failure:
            shortcutStatus = .unavailable
        }
    }

    private func makePanelIfNeeded() -> NSPanel {
        if let panel {
            return panel
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 410),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = L10n.string("Quick Action")
        panel.titleVisibility = .visible
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        let rootView = QuickTranslationView(
            model: model,
            terminologyStore: terminologyStore,
            onRequestAccessibility: { [weak self] in
                self?.requestAccessibilityAccess()
            },
            onOpenPrivacySettings: { [weak self] in
                self?.openAccessibilitySettings()
            },
            onDismiss: { [weak panel] in
                panel?.orderOut(nil)
            }
        )
        panel.contentViewController = NSHostingController(rootView: rootView)

        self.panel = panel
        return panel
    }

    private func position(_ panel: NSPanel, near pointer: NSPoint) {
        let screen = NSScreen.screens.first { screen in
            NSMouseInRect(pointer, screen.frame, false)
        } ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else { return }

        let panelSize = panel.frame.size
        let margin: CGFloat = 12
        var origin = NSPoint(
            x: pointer.x - panelSize.width / 2,
            y: pointer.y - panelSize.height - 16
        )

        if origin.y < visibleFrame.minY + margin {
            origin.y = pointer.y + 16
        }

        origin.x = min(
            max(origin.x, visibleFrame.minX + margin),
            visibleFrame.maxX - panelSize.width - margin
        )
        origin.y = min(
            max(origin.y, visibleFrame.minY + margin),
            visibleFrame.maxY - panelSize.height - margin
        )

        panel.setFrameOrigin(origin)
    }
}
