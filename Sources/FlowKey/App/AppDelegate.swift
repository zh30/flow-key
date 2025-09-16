import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {

    // Modern notification center for macOS 26
    private let notificationCenter = UNUserNotificationCenter.current()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupNotifications()
        setupInputMethod()

        // Modern app activation
        NSApp.setActivationPolicy(.regular)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup resources
    }

    private func setupNotifications() {
        // Request notification permissions
        Task {
            do {
                try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                print("Failed to request notification authorization: \(error)")
            }
        }
    }

    private func setupInputMethod() {
        // Initialize input method controller
        _ = FlowInputController.shared
    }

    // MARK: - Modern Notification Method
    func showNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }
        }
    }
}

// MARK: - SwiftUI App Integration
@main
struct FlowKeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var localizationService = LocalizationService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(localizationService)
                .onKeyPress(.escape) {
                    // Handle escape key globally
                    return .handled
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 400, height: 600)

        Settings {
            SettingsView()
                .environmentObject(localizationService)
        }
    }
}