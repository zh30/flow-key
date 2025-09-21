import AppKit
import SwiftUI
import UserNotifications

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var notificationCenter: UNUserNotificationCenter?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        configureNotificationsIfAvailable()
        NSApp.setActivationPolicy(.regular)
    }
    
    func applicationWillTerminate(_ notification: Notification) { }
    
    private func configureNotificationsIfAvailable() {
        guard let usageDescription = Bundle.main.object(forInfoDictionaryKey: "NSUserNotificationUsageDescription") as? String,
              usageDescription.isEmpty == false else {
            print("NSUserNotificationUsageDescription missing or empty; skipping notification authorization to avoid crash.")
            notificationCenter = nil
            return
        }
        
        let center = UNUserNotificationCenter.current()
        notificationCenter = center
        setupNotifications(with: center)
    }
    
    private func setupNotifications(with center: UNUserNotificationCenter) {
        Task { @MainActor in
            do {
                try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                print("Failed to request notification authorization: \(error)")
            }
        }
    }
    
    func showNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        guard let notificationCenter else {
            print("Notification center unavailable; cannot display notification with title: \(title)")
            return
        }
        
        notificationCenter.add(request) { error in
            if let error {
                print("Error showing notification: \(error)")
            }
        }
    }
}

@main
struct FlowKeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var localizationService = LocalizationService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(localizationService)
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
