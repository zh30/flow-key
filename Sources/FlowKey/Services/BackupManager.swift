import Foundation

public class BackupManager {
    public static let shared = BackupManager()
    
    private init() {}
    
    // MARK: - Backup Configuration
    
    private let backupDirectoryName = "FlowKeyBackups"
    private let maxBackupFiles = 10
    private let encryptionManager = DataEncryptionManager.shared
    private let coreDataManager = CoreDataManager.shared
    
    // MARK: - Backup Operations
    
    public func createBackup() async throws -> BackupInfo {
        let timestamp = Date()
        let backupFileName = "FlowKeyBackup_\(timestampString(timestamp)).flowkeybackup"
        
        // Create backup directory if it doesn't exist
        let backupDirectory = try getOrCreateBackupDirectory()
        let backupURL = backupDirectory.appendingPathComponent(backupFileName)
        
        // Collect data to backup
        let backupData = try collectBackupData()
        
        // Serialize backup data
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let serializedData = try encoder.encode(backupData)
        
        // Encrypt backup data if encryption is enabled
        let finalData: Data
        if PrivacyManager.shared.settings.enableEncryption {
            finalData = try encryptionManager.encryptData(serializedData)
        } else {
            finalData = serializedData
        }
        
        // Write backup file
        try finalData.write(to: backupURL)
        
        // Clean up old backups
        try cleanupOldBackups()
        
        let backupInfo = BackupInfo(
            id: UUID().uuidString,
            fileName: backupFileName,
            fileURL: backupURL,
            size: finalData.count,
            timestamp: timestamp,
            isEncrypted: PrivacyManager.shared.settings.enableEncryption,
            version: "1.0"
        )
        
        print("Backup created successfully: \(backupFileName)")
        return backupInfo
    }
    
    public func restoreBackup(from backupURL: URL) async throws -> RestoreResult {
        guard FileManager.default.fileExists(atPath: backupURL.path) else {
            throw BackupError.fileNotFound
        }
        
        // Read backup file
        let encryptedData = try Data(contentsOf: backupURL)
        
        // Decrypt if necessary
        let decryptedData: Data
        if isBackupEncrypted(backupURL) {
            decryptedData = try encryptionManager.decryptData(encryptedData)
        } else {
            decryptedData = encryptedData
        }
        
        // Deserialize backup data
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backupData = try decoder.decode(BackupData.self, from: decryptedData)
        
        // Validate backup data
        try validateBackupData(backupData)
        
        // Create restore point before applying changes
        try await createRestorePoint()
        
        // Apply backup data
        try await applyBackupData(backupData)
        
        let result = RestoreResult(
            backupId: backupData.id,
            timestamp: Date(),
            itemsRestored: backupData.translationRecords.count + backupData.userSettings.count + backupData.knowledgeDocuments.count,
            success: true
        )
        
        print("Backup restored successfully from: \(backupURL.lastPathComponent)")
        return result
    }
    
    public func getAvailableBackups() async throws -> [BackupInfo] {
        let backupDirectory = try getOrCreateBackupDirectory()
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: backupDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .creationDateKey, .contentModificationDateKey]
        )
        
        let backupFiles = fileURLs.filter { $0.pathExtension == "flowkeybackup" }
        
        var backups: [BackupInfo] = []
        
        for fileURL in backupFiles {
            do {
                let attributes = try fileURL.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
                let backupInfo = BackupInfo(
                    id: UUID().uuidString,
                    fileName: fileURL.lastPathComponent,
                    fileURL: fileURL,
                    size: attributes.fileSize ?? 0,
                    timestamp: attributes.creationDate ?? Date(),
                    isEncrypted: isBackupEncrypted(fileURL),
                    version: "1.0"
                )
                backups.append(backupInfo)
            } catch {
                print("Failed to read backup file attributes: \(error)")
            }
        }
        
        // Sort by timestamp (newest first)
        return backups.sorted { $0.timestamp > $1.timestamp }
    }
    
    public func deleteBackup(_ backupInfo: BackupInfo) throws {
        try FileManager.default.removeItem(at: backupInfo.fileURL)
        print("Backup deleted: \(backupInfo.fileName)")
    }
    
    public func scheduleAutomaticBackup() {
        // Schedule backup every 24 hours
        Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { _ in
            Task {
                do {
                    let backup = try await self.createBackup()
                    print("Automatic backup created: \(backup.fileName)")
                } catch {
                    print("Failed to create automatic backup: \(error)")
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func getOrCreateBackupDirectory() throws -> URL {
        let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        
        let backupDirectory = applicationSupportURL
            .appendingPathComponent("FlowKey")
            .appendingPathComponent(backupDirectoryName)
        
        try FileManager.default.createDirectory(
            at: backupDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        return backupDirectory
    }
    
    private func collectBackupData() throws -> BackupData {
        // Collect translation records
        let translationRecords = coreDataManager.fetchTranslationHistory(limit: 10000)
        
        // Collect user settings
        let userSettings = coreDataManager.getUserSettings()
        
        // Collect knowledge documents
        let knowledgeDocuments = coreDataManager.fetchKnowledgeDocuments(limit: 1000)
        
        // Collect user habits
        let userHabits = coreDataManager.getUserHabits(limit: 5000)
        
        return BackupData(
            id: UUID().uuidString,
            timestamp: Date(),
            version: "1.0",
            translationRecords: translationRecords.map { record in
                BackupTranslationRecord(
                    id: record.id.uuidString,
                    originalText: record.originalText,
                    translatedText: record.translatedText,
                    sourceLanguage: record.sourceLanguage,
                    targetLanguage: record.targetLanguage,
                    translationMode: record.translationMode,
                    confidence: record.confidence,
                    contextText: record.contextText,
                    timestamp: record.timestamp
                )
            },
            userSettings: BackupUserSettings(
                id: userSettings.id.uuidString,
                launchAtLogin: userSettings.launchAtLogin,
                showInMenuBar: userSettings.showInMenuBar,
                autoCheckUpdates: userSettings.autoCheckUpdates,
                interfaceLanguage: userSettings.interfaceLanguage,
                translationMode: userSettings.translationMode,
                sourceLanguage: userSettings.sourceLanguage,
                targetLanguage: userSettings.targetLanguage,
                showTranslationPopup: userSettings.showTranslationPopup,
                popupDuration: userSettings.popupDuration,
                mlxModelSize: userSettings.mlxModelSize,
                knowledgeBaseEnabled: userSettings.knowledgeBaseEnabled,
                autoIndexDocuments: userSettings.autoIndexDocuments,
                searchLimit: userSettings.searchLimit,
                icloudSyncEnabled: userSettings.icloudSyncEnabled,
                autoSync: userSettings.autoSync,
                syncInterval: userSettings.syncInterval,
                createdAt: userSettings.createdAt,
                updatedAt: userSettings.updatedAt
            ),
            knowledgeDocuments: knowledgeDocuments.map { document in
                BackupKnowledgeDocument(
                    id: document.id.uuidString,
                    title: document.title,
                    content: document.content,
                    documentType: document.documentType,
                    tags: document.tags as? [String] ?? [],
                    metadata: document.metadata as? [String: String] ?? [:],
                    createdAt: document.createdAt,
                    updatedAt: document.updatedAt,
                    isIndexed: document.isIndexed
                )
            },
            userHabits: userHabits.map { habit in
                BackupUserHabit(
                    id: habit.id.uuidString,
                    actionType: habit.actionType,
                    details: habit.details as? [String: Any] ?? [:],
                    context: habit.context,
                    timestamp: habit.timestamp
                )
            }
        )
    }
    
    private func applyBackupData(_ backupData: BackupData) async throws {
        // Clear existing data (optional - could be made configurable)
        try coreDataManager.clearAllTranslationHistory()
        
        // Restore user settings
        if let backupSettings = backupData.userSettings {
            if let currentSettings = coreDataManager.getUserSettings() {
                currentSettings.launchAtLogin = backupSettings.launchAtLogin
                currentSettings.showInMenuBar = backupSettings.showInMenuBar
                currentSettings.autoCheckUpdates = backupSettings.autoCheckUpdates
                currentSettings.interfaceLanguage = backupSettings.interfaceLanguage
                currentSettings.translationMode = backupSettings.translationMode
                currentSettings.sourceLanguage = backupSettings.sourceLanguage
                currentSettings.targetLanguage = backupSettings.targetLanguage
                currentSettings.showTranslationPopup = backupSettings.showTranslationPopup
                currentSettings.popupDuration = backupSettings.popupDuration
                currentSettings.mlxModelSize = backupSettings.mlxModelSize
                currentSettings.knowledgeBaseEnabled = backupSettings.knowledgeBaseEnabled
                currentSettings.autoIndexDocuments = backupSettings.autoIndexDocuments
                currentSettings.searchLimit = backupSettings.searchLimit
                currentSettings.icloudSyncEnabled = backupSettings.icloudSyncEnabled
                currentSettings.autoSync = backupSettings.autoSync
                currentSettings.syncInterval = backupSettings.syncInterval
                currentSettings.updatedAt = Date()
                
                try coreDataManager.updateUserSettings(currentSettings)
            }
        }
        
        // Restore translation records
        for record in backupData.translationRecords {
            _ = try coreDataManager.createTranslationRecord(
                originalText: record.originalText,
                translatedText: record.translatedText,
                sourceLanguage: record.sourceLanguage,
                targetLanguage: record.targetLanguage,
                translationMode: record.translationMode,
                confidence: record.confidence,
                context: record.contextText
            )
        }
        
        // Restore knowledge documents
        for document in backupData.knowledgeDocuments {
            _ = try coreDataManager.createKnowledgeDocument(
                title: document.title,
                content: document.content,
                type: document.documentType,
                tags: document.tags,
                metadata: document.metadata
            )
        }
        
        // Restore user habits
        for habit in backupData.userHabits {
            try coreDataManager.recordUserAction(
                actionType: habit.actionType,
                details: habit.details,
                contextText: habit.context
            )
        }
    }
    
    private func validateBackupData(_ backupData: BackupData) throws {
        guard !backupData.id.isEmpty else {
            throw BackupError.invalidBackupData("Missing backup ID")
        }
        
        guard backupData.version.hasPrefix("1.") else {
            throw BackupError.incompatibleVersion("Backup version \(backupData.version) is not supported")
        }
        
        // Validate data integrity
        for record in backupData.translationRecords {
            guard !record.originalText.isEmpty else {
                throw BackupError.invalidBackupData("Empty original text in translation record")
            }
        }
    }
    
    private func createRestorePoint() async throws {
        // Create a backup of current state before restore
        _ = try await createBackup()
    }
    
    private func cleanupOldBackups() throws {
        let backupDirectory = try getOrCreateBackupDirectory()
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: backupDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: []
        )
        
        let backupFiles = fileURLs
            .filter { $0.pathExtension == "flowkeybackup" }
        
        // Sort by creation date
        let sortedFiles = try backupFiles.sorted { url1, url2 in
            let date1 = try url1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date()
            let date2 = try url2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date()
            return date1 > date2
        }
        
        // Delete oldest backups if we have too many
        if sortedFiles.count > maxBackupFiles {
            for backupFile in sortedFiles.dropFirst(maxBackupFiles) {
                try FileManager.default.removeItem(at: backupFile)
            }
        }
    }
    
    private func isBackupEncrypted(_ backupURL: URL) -> Bool {
        // Simple heuristic: encrypted files typically have a different size pattern
        // In production, this could be stored in the backup metadata
        return PrivacyManager.shared.settings.enableEncryption
    }
    
    private func timestampString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: date)
    }
    
    // MARK: - Initialization
    
    public func initialize() {
        // Schedule automatic backup
        scheduleAutomaticBackup()
        
        print("Backup manager initialized")
    }
}

// MARK: - Backup Data Structures

public struct BackupInfo: Identifiable {
    public let id: String
    public let fileName: String
    public let fileURL: URL
    public let size: Int
    public let timestamp: Date
    public let isEncrypted: Bool
    public let version: String
}

public struct RestoreResult {
    public let backupId: String
    public let timestamp: Date
    public let itemsRestored: Int
    public let success: Bool
}

public struct BackupData: Codable {
    public let id: String
    public let timestamp: Date
    public let version: String
    public let translationRecords: [BackupTranslationRecord]
    public let userSettings: BackupUserSettings?
    public let knowledgeDocuments: [BackupKnowledgeDocument]
    public let userHabits: [BackupUserHabit]
}

public struct BackupTranslationRecord: Codable {
    public let id: String
    public let originalText: String
    public let translatedText: String
    public let sourceLanguage: String
    public let targetLanguage: String
    public let translationMode: String
    public let confidence: Double
    public let contextText: String?
    public let timestamp: Date
}

public struct BackupUserSettings: Codable {
    public let id: String
    public let launchAtLogin: Bool
    public let showInMenuBar: Bool
    public let autoCheckUpdates: Bool
    public let interfaceLanguage: String
    public let translationMode: String
    public let sourceLanguage: String
    public let targetLanguage: String
    public let showTranslationPopup: Bool
    public let popupDuration: Double
    public let mlxModelSize: String
    public let knowledgeBaseEnabled: Bool
    public let autoIndexDocuments: Bool
    public let searchLimit: Int
    public let icloudSyncEnabled: Bool
    public let autoSync: Bool
    public let syncInterval: Int
    public let createdAt: Date
    public let updatedAt: Date
}

public struct BackupKnowledgeDocument: Codable {
    public let id: String
    public let title: String
    public let content: String
    public let documentType: String
    public let tags: [String]
    public let metadata: [String: String]
    public let createdAt: Date
    public let updatedAt: Date
    public let isIndexed: Bool
}

public struct BackupUserHabit: Codable {
    public let id: String
    public let actionType: String
    public let details: [String: Any]
    public let context: String?
    public let timestamp: Date
}

// MARK: - Backup Error Types

public enum BackupError: Error, LocalizedError {
    case fileNotFound
    case invalidBackupData(String)
    case incompatibleVersion(String)
    case encryptionFailed
    case decryptionFailed
    case restoreFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Backup file not found"
        case .invalidBackupData(let message):
            return "Invalid backup data: \(message)"
        case .incompatibleVersion(let version):
            return "Incompatible backup version: \(version)"
        case .encryptionFailed:
            return "Backup encryption failed"
        case .decryptionFailed:
            return "Backup decryption failed"
        case .restoreFailed(let message):
            return "Restore failed: \(message)"
        }
    }
}