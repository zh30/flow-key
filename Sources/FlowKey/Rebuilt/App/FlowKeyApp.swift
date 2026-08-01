import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings: AppSettings
    let systemQuickTranslation: SystemQuickTranslation
    let inputMethodManager: InputMethodManager
    let terminologyStore: TerminologyStore

    override init() {
        let settings = AppSettings()
        let terminologyStore = TerminologyStore()
        self.settings = settings
        self.terminologyStore = terminologyStore
        self.systemQuickTranslation = SystemQuickTranslation(
            settings: settings,
            terminologyStore: terminologyStore
        )
        self.inputMethodManager = InputMethodManager()
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        systemQuickTranslation.start()
        inputMethodManager.refresh()
    }

    func applicationWillTerminate(_ notification: Notification) {
        systemQuickTranslation.stop()
    }
}

@main
@MainActor
struct FlowKeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("FlowKey", id: "translator") {
            FlowKeyWorkspaceView(
                settings: appDelegate.settings,
                terminologyStore: appDelegate.terminologyStore
            )
        }
        .defaultSize(width: 780, height: 520)
        .windowResizability(.contentMinSize)
        .windowToolbarStyle(.unified)
        .commands {
            FlowKeyCommands()
        }

        MenuBarExtra("FlowKey", systemImage: "character.bubble") {
            FlowKeyMenuBarView(
                settings: appDelegate.settings,
                systemQuickTranslation: appDelegate.systemQuickTranslation
            )
        }

        Settings {
            FlowKeySettingsView(
                settings: appDelegate.settings,
                systemQuickTranslation: appDelegate.systemQuickTranslation,
                inputMethodManager: appDelegate.inputMethodManager,
                terminologyStore: appDelegate.terminologyStore
            )
        }
        .defaultPosition(.center)
    }
}
