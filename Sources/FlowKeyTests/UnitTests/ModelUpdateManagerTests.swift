import XCTest
@testable import FlowKey

class ModelUpdateManagerTests: XCTestCase {
    
    var updateManager: ModelUpdateManager!
    
    override func setUp() {
        super.setUp()
        updateManager = ModelUpdateManager.shared
    }
    
    override func tearDown() {
        updateManager = nil
        super.tearDown()
    }
    
    // MARK: - Basic Update Tests
    
    func testCheckForUpdates() async {
        do {
            let updateInfo = try await updateManager.checkForUpdates()
            
            XCTAssertFalse(updateInfo.currentVersion.version.isEmpty)
            XCTAssertNotNil(updateInfo.status)
            
            if let availableVersion = updateInfo.availableVersion {
                XCTAssertFalse(availableVersion.version.isEmpty)
                XCTAssertGreaterThan(availableVersion.modelSize, 0)
                XCTAssertFalse(availableVersion.checksum.isEmpty)
                XCTAssertFalse(availableVersion.description.isEmpty)
                XCTAssertFalse(availableVersion.changelog.isEmpty)
            }
        } catch {
            XCTFail("Failed to check for updates: \(error)")
        }
    }
    
    func testUpdateConfiguration() {
        let config = updateManager.getUpdateConfiguration()
        
        XCTAssertNotNil(config)
        XCTAssertTrue(config.autoCheckEnabled)
        XCTAssertEqual(config.updateChannel, .stable)
        XCTAssertEqual(config.checkInterval, 24 * 60 * 60)
        XCTAssertTrue(config.downloadOnlyOnWiFi)
        XCTAssertTrue(config.notifyBeforeInstall)
        XCTAssertTrue(config.backupBeforeUpdate)
    }
    
    func testSetUpdateConfiguration() {
        var newConfig = ModelUpdateManager.UpdateConfiguration()
        newConfig.autoCheckEnabled = false
        newConfig.updateChannel = .beta
        newConfig.checkInterval = 12 * 60 * 60 // 12 hours
        newConfig.downloadOnlyOnWiFi = false
        newConfig.notifyBeforeInstall = false
        
        updateManager.setUpdateConfiguration(newConfig)
        
        let retrievedConfig = updateManager.getUpdateConfiguration()
        XCTAssertEqual(retrievedConfig.autoCheckEnabled, false)
        XCTAssertEqual(retrievedConfig.updateChannel, .beta)
        XCTAssertEqual(retrievedConfig.checkInterval, 12 * 60 * 60)
        XCTAssertEqual(retrievedConfig.downloadOnlyOnWiFi, false)
        XCTAssertEqual(retrievedConfig.notifyBeforeInstall, false)
    }
    
    // MARK: - Model Version Tests
    
    func testModelVersionCreation() {
        let version = ModelUpdateManager.ModelVersion(
            version: "1.0.0",
            buildNumber: "20240101",
            releaseDate: Date(),
            modelSize: 600_000_000,
            checksum: "abc123",
            description: "Test version",
            changelog: ["Test change 1", "Test change 2"],
            updateType: .minor,
            minimumSystemVersion: "12.0"
        )
        
        XCTAssertEqual(version.version, "1.0.0")
        XCTAssertEqual(version.buildNumber, "20240101")
        XCTAssertEqual(version.modelSize, 600_000_000)
        XCTAssertEqual(version.checksum, "abc123")
        XCTAssertEqual(version.description, "Test version")
        XCTAssertEqual(version.changelog.count, 2)
        XCTAssertEqual(version.updateType, .minor)
        XCTAssertEqual(version.minimumSystemVersion, "12.0")
        XCTAssertTrue(version.isCompatible)
    }
    
    func testVersionComparison() {
        let manager = ModelUpdateManager.shared
        
        // Test newer version detection
        XCTAssertTrue(manager.isNewerVersion("1.1.0", currentVersion: "1.0.0"))
        XCTAssertTrue(manager.isNewerVersion("2.0.0", currentVersion: "1.9.9"))
        XCTAssertFalse(manager.isNewerVersion("1.0.0", currentVersion: "1.1.0"))
        XCTAssertFalse(manager.isNewerVersion("1.0.0", currentVersion: "1.0.0"))
    }
    
    // MARK: - Update Channel Tests
    
    func testUpdateChannelCompatibility() {
        let stableVersion = ModelUpdateManager.ModelVersion(
            version: "1.0.1",
            buildNumber: "20240102",
            releaseDate: Date(),
            modelSize: 600_000_000,
            checksum: "def456",
            description: "Stable update",
            changelog: ["Bug fixes"],
            updateType: .minor,
            minimumSystemVersion: "12.0"
        )
        
        var config = ModelUpdateManager.UpdateConfiguration()
        config.updateChannel = .stable
        
        updateManager.setUpdateConfiguration(config)
        
        // Test stable channel compatibility
        XCTAssertTrue(updateManager.isUpdateCompatibleWithChannel(stableVersion))
        
        // Test beta channel compatibility
        config.updateChannel = .beta
        updateManager.setUpdateConfiguration(config)
        XCTAssertTrue(updateManager.isUpdateCompatibleWithChannel(stableVersion))
    }
    
    // MARK: - Update History Tests
    
    func testUpdateHistory() async {
        let history = await updateManager.getUpdateHistory()
        
        XCTAssertNotNil(history)
        // History may be empty in test environment
    }
    
    // MARK: - Performance Tests
    
    func testUpdateCheckPerformance() async {
        let startTime = Date()
        
        do {
            _ = try await updateManager.checkForUpdates()
            let endTime = Date()
            let processingTime = endTime.timeIntervalSince(startTime)
            
            XCTAssertLessThan(processingTime, 5.0) // Should complete within 5 seconds
        } catch {
            XCTFail("Update check failed: \(error)")
        }
    }
    
    func testConfigurationUpdatePerformance() {
        let startTime = Date()
        
        let config = ModelUpdateManager.UpdateConfiguration()
        updateManager.setUpdateConfiguration(config)
        
        let endTime = Date()
        let processingTime = endTime.timeIntervalSince(startTime)
        
        XCTAssertLessThan(processingTime, 1.0) // Should complete within 1 second
    }
}

class ModelUpdateSchedulerTests: XCTestCase {
    
    var scheduler: ModelUpdateScheduler!
    
    override func setUp() {
        super.setUp()
        scheduler = ModelUpdateScheduler.shared
    }
    
    override func tearDown() {
        scheduler = nil
        super.tearDown()
    }
    
    // MARK: - Scheduling Tests
    
    func testScheduleImmediateUpdate() async {
        let version = ModelUpdateManager.ModelVersion(
            version: "1.0.1",
            buildNumber: "20240102",
            releaseDate: Date(),
            modelSize: 600_000_000,
            checksum: "def456",
            description: "Test update",
            changelog: ["Test change"],
            updateType: .minor,
            minimumSystemVersion: "12.0"
        )
        
        let scheduleId = await scheduler.scheduleUpdate(
            version: version,
            schedule: .immediate,
            priority: .normal
        )
        
        XCTAssertFalse(scheduleId.isEmpty)
        
        let scheduledUpdates = scheduler.getScheduledUpdates()
        XCTAssertFalse(scheduledUpdates.isEmpty)
        XCTAssertEqual(scheduledUpdates.first?.version.version, "1.0.1")
    }
    
    func testScheduleSpecificTimeUpdate() async {
        let version = ModelUpdateManager.ModelVersion(
            version: "1.0.2",
            buildNumber: "20240103",
            releaseDate: Date(),
            modelSize: 600_000_000,
            checksum: "ghi789",
            description: "Test update",
            changelog: ["Test change"],
            updateType: .minor,
            minimumSystemVersion: "12.0"
        )
        
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now
        
        let scheduleId = await scheduler.scheduleUpdate(
            version: version,
            schedule: .specificTime(futureDate),
            priority: .normal
        )
        
        XCTAssertFalse(scheduleId.isEmpty)
        
        let scheduledUpdates = scheduler.getScheduledUpdates()
        let scheduledUpdate = scheduledUpdates.first { $0.id == scheduleId }
        
        XCTAssertNotNil(scheduledUpdate)
        if let update = scheduledUpdate {
            XCTAssertEqual(update.version.version, "1.0.2")
            XCTAssertEqual(update.priority, .normal)
        }
    }
    
    func testCancelScheduledUpdate() async {
        let version = ModelUpdateManager.ModelVersion(
            version: "1.0.3",
            buildNumber: "20240104",
            releaseDate: Date(),
            modelSize: 600_000_000,
            checksum: "jkl012",
            description: "Test update",
            changelog: ["Test change"],
            updateType: .minor,
            minimumSystemVersion: "12.0"
        )
        
        let scheduleId = await scheduler.scheduleUpdate(
            version: version,
            schedule: .immediate,
            priority: .normal
        )
        
        XCTAssertFalse(scheduleId.isEmpty)
        
        await scheduler.cancelScheduledUpdate(withId: scheduleId)
        
        let scheduledUpdates = scheduler.getScheduledUpdates()
        let cancelledUpdate = scheduledUpdates.first { $0.id == scheduleId }
        XCTAssertNil(cancelledUpdate)
    }
    
    func testGetScheduledUpdates() async {
        let version1 = ModelUpdateManager.ModelVersion(
            version: "1.0.1",
            buildNumber: "20240102",
            releaseDate: Date(),
            modelSize: 600_000_000,
            checksum: "def456",
            description: "Test update",
            changelog: ["Test change"],
            updateType: .minor,
            minimumSystemVersion: "12.0"
        )
        
        let version2 = ModelUpdateManager.ModelVersion(
            version: "1.0.2",
            buildNumber: "20240103",
            releaseDate: Date(),
            modelSize: 600_000_000,
            checksum: "ghi789",
            description: "Test update",
            changelog: ["Test change"],
            updateType: .minor,
            minimumSystemVersion: "12.0"
        )
        
        let scheduleId1 = await scheduler.scheduleUpdate(
            version: version1,
            schedule: .immediate,
            priority: .normal
        )
        
        let scheduleId2 = await scheduler.scheduleUpdate(
            version: version2,
            schedule: .immediate,
            priority: .high
        )
        
        XCTAssertFalse(scheduleId1.isEmpty)
        XCTAssertFalse(scheduleId2.isEmpty)
        
        let scheduledUpdates = scheduler.getScheduledUpdates()
        XCTAssertEqual(scheduledUpdates.count, 2)
        
        // Should be sorted by priority (high first)
        XCTAssertEqual(scheduledUpdates.first?.priority, .high)
    }
    
    // MARK: - Time Calculation Tests
    
    func testMaintenanceWindowCalculation() async {
        let version = ModelUpdateManager.ModelVersion(
            version: "1.0.1",
            buildNumber: "20240102",
            releaseDate: Date(),
            modelSize: 600_000_000,
            checksum: "def456",
            description: "Test update",
            changelog: ["Test change"],
            updateType: .minor,
            minimumSystemVersion: "12.0"
        )
        
        let scheduleId = await scheduler.scheduleUpdate(
            version: version,
            schedule: .maintenanceWindow,
            priority: .normal
        )
        
        XCTAssertFalse(scheduleId.isEmpty)
        
        let scheduledUpdates = scheduler.getScheduledUpdates()
        let scheduledUpdate = scheduledUpdates.first { $0.id == scheduleId }
        
        XCTAssertNotNil(scheduledUpdate)
        if let update = scheduledUpdate {
            XCTAssertEqual(update.schedule, .maintenanceWindow)
        }
    }
    
    func testLowUsagePeriodCalculation() async {
        let version = ModelUpdateManager.ModelVersion(
            version: "1.0.1",
            buildNumber: "20240102",
            releaseDate: Date(),
            modelSize: 600_000_000,
            checksum: "def456",
            description: "Test update",
            changelog: ["Test change"],
            updateType: .minor,
            minimumSystemVersion: "12.0"
        )
        
        let scheduleId = await scheduler.scheduleUpdate(
            version: version,
            schedule: .lowUsagePeriod,
            priority: .normal
        )
        
        XCTAssertFalse(scheduleId.isEmpty)
        
        let scheduledUpdates = scheduler.getScheduledUpdates()
        let scheduledUpdate = scheduledUpdates.first { $0.id == scheduleId }
        
        XCTAssertNotNil(scheduledUpdate)
        if let update = scheduledUpdate {
            XCTAssertEqual(update.schedule, .lowUsagePeriod)
        }
    }
    
    // MARK: - Duration Estimation Tests
    
    func testDurationEstimation() {
        let smallVersion = ModelUpdateManager.ModelVersion(
            version: "1.0.1",
            buildNumber: "20240102",
            releaseDate: Date(),
            modelSize: 100_000_000, // 100MB
            checksum: "def456",
            description: "Small update",
            changelog: ["Small change"],
            updateType: .minor,
            minimumSystemVersion: "12.0"
        )
        
        let largeVersion = ModelUpdateManager.ModelVersion(
            version: "2.0.0",
            buildNumber: "20240103",
            releaseDate: Date(),
            modelSize: 2_000_000_000, // 2GB
            checksum: "ghi789",
            description: "Large update",
            changelog: ["Major changes"],
            updateType: .major,
            minimumSystemVersion: "12.0"
        )
        
        let smallDuration = scheduler.estimateUpdateDuration(for: smallVersion)
        let largeDuration = scheduler.estimateUpdateDuration(for: largeVersion)
        
        XCTAssertGreaterThan(smallDuration, 0)
        XCTAssertGreaterThan(largeDuration, 0)
        XCTAssertGreaterThan(largeDuration, smallDuration)
    }
    
    // MARK: - Smart Scheduling Tests
    
    func testOptimalScheduleSuggestion() async {
        let version = ModelUpdateManager.ModelVersion(
            version: "1.0.1",
            buildNumber: "20240102",
            releaseDate: Date(),
            modelSize: 600_000_000,
            checksum: "def456",
            description: "Test update",
            changelog: ["Test change"],
            updateType: .minor,
            minimumSystemVersion: "12.0"
        )
        
        let suggestedSchedule = await scheduler.suggestOptimalUpdateSchedule(for: version)
        
        XCTAssertNotNil(suggestedSchedule)
        
        // Test critical update suggestion
        let criticalVersion = ModelUpdateManager.ModelVersion(
            version: "1.0.1",
            buildNumber: "20240102",
            releaseDate: Date(),
            modelSize: 600_000_000,
            checksum: "def456",
            description: "Critical update",
            changelog: ["Critical fix"],
            updateType: .critical,
            minimumSystemVersion: "12.0"
        )
        
        let criticalSchedule = await scheduler.suggestOptimalUpdateSchedule(for: criticalVersion)
        XCTAssertEqual(criticalSchedule, .immediate)
    }
}

class ModelUpdateNotificationManagerTests: XCTestCase {
    
    var notificationManager: ModelUpdateNotificationManager!
    
    override func setUp() {
        super.setUp()
        notificationManager = ModelUpdateNotificationManager.shared
    }
    
    override func tearDown() {
        notificationManager = nil
        super.tearDown()
    }
    
    // MARK: - Notification Tests
    
    func testNotificationAuthorization() async {
        await notificationManager.requestNotificationAuthorization()
        // Test passes if no exception is thrown
    }
    
    func testUpdateAvailableNotification() async {
        let version = ModelUpdateManager.ModelVersion(
            version: "1.0.1",
            buildNumber: "20240102",
            releaseDate: Date(),
            modelSize: 600_000_000,
            checksum: "def456",
            description: "Test update",
            changelog: ["Test change"],
            updateType: .minor,
            minimumSystemVersion: "12.0"
        )
        
        await notificationManager.notifyUpdateAvailable(version: version)
        // Test passes if no exception is thrown
    }
    
    func testDownloadCompleteNotification() async {
        let version = ModelUpdateManager.ModelVersion(
            version: "1.0.1",
            buildNumber: "20240102",
            releaseDate: Date(),
            modelSize: 600_000_000,
            checksum: "def456",
            description: "Test update",
            changelog: ["Test change"],
            updateType: .minor,
            minimumSystemVersion: "12.0"
        )
        
        await notificationManager.notifyDownloadComplete(version: version)
        // Test passes if no exception is thrown
    }
    
    func testUpdateCompleteNotification() async {
        let version = ModelUpdateManager.ModelVersion(
            version: "1.0.1",
            buildNumber: "20240102",
            releaseDate: Date(),
            modelSize: 600_000_000,
            checksum: "def456",
            description: "Test update",
            changelog: ["Test change"],
            updateType: .minor,
            minimumSystemVersion: "12.0"
        )
        
        await notificationManager.notifyUpdateComplete(version: version)
        // Test passes if no exception is thrown
    }
    
    func testUpdateFailedNotification() async {
        let version = ModelUpdateManager.ModelVersion(
            version: "1.0.1",
            buildNumber: "20240102",
            releaseDate: Date(),
            modelSize: 600_000_000,
            checksum: "def456",
            description: "Test update",
            changelog: ["Test change"],
            updateType: .minor,
            minimumSystemVersion: "12.0"
        )
        
        let testError = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        await notificationManager.notifyUpdateFailed(version: version, error: testError)
        // Test passes if no exception is thrown
    }
    
    func testNotificationCancellation() async {
        let testIdentifier = "test_notification_\(UUID().uuidString)"
        
        await notificationManager.cancelNotification(withIdentifier: testIdentifier)
        // Test passes if no exception is thrown
    }
    
    func testCancelAllNotifications() async {
        await notificationManager.cancelAllNotifications()
        // Test passes if no exception is thrown
    }
    
    func testGetPendingNotifications() async {
        let pendingNotifications = await notificationManager.getPendingNotifications()
        XCTAssertNotNil(pendingNotifications)
    }
}