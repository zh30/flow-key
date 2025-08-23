import Foundation
import CloudKit
import Combine
import CoreData

// MARK: - CloudKit Sync Manager

@MainActor
public class CloudKitSyncManager: ObservableObject {
    @Published public private(set) var isSyncEnabled = false
    @Published public private(set) var isSyncing = false
    @Published public private(set) var lastSyncDate: Date?
    @Published public private(set) var syncStatus: SyncStatus = .notStarted
    @Published public private(set) var syncError: Error?
    
    // MARK: - Initialization
    
    public func initialize() async {
        // Initialize CloudKit sync manager
        do {
            try await checkCloudKitAvailability()
        } catch {
            print("CloudKit availability check failed: \(error)")
        }
        print("CloudKit sync manager initialized")
    }
    
    public enum SyncStatus {
        case notStarted
        case checkingAccount
        case fetchingChanges
        case uploadingChanges
        case resolvingConflicts
        case completed
        case failed(Error)
        
        var displayName: String {
            switch self {
            case .notStarted: return "未开始"
            case .checkingAccount: return "检查账户"
            case .fetchingChanges: return "获取更改"
            case .uploadingChanges: return "上传更改"
            case .resolvingConflicts: return "解决冲突"
            case .completed: return "已完成"
            case .failed(let error): return "失败：\(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - CloudKit Configuration
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let publicDatabase: CKDatabase
    
    // MARK: - Record Types
    
    private enum RecordType: String {
        case translationRecord = "TranslationRecord"
        case knowledgeItem = "KnowledgeItem"
        case userSettings = "UserSettings"
        case userHabit = "UserHabit"
        case syncMetadata = "SyncMetadata"
    }
    
    // MARK: - Sync State
    
    private var syncToken: Data?
    private var serverChangeToken: CKServerChangeToken?
    private var cancellables = Set<AnyCancellable>()
    
    public static let shared = CloudKitSyncManager()
    
    private init() {
        self.container = CKContainer.default()
        self.privateDatabase = container.privateCloudDatabase
        self.publicDatabase = container.publicCloudDatabase
        
        setupNotificationObservers()
    }
    
        
    private func loadSettings() async {
        // Load settings from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "CloudKitSyncSettings") {
            let decoder = JSONDecoder()
            do {
                _ = try decoder.decode(CloudKitSyncSettings.self, from: data)
                await MainActor.run {
                    // Update settings if needed
                }
            } catch {
                print("Failed to load CloudKit sync settings: \(error)")
            }
        }
    }
    
    // MARK: - Public Methods
    
    public func checkCloudKitAvailability() async throws -> Bool {
        do {
            let accountStatus = try await container.accountStatus()
            return accountStatus == .available
        } catch {
            syncError = error
            return false
        }
    }
    
    public func requestPermission() async throws -> Bool {
        let status = try await container.accountStatus()
        
        switch status {
        case .available:
            return true
        case .noAccount:
            throw CloudKitError.noAccount
        case .restricted:
            throw CloudKitError.restricted
        case .couldNotDetermine:
            throw CloudKitError.couldNotDetermine
        case .temporarilyUnavailable:
            throw CloudKitError.temporarilyUnavailable
        @unknown default:
            throw CloudKitError.unknownStatus
        }
    }
    
    public func enableSync() async throws {
        guard !isSyncEnabled else { return }
        
        syncStatus = .checkingAccount
        
        // Check CloudKit availability
        let isAvailable = try await checkCloudKitAvailability()
        guard isAvailable else {
            throw CloudKitError.notAvailable
        }
        
        // Request permission
        let hasPermission = try await requestPermission()
        guard hasPermission else {
            throw CloudKitError.permissionDenied
        }
        
        // Create subscription for remote changes
        try await createSubscription()
        
        // Initial sync
        try await performInitialSync()
        
        isSyncEnabled = true
        lastSyncDate = Date()
        syncStatus = .completed
    }
    
    public func disableSync() async {
        guard isSyncEnabled else { return }
        
        // Remove subscription
        await removeSubscription()
        
        // Clear sync tokens
        syncToken = nil
        serverChangeToken = nil
        
        isSyncEnabled = false
        syncStatus = .notStarted
        lastSyncDate = nil
    }
    
    public func syncNow() async throws {
        guard isSyncEnabled else {
            throw CloudKitError.syncNotEnabled
        }
        
        isSyncing = true
        syncStatus = .fetchingChanges
        syncError = nil
        
        do {
            try await performSync()
            syncStatus = .completed
            lastSyncDate = Date()
        } catch {
            syncStatus = .failed(error)
            syncError = error
            throw error
        }
        
        isSyncing = false
    }
    
    // MARK: - Sync Operations
    
    private func performInitialSync() async throws {
        // Upload local changes first
        try await uploadLocalChanges()
        
        // Then fetch remote changes
        try await fetchRemoteChanges()
    }
    
    private func performSync() async throws {
        // Fetch remote changes
        try await fetchRemoteChanges()
        
        // Upload local changes
        try await uploadLocalChanges()
    }
    
    private func fetchRemoteChanges() async throws {
        syncStatus = .fetchingChanges
        
        let query = CKQuery(recordType: RecordType.translationRecord.rawValue, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]
        
        let (matchResults, cursor) = try await privateDatabase.records(matching: query)
        
        // Process matched records
        for recordID in matchResults {
            // TODO: Process each record and merge with local data
            print("Fetched record: \(recordID.recordName)")
        }
        
        // Handle cursor if there are more results
        if let cursor = cursor {
            // TODO: Handle pagination
            print("More results available")
        }
    }
    
    private func uploadLocalChanges() async throws {
        syncStatus = .uploadingChanges
        
        // Get unsynced local records
        let unsyncedRecords = getUnsyncedLocalRecords()
        
        for record in unsyncedRecords {
            let cloudRecord = convertToCloudRecord(record)
            
            do {
                try await privateDatabase.save(cloudRecord)
                markRecordAsSynced(record)
            } catch {
                print("Failed to upload record: \(error)")
            }
        }
    }
    
    // MARK: - Subscription Management
    
    private func createSubscription() async throws {
        let subscriptionID = "com.flowkit.cloudkit-sync"
        
        let subscription = CKQuerySubscription(
            recordType: RecordType.translationRecord.rawValue,
            predicate: NSPredicate(value: true),
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        
        subscription.notificationInfo = notificationInfo
        
        do {
            try await privateDatabase.save(subscription)
            print("CloudKit subscription created successfully")
        } catch {
            // Subscription might already exist
            print("CloudKit subscription already exists or failed: \(error)")
        }
    }
    
    private func removeSubscription() async {
        let subscriptionID = "com.flowkit.cloudkit-sync"
        
        do {
            try await privateDatabase.deleteSubscription(withID: subscriptionID)
            print("CloudKit subscription removed")
        } catch {
            print("Failed to remove CloudKit subscription: \(error)")
        }
    }
    
    // MARK: - Data Conversion
    
    private func convertToCloudRecord(_ localRecord: NSManagedObject) -> CKRecord {
        let record = CKRecord(recordType: RecordType.translationRecord.rawValue)
        
        // Convert local Core Data record to CloudKit record
        if let translation = localRecord as? TranslationRecord {
            record["originalText"] = translation.originalText
            record["translatedText"] = translation.translatedText
            record["sourceLanguage"] = translation.sourceLanguage
            record["targetLanguage"] = translation.targetLanguage
            record["timestamp"] = translation.timestamp
            record["confidence"] = translation.confidence
        }
        
        return record
    }
    
    private func convertToLocalRecord(_ cloudRecord: CKRecord) -> NSManagedObject {
        // Convert CloudKit record to local Core Data record
        // This would need to be implemented based on your data model
        let context = CoreDataManager.shared.viewContext
        
        if cloudRecord.recordType == RecordType.translationRecord.rawValue {
            let translation = TranslationRecord(context: context)
            translation.id = UUID(uuidString: cloudRecord.recordID.recordName) ?? UUID()
            translation.originalText = cloudRecord["originalText"] as? String ?? ""
            translation.translatedText = cloudRecord["translatedText"] as? String ?? ""
            translation.sourceLanguage = cloudRecord["sourceLanguage"] as? String ?? ""
            translation.targetLanguage = cloudRecord["targetLanguage"] as? String ?? ""
            translation.timestamp = cloudRecord["timestamp"] as? Date ?? Date()
            translation.confidence = cloudRecord["confidence"] as? Double ?? 0.0
            
            return translation
        }
        
        // Handle other record types as needed
        return NSManagedObject()
    }
    
    // MARK: - Local Data Management
    
    private func getUnsyncedLocalRecords() -> [NSManagedObject] {
        let context = CoreDataManager.shared.viewContext
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "TranslationRecord")
        
        // Fetch records that haven't been synced
        fetchRequest.predicate = NSPredicate(format: "synced == %@", NSNumber(value: false))
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch unsynced records: \(error)")
            return []
        }
    }
    
    private func markRecordAsSynced(_ record: NSManagedObject) {
        record.setValue(true, forKey: "synced")
        
        do {
            let context = CoreDataManager.shared.viewContext
            try context.save()
        } catch {
            print("Failed to mark record as synced: \(error)")
        }
    }
    
    // MARK: - Conflict Resolution
    
    private func resolveConflict(_ localRecord: NSManagedObject, remoteRecord: CKRecord) -> NSManagedObject {
        // Simple conflict resolution: use the most recently modified record
        let localModifiedDate = localRecord.value(forKey: "modificationDate") as? Date ?? Date.distantPast
        let remoteModifiedDate = remoteRecord["modificationDate"] as? Date ?? Date.distantPast
        
        if remoteModifiedDate > localModifiedDate {
            return convertToLocalRecord(remoteRecord)
        } else {
            return localRecord
        }
    }
    
    // MARK: - Notification Handling
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .cloudKitDataChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handleRemoteDataChange()
            }
        }
    }
    
    private func handleRemoteDataChange() async {
        guard isSyncEnabled else { return }
        
        do {
            try await syncNow()
        } catch {
            print("Failed to sync remote changes: \(error)")
        }
    }
}

// MARK: - CloudKit Errors

enum CloudKitError: Error, LocalizedError {
    case notAvailable
    case noAccount
    case restricted
    case couldNotDetermine
    case temporarilyUnavailable
    case permissionDenied
    case syncNotEnabled
    case unknownStatus
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "CloudKit 不可用"
        case .noAccount:
            return "未找到 iCloud 账户"
        case .restricted:
            return "iCloud 访问受限"
        case .couldNotDetermine:
            return "无法确定 iCloud 状态"
        case .temporarilyUnavailable:
            return "CloudKit 暂时不可用"
        case .permissionDenied:
            return "CloudKit 权限被拒绝"
        case .syncNotEnabled:
            return "同步功能未启用"
        case .unknownStatus:
            return "未知的 CloudKit 状态"
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let cloudKitDataChanged = Notification.Name("cloudKitDataChanged")
    static let cloudKitSyncCompleted = Notification.Name("cloudKitSyncCompleted")
    static let cloudKitSyncFailed = Notification.Name("cloudKitSyncFailed")
}

// MARK: - Sync Settings

public struct CloudKitSyncSettings: Codable {
    public var isEnabled: Bool = false
    public var autoSync: Bool = true
    public var syncInterval: TimeInterval = 3600 // 1 hour
    public var syncOnLaunch: Bool = true
    public var syncOnBackground: Bool = true
    public var conflictResolution: ConflictResolutionStrategy = .newestWins
    public var lastSyncDate: Date?
    public var syncStatistics: SyncStatistics = SyncStatistics()
    
    public init() {}
}

public enum ConflictResolutionStrategy: String, Codable {
    case newestWins = "newest_wins"
    case localWins = "local_wins"
    case remoteWins = "remote_wins"
    case manual = "manual"
    
    var displayName: String {
        switch self {
        case .newestWins: return "最新的获胜"
        case .localWins: return "本地获胜"
        case .remoteWins: return "远程获胜"
        case .manual: return "手动解决"
        }
    }
}

public struct SyncStatistics: Codable {
    public var totalSyncs: Int = 0
    public var successfulSyncs: Int = 0
    public var failedSyncs: Int = 0
    public var lastSuccessfulSync: Date?
    public var lastFailedSync: Date?
    public var totalRecordsUploaded: Int = 0
    public var totalRecordsDownloaded: Int = 0
    public var conflictsResolved: Int = 0
    
    public init() {}
    
    public var successRate: Double {
        guard totalSyncs > 0 else { return 0.0 }
        return Double(successfulSyncs) / Double(totalSyncs)
    }
}