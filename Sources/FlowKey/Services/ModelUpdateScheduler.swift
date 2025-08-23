import Foundation

public class ModelUpdateScheduler {
    public static let shared = ModelUpdateScheduler()
    
    private init() {}
    
    // MARK: - Scheduling Types
    
    public enum UpdateSchedule {
        case immediate          // Update immediately
        case specificTime(Date) // Update at specific time
        case maintenanceWindow  // Update during maintenance window
        case lowUsagePeriod     // Update during low usage period
        case userDefined(Date)  // User-defined schedule
    }
    
    public enum UpdatePriority: Int, CaseIterable {
        case low = 1
        case normal = 2
        case high = 3
        case critical = 4
        
        public var displayName: String {
            switch self {
            case .low: return "低优先级"
            case .normal: return "正常优先级"
            case .high: return "高优先级"
            case .critical: return "关键优先级"
            }
        }
    }
    
    public struct ScheduledUpdate {
        public let id: String
        public let version: ModelUpdateManager.ModelVersion
        public let schedule: UpdateSchedule
        public let priority: UpdatePriority
        public let scheduledDate: Date
        public let estimatedDuration: TimeInterval
        public let requiresRestart: Bool
        public let userNotification: Bool
        public let autoDownload: Bool
        public let createdDate: Date
        public var status: UpdateStatus
        
        public init(id: String, version: ModelUpdateManager.ModelVersion, schedule: UpdateSchedule,
                    priority: UpdatePriority, scheduledDate: Date, estimatedDuration: TimeInterval,
                    requiresRestart: Bool = false, userNotification: Bool = true, autoDownload: Bool = true,
                    createdDate: Date = Date(), status: UpdateStatus = .scheduled) {
            self.id = id
            self.version = version
            self.schedule = schedule
            self.priority = priority
            self.scheduledDate = scheduledDate
            self.estimatedDuration = estimatedDuration
            self.requiresRestart = requiresRestart
            self.userNotification = userNotification
            self.autoDownload = autoDownload
            self.createdDate = createdDate
            self.status = status
        }
    }
    
    public enum UpdateStatus: String, CaseIterable {
        case scheduled = "scheduled"
        case downloading = "downloading"
        case readyToInstall = "ready_to_install"
        case installing = "installing"
        case completed = "completed"
        case failed = "failed"
        case cancelled = "cancelled"
        case postponed = "postponed"
        
        public var displayName: String {
            switch self {
            case .scheduled: return "已安排"
            case .downloading: return "正在下载"
            case .readyToInstall: return "准备安装"
            case .installing: return "正在安装"
            case .completed: return "已完成"
            case .failed: return "失败"
            case .cancelled: return "已取消"
            case .postponed: return "已推迟"
            }
        }
    }
    
    // MARK: - Properties
    
    private var scheduledUpdates: [ScheduledUpdate] = []
    private var updateTimer: Timer?
    private let notificationManager = ModelUpdateNotificationManager.shared
    private let updateManager = ModelUpdateManager.shared
    private let habitService = UserHabitIntegrationService.shared
    
    // MARK: - Public Methods
    
    public func scheduleUpdate(
        version: ModelUpdateManager.ModelVersion,
        schedule: UpdateSchedule,
        priority: UpdatePriority = .normal,
        requiresRestart: Bool = false,
        userNotification: Bool = true,
        autoDownload: Bool = true
    ) async -> String {
        let scheduledDate = calculateScheduledDate(for: schedule, priority: priority)
        let estimatedDuration = estimateUpdateDuration(for: version)
        
        let scheduledUpdate = ScheduledUpdate(
            id: UUID().uuidString,
            version: version,
            schedule: schedule,
            priority: priority,
            scheduledDate: scheduledDate,
            estimatedDuration: estimatedDuration,
            requiresRestart: requiresRestart,
            userNotification: userNotification,
            autoDownload: autoDownload
        )
        
        scheduledUpdates.append(scheduledUpdate)
        
        // Sort by priority and scheduled date
        scheduledUpdates.sort { update1, update2 in
            if update1.priority.rawValue != update2.priority.rawValue {
                return update1.priority.rawValue > update2.priority.rawValue
            }
            return update1.scheduledDate < update2.scheduledDate
        }
        
        // Schedule the update
        await scheduleUpdateTask(scheduledUpdate)
        
        // Notify user if requested
        if userNotification {
            await notificationManager.notifyUpdateScheduled(
                version: version,
                scheduledDate: scheduledDate
            )
        }
        
        return scheduledUpdate.id
    }
    
    public func cancelScheduledUpdate(withId id: String) async {
        if let index = scheduledUpdates.firstIndex(where: { $0.id == id }) {
            let update = scheduledUpdates[index]
            
            switch update.status {
            case .scheduled:
                // Cancel scheduled task
                await cancelScheduledTask(update)
                update.status = .cancelled
            case .downloading:
                // Cancel download
                updateManager.cancelUpdate()
                update.status = .cancelled
            case .readyToInstall:
                // Just mark as cancelled
                update.status = .cancelled
            default:
                break
            }
            
            // Remove from scheduled updates
            scheduledUpdates.remove(at: index)
            
            // Cancel notification
            await notificationManager.cancelNotification(withIdentifier: id)
        }
    }
    
    public func postponeScheduledUpdate(withId id: String, until: Date) async {
        if let index = scheduledUpdates.firstIndex(where: { $0.id == id }) {
            var update = scheduledUpdates[index]
            
            // Cancel current scheduling
            await cancelScheduledTask(update)
            
            // Reschedule for new date
            update.scheduledDate = until
            update.status = .scheduled
            
            scheduledUpdates[index] = update
            
            // Reschedule the task
            await scheduleUpdateTask(update)
            
            // Notify user
            await notificationManager.notifyUpdateScheduled(
                version: update.version,
                scheduledDate: until
            )
        }
    }
    
    public func getScheduledUpdates() -> [ScheduledUpdate] {
        return scheduledUpdates.sorted { $0.scheduledDate < $1.scheduledDate }
    }
    
    public func getUpdateSchedule(withId id: String) -> ScheduledUpdate? {
        return scheduledUpdates.first { $0.id == id }
    }
    
    public func startScheduler() {
        startUpdateMonitoring()
    }
    
    public func stopScheduler() {
        stopUpdateMonitoring()
    }
    
    // MARK: - Private Methods
    
    private func calculateScheduledDate(for schedule: UpdateSchedule, priority: UpdatePriority) -> Date {
        let now = Date()
        
        switch schedule {
        case .immediate:
            return now
            
        case .specificTime(let date):
            return date > now ? date : now
            
        case .maintenanceWindow:
            return calculateMaintenanceWindowDate(now: now, priority: priority)
            
        case .lowUsagePeriod:
            return calculateLowUsagePeriodDate(now: now, priority: priority)
            
        case .userDefined(let date):
            return date > now ? date : now
        }
    }
    
    private func calculateMaintenanceWindowDate(now: Date, priority: UpdatePriority) -> Date {
        let calendar = Calendar.current
        
        // Maintenance window: 2:00 AM - 4:00 AM
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 2
        components.minute = 0
        
        var maintenanceDate = calendar.date(from: components)!
        
        // If maintenance time has passed today, schedule for tomorrow
        if maintenanceDate < now {
            maintenanceDate = calendar.date(byAdding: .day, value: 1, to: maintenanceDate)!
        }
        
        // For critical updates, schedule sooner
        if priority == .critical {
            // Schedule for next available maintenance window within 2 hours
            if now.timeIntervalSince(maintenanceDate) > 2 * 60 * 60 {
                maintenanceDate = now.addingTimeInterval(30 * 60) // 30 minutes from now
            }
        }
        
        return maintenanceDate
    }
    
    private func calculateLowUsagePeriodDate(now: Date, priority: UpdatePriority) -> Date {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        
        // Low usage periods: 10 PM - 6 AM
        let lowUsageStart = 22 // 10 PM
        let lowUsageEnd = 6    // 6 AM
        
        var targetDate = now
        
        if currentHour >= lowUsageStart || currentHour < lowUsageEnd {
            // Currently in low usage period
            targetDate = now.addingTimeInterval(30 * 60) // 30 minutes from now
        } else {
            // Schedule for next low usage period
            if currentHour < lowUsageEnd {
                // Before 6 AM, already in low usage period
                targetDate = now.addingTimeInterval(30 * 60)
            } else {
                // After 6 AM, schedule for 10 PM
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                components.hour = lowUsageStart
                components.minute = 0
                targetDate = calendar.date(from: components)!
            }
        }
        
        // For critical updates, schedule sooner
        if priority == .critical {
            targetDate = now.addingTimeInterval(15 * 60) // 15 minutes from now
        }
        
        return targetDate
    }
    
    private func estimateUpdateDuration(for version: ModelUpdateManager.ModelVersion) -> TimeInterval {
        // Estimate based on model size and update type
        let baseDownloadTime = Double(version.modelSize) / 100_000_000 // 100 MB/s
        let baseInstallTime = 60.0 // 1 minute base install time
        
        var totalDuration = baseDownloadTime + baseInstallTime
        
        // Add time based on update type
        switch version.updateType {
        case .major:
            totalDuration += 120.0 // 2 minutes extra
        case .critical:
            totalDuration += 60.0  // 1 minute extra
        case .minor:
            totalDuration += 30.0  // 30 seconds extra
        case .experimental:
            totalDuration += 90.0  // 1.5 minutes extra
        }
        
        return totalDuration
    }
    
    private func scheduleUpdateTask(_ update: ScheduledUpdate) async {
        let timeInterval = update.scheduledDate.timeIntervalSince(Date())
        
        guard timeInterval > 0 else {
            // Schedule immediately
            await executeUpdate(update)
            return
        }
        
        // Schedule timer for update
        let timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
            Task {
                await self.executeUpdate(update)
            }
        }
        
        updateTimer = timer
    }
    
    private func cancelScheduledTask(_ update: ScheduledUpdate) async {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func executeUpdate(_ update: ScheduledUpdate) async {
        // Update status
        if let index = scheduledUpdates.firstIndex(where: { $0.id == update.id }) {
            scheduledUpdates[index].status = .downloading
        }
        
        do {
            // Download update if auto-download is enabled
            if update.autoDownload {
                try await updateManager.downloadUpdate(update.version)
            }
            
            // Update status
            if let index = scheduledUpdates.firstIndex(where: { $0.id == update.id }) {
                scheduledUpdates[index].status = .readyToInstall
            }
            
            // Install update
            if let index = scheduledUpdates.firstIndex(where: { $0.id == update.id }) {
                scheduledUpdates[index].status = .installing
            }
            
            try await updateManager.installUpdate(update.version)
            
            // Update status
            if let index = scheduledUpdates.firstIndex(where: { $0.id == update.id }) {
                scheduledUpdates[index].status = .completed
            }
            
            // Remove from scheduled updates
            scheduledUpdates.removeAll { $0.id == update.id }
            
            // Notify completion
            await notificationManager.notifyUpdateComplete(version: update.version)
            
        } catch {
            // Update status
            if let index = scheduledUpdates.firstIndex(where: { $0.id == update.id }) {
                scheduledUpdates[index].status = .failed
            }
            
            // Notify failure
            await notificationManager.notifyUpdateFailed(version: update.version, error: error)
        }
    }
    
    // MARK: - Monitoring Methods
    
    private func startUpdateMonitoring() {
        // Check for scheduled updates every minute
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task {
                await self.checkScheduledUpdates()
            }
        }
    }
    
    private func stopUpdateMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func checkScheduledUpdates() async {
        let now = Date()
        
        for update in scheduledUpdates {
            // Check if update should be executed
            if update.status == .scheduled && update.scheduledDate <= now {
                await executeUpdate(update)
            }
        }
        
        // Clean up completed updates older than 30 days
        let cutoffDate = now.addingTimeInterval(-30 * 24 * 60 * 60)
        scheduledUpdates.removeAll { update in
            update.status == .completed && update.scheduledDate < cutoffDate
        }
    }
    
    // MARK: - Smart Scheduling
    
    public func suggestOptimalUpdateSchedule(
        for version: ModelUpdateManager.ModelVersion
    ) async -> UpdateSchedule {
        let habits = habitService.getRelevantInsights()
        let now = Date()
        
        // Analyze user patterns to suggest optimal time
        let userActivity = analyzeUserActivity(habits: habits)
        
        if version.updateType == .critical {
            return .immediate
        }
        
        if userActivity.isLowUsagePeriod(now) {
            return .lowUsagePeriod
        }
        
        if userActivity.hasMaintenanceWindow {
            return .maintenanceWindow
        }
        
        // Default to next low usage period
        return .lowUsagePeriod
    }
    
    private func analyzeUserActivity(habits: [HabitInsight]) -> UserActivityAnalysis {
        // Analyze user habits to determine optimal update times
        return UserActivityAnalysis(
            isLowUsagePeriod: { date in
                let hour = Calendar.current.component(.hour, from: date)
                return hour >= 22 || hour < 6
            },
            hasMaintenanceWindow: true,
            preferredUpdateTimes: [22, 23, 0, 1, 2, 3, 4, 5] // 10 PM - 5 AM
        )
    }
}

// MARK: - Supporting Structures

private struct UserActivityAnalysis {
    let isLowUsagePeriod: (Date) -> Bool
    let hasMaintenanceWindow: Bool
    let preferredUpdateTimes: [Int]
}