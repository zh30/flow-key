import Foundation
import UserNotifications

public class ModelUpdateNotificationManager {
    public static let shared = ModelUpdateNotificationManager()
    
    private init() {}
    
    // MARK: - Notification Types
    
    public enum NotificationType: String, CaseIterable {
        case updateAvailable = "update_available"
        case downloadComplete = "download_complete"
        case updateComplete = "update_complete"
        case updateFailed = "update_failed"
        case updateScheduled = "update_scheduled"
        case maintenanceRequired = "maintenance_required"
        
        public var title: String {
            switch self {
            case .updateAvailable: return "更新可用"
            case .downloadComplete: return "下载完成"
            case .updateComplete: return "更新完成"
            case .updateFailed: return "更新失败"
            case .updateScheduled: return "更新已安排"
            case .maintenanceRequired: return "需要维护"
            }
        }
        
        public var category: String {
            switch self {
            case .updateAvailable: return "UPDATE_AVAILABLE"
            case .downloadComplete: return "DOWNLOAD_COMPLETE"
            case .updateComplete: return "UPDATE_COMPLETE"
            case .updateFailed: return "UPDATE_FAILED"
            case .updateScheduled: return "UPDATE_SCHEDULED"
            case .maintenanceRequired: return "MAINTENANCE_REQUIRED"
            }
        }
    }
    
    // MARK: - Notification Management
    
    public func requestNotificationAuthorization() async {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                print("Notification authorization granted")
                setupNotificationCategories()
            } else {
                print("Notification authorization denied")
            }
        } catch {
            print("Failed to request notification authorization: \(error)")
        }
    }
    
    public func scheduleUpdateNotification(
        type: NotificationType,
        version: ModelUpdateManager.ModelVersion?,
        body: String,
        scheduledDate: Date? = nil,
        identifier: String? = nil
    ) async {
        let content = UNMutableNotificationContent()
        content.title = type.title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = type.category
        
        // Add version information if available
        if let version = version {
            content.userInfo = [
                "version": version.version,
                "buildNumber": version.buildNumber,
                "updateType": version.updateType.rawValue
            ]
        }
        
        // Add actions based on notification type
        switch type {
        case .updateAvailable:
            content.userInfo["action"] = "check_update"
        case .downloadComplete:
            content.userInfo["action"] = "install_update"
        case .updateComplete:
            content.userInfo["action"] = "update_complete"
        case .updateFailed:
            content.userInfo["action"] = "update_failed"
        case .updateScheduled:
            content.userInfo["action"] = "update_scheduled"
        case .maintenanceRequired:
            content.userInfo["action"] = "maintenance_required"
        }
        
        let request: UNNotificationRequest
        
        if let scheduledDate = scheduledDate {
            // Schedule for future date
            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            request = UNNotificationRequest(
                identifier: identifier ?? UUID().uuidString,
                content: content,
                trigger: trigger
            )
        } else {
            // Send immediately
            request = UNNotificationRequest(
                identifier: identifier ?? UUID().uuidString,
                content: content,
                trigger: nil
            )
        }
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled notification: \(type.title)")
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }
    
    public func cancelNotification(withIdentifier identifier: String) async {
        let center = UNUserNotificationCenter.current()
        await center.removePendingNotificationRequests(withIdentifiers: [identifier])
        await center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    public func cancelAllNotifications() async {
        let center = UNUserNotificationCenter.current()
        await center.removeAllPendingNotificationRequests()
        await center.removeAllDeliveredNotifications()
    }
    
    public func getPendingNotifications() async -> [UNNotificationRequest] {
        let center = UNUserNotificationCenter.current()
        return await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }
    
    // MARK: - Predefined Notifications
    
    public func notifyUpdateAvailable(version: ModelUpdateManager.ModelVersion) async {
        let body = """
        版本 \(version.version) 现已可用。
        
        更新内容：
        \(version.changelog.joined(separator: "\n"))
        
        文件大小：\(formatBytes(version.modelSize))
        """
        
        await scheduleUpdateNotification(
            type: .updateAvailable,
            version: version,
            body: body
        )
    }
    
    public func notifyDownloadComplete(version: ModelUpdateManager.ModelVersion) async {
        let body = """
        版本 \(version.version) 下载完成。
        
        点击安装以完成更新过程。
        """
        
        await scheduleUpdateNotification(
            type: .downloadComplete,
            version: version,
            body: body
        )
    }
    
    public func notifyUpdateComplete(version: ModelUpdateManager.ModelVersion) async {
        let body = """
        模型已成功更新到版本 \(version.version)。
        
        新功能和改进现已可用。
        """
        
        await scheduleUpdateNotification(
            type: .updateComplete,
            version: version,
            body: body
        )
    }
    
    public func notifyUpdateFailed(version: ModelUpdateManager.ModelVersion, error: Error) async {
        let body = """
        版本 \(version.version) 更新失败。
        
        错误信息：\(error.localizedDescription)
        
        请稍后重试或检查网络连接。
        """
        
        await scheduleUpdateNotification(
            type: .updateFailed,
            version: version,
            body: body
        )
    }
    
    public func notifyUpdateScheduled(version: ModelUpdateManager.ModelVersion, scheduledDate: Date) async {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let body = """
        版本 \(version.version) 将在 \(formatter.string(from: scheduledDate)) 自动安装。
        
        您可以在设置中更改此安排。
        """
        
        await scheduleUpdateNotification(
            type: .updateScheduled,
            version: version,
            body: body,
            scheduledDate: scheduledDate
        )
    }
    
    public func notifyMaintenanceRequired(message: String) async {
        let body = """
        模型需要维护才能继续正常工作。
        
        \(message)
        
        请按照指示进行维护操作。
        """
        
        await scheduleUpdateNotification(
            type: .maintenanceRequired,
            version: nil,
            body: body
        )
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationCategories() {
        let center = UNUserNotificationCenter.current()
        
        // Update available category
        let updateAvailableAction = UNNotificationAction(
            identifier: "DOWNLOAD_UPDATE",
            title: "下载更新",
            options: []
        )
        
        let updateAvailableCategory = UNNotificationCategory(
            identifier: NotificationType.updateAvailable.category,
            actions: [updateAvailableAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Download complete category
        let installUpdateAction = UNNotificationAction(
            identifier: "INSTALL_UPDATE",
            title: "安装更新",
            options: []
        )
        
        let laterAction = UNNotificationAction(
            identifier: "LATER",
            title: "稍后",
            options: []
        )
        
        let downloadCompleteCategory = UNNotificationCategory(
            identifier: NotificationType.downloadComplete.category,
            actions: [installUpdateAction, laterAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Update complete category
        let viewChangesAction = UNNotificationAction(
            identifier: "VIEW_CHANGES",
            title: "查看更新内容",
            options: []
        )
        
        let updateCompleteCategory = UNNotificationCategory(
            identifier: NotificationType.updateComplete.category,
            actions: [viewChangesAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([
            updateAvailableCategory,
            downloadCompleteCategory,
            updateCompleteCategory
        ])
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Notification Handler

public class ModelUpdateNotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    
    public static let shared = ModelUpdateNotificationHandler()
    private let updateManager = ModelUpdateManager.shared
    
    private override init() {
        super.init()
        setupNotificationDelegate()
    }
    
    private func setupNotificationDelegate() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification actions
        switch response.actionIdentifier {
        case "DOWNLOAD_UPDATE":
            handleDownloadAction(userInfo: userInfo)
        case "INSTALL_UPDATE":
            handleInstallAction(userInfo: userInfo)
        case "VIEW_CHANGES":
            handleViewChangesAction(userInfo: userInfo)
        case UNNotificationDefaultActionIdentifier:
            // User tapped on the notification
            handleDefaultAction(userInfo: userInfo)
        default:
            break
        }
        
        completionHandler()
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    private func handleDownloadAction(userInfo: [AnyHashable: Any]) {
        Task {
            if let versionString = userInfo["version"] as? String,
               let updateInfo = updateManager.getCurrentUpdateInfo().availableVersion,
               updateInfo.version == versionString {
                
                do {
                    try await updateManager.downloadUpdate(updateInfo)
                } catch {
                    print("Failed to download update: \(error)")
                }
            }
        }
    }
    
    private func handleInstallAction(userInfo: [AnyHashable: Any]) {
        Task {
            if let versionString = userInfo["version"] as? String,
               let updateInfo = updateManager.getCurrentUpdateInfo().availableVersion,
               updateInfo.version == versionString {
                
                do {
                    try await updateManager.installUpdate(updateInfo)
                } catch {
                    print("Failed to install update: \(error)")
                }
            }
        }
    }
    
    private func handleViewChangesAction(userInfo: [AnyHashable: Any]) {
        // Show changelog or update details
        print("Show changelog for version: \(userInfo["version"] ?? "unknown")")
    }
    
    private func handleDefaultAction(userInfo: [AnyHashable: Any]) {
        // Handle default notification tap
        if let action = userInfo["action"] as? String {
            switch action {
            case "check_update":
                // Open update settings
                print("Open update settings")
            case "install_update":
                // Start installation
                handleInstallAction(userInfo: userInfo)
            case "update_complete":
                // Show update complete screen
                print("Show update complete screen")
            default:
                break
            }
        }
    }
}