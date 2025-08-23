import Foundation
import CoreData

public class CoreDataManager {
    public static let shared = CoreDataManager()
    
    private init() {}
    
    // MARK: - Core Data Stack
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FlowKeyDataModel")
        
        // Load the model from the bundle
        guard let modelURL = Bundle.main.url(forResource: "FlowKeyDataModel", withExtension: "momd") else {
            fatalError("Unable to find Core Data model in bundle")
        }
        
        container.managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!
        
        // Store description configuration
        let storeDescription = NSPersistentStoreDescription()
        storeDescription.type = NSSQLiteStoreType
        storeDescription.url = applicationDocumentsDirectory.appendingPathComponent("FlowKeyDataModel.sqlite")
        
        // Enable lightweight migration
        storeDescription.shouldMigrateStoreAutomatically = true
        storeDescription.shouldInferMappingModelAutomatically = true
        
        // Add encryption if available
        if #available(macOS 10.15, *) {
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
        
        container.persistentStoreDescriptions = [storeDescription]
        
        // Load persistent stores
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stores: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    // MARK: - Public Properties
    
    public func initialize() {
        // Initialize Core Data
        _ = persistentContainer
        print("Core Data manager initialized")
    }
    
    public var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    public var backgroundContext: NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - Application Support Directory
    
    private var applicationDocumentsDirectory: URL {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard let url = urls.last else {
            fatalError("Unable to access application support directory")
        }
        
        // Create FlowKey directory if it doesn't exist
        let flowKeyURL = url.appendingPathComponent("FlowKey")
        try? FileManager.default.createDirectory(at: flowKeyURL, withIntermediateDirectories: true, attributes: nil)
        
        return flowKeyURL
    }
    
    // MARK: - Save Context
    
    public func saveContext() throws {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("Failed to save Core Data context: \(error)")
            throw error
        }
    }
    
    public func saveBackgroundContext() throws {
        guard backgroundContext.hasChanges else { return }
        
        do {
            try backgroundContext.save()
        } catch {
            print("Failed to save background Core Data context: \(error)")
            throw error
        }
    }
    
    // MARK: - Translation History Entity
    
    public func createTranslationRecord(
        originalText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String,
        translationMode: String,
        confidence: Double? = nil,
        context: String? = nil
    ) throws -> TranslationRecord {
        let record = TranslationRecord(context: context)
        record.id = UUID()
        record.originalText = originalText
        record.translatedText = translatedText
        record.sourceLanguage = sourceLanguage
        record.targetLanguage = targetLanguage
        record.translationMode = translationMode
        record.timestamp = Date()
        record.confidence = confidence ?? 0.0
        record.contextText = context
        
        try saveContext()
        return record
    }
    
    public func fetchTranslationHistory(limit: Int = 50) -> [TranslationRecord] {
        let request: NSFetchRequest<TranslationRecord> = TranslationRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch translation history: \(error)")
            return []
        }
    }
    
    public func searchTranslationHistory(query: String, limit: Int = 20) -> [TranslationRecord] {
        let request: NSFetchRequest<TranslationRecord> = TranslationRecord.fetchRequest()
        
        let predicate = NSPredicate(format: "originalText CONTAINS[cd] %@ OR translatedText CONTAINS[cd] %@ OR contextText CONTAINS[cd] %@", query, query, query)
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to search translation history: \(error)")
            return []
        }
    }
    
    public func deleteTranslationRecord(_ record: TranslationRecord) throws {
        context.delete(record)
        try saveContext()
    }
    
    public func clearAllTranslationHistory() throws {
        let request: NSFetchRequest<NSFetchRequestResult> = TranslationRecord.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            try saveContext()
        } catch {
            print("Failed to clear translation history: \(error)")
            throw error
        }
    }
    
    // MARK: - User Settings Entity
    
    public func getUserSettings() -> UserSettings? {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let settings = try context.fetch(request)
            return settings.first ?? createUserSettings()
        } catch {
            print("Failed to fetch user settings: \(error)")
            return createUserSettings()
        }
    }
    
    private func createUserSettings() -> UserSettings {
        let settings = UserSettings(context: context)
        settings.id = UUID()
        settings.launchAtLogin = false
        settings.showInMenuBar = true
        settings.autoCheckUpdates = true
        settings.interfaceLanguage = "zh-CN"
        settings.translationMode = "hybrid"
        settings.sourceLanguage = "auto"
        settings.targetLanguage = "zh"
        settings.showTranslationPopup = true
        settings.popupDuration = 5.0
        settings.mlxModelSize = "small"
        settings.knowledgeBaseEnabled = false
        settings.autoIndexDocuments = true
        settings.searchLimit = 10
        settings.icloudSyncEnabled = false
        settings.autoSync = true
        settings.syncInterval = 3600
        settings.createdAt = Date()
        settings.updatedAt = Date()
        
        try? saveContext()
        return settings
    }
    
    public func updateUserSettings(_ settings: UserSettings) throws {
        settings.updatedAt = Date()
        try saveContext()
    }
    
    // MARK: - Knowledge Base Entity
    
    public func createKnowledgeDocument(
        title: String,
        content: String,
        type: String,
        tags: [String] = [],
        metadata: [String: String] = [:]
    ) throws -> KnowledgeDocument {
        let document = KnowledgeDocument(context: context)
        document.id = UUID()
        document.title = title
        document.content = content
        document.documentType = type
        document.tags = tags as NSObject
        document.metadata = metadata as NSObject
        document.createdAt = Date()
        document.updatedAt = Date()
        document.isIndexed = false
        
        try saveContext()
        return document
    }
    
    public func fetchKnowledgeDocuments(limit: Int = 100) -> [KnowledgeDocument] {
        let request: NSFetchRequest<KnowledgeDocument> = KnowledgeDocument.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch knowledge documents: \(error)")
            return []
        }
    }
    
    public func searchKnowledgeDocuments(query: String, limit: Int = 20) -> [KnowledgeDocument] {
        let request: NSFetchRequest<KnowledgeDocument> = KnowledgeDocument.fetchRequest()
        
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@ OR content CONTAINS[cd] %@", query, query)
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to search knowledge documents: \(error)")
            return []
        }
    }
    
    public func deleteKnowledgeDocument(_ document: KnowledgeDocument) throws {
        context.delete(document)
        try saveContext()
    }
    
    // MARK: - User Habits Entity
    
    public func recordUserAction(
        actionType: String,
        details: [String: Any] = [:],
        contextText: String? = nil
    ) throws {
        let habit = UserHabit(context: context)
        habit.id = UUID()
        habit.actionType = actionType
        habit.details = details as NSObject
        habit.context = contextText
        habit.timestamp = Date()
        
        try saveContext()
    }
    
    public func getUserHabits(actionType: String? = nil, limit: Int = 100) -> [UserHabit] {
        let request: NSFetchRequest<UserHabit> = UserHabit.fetchRequest()
        
        if let action = actionType {
            request.predicate = NSPredicate(format: "actionType == %@", action)
        }
        
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch user habits: \(error)")
            return []
        }
    }
    
    // MARK: - Statistics
    
    public func getDatabaseStatistics() -> DatabaseStatistics {
        let translationCount = countEntities(entityName: "TranslationRecord")
        let knowledgeCount = countEntities(entityName: "KnowledgeDocument")
        let habitCount = countEntities(entityName: "UserHabit")
        
        return DatabaseStatistics(
            translationRecords: translationCount,
            knowledgeDocuments: knowledgeCount,
            userHabits: habitCount,
            lastUpdated: Date()
        )
    }
    
    private func countEntities(entityName: String) -> Int {
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
        request.resultType = .countResultType
        
        do {
            let result = try context.fetch(request)
            return result.first as? Int ?? 0
        } catch {
            print("Failed to count \(entityName): \(error)")
            return 0
        }
    }
    
    // MARK: - Cleanup
    
    public func cleanupOldData(olderThan days: Int) throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        // Clean up old translation records
        let translationRequest: NSFetchRequest<NSFetchRequestResult> = TranslationRecord.fetchRequest()
        translationRequest.predicate = NSPredicate(format: "timestamp < %@", cutoffDate as NSDate)
        let translationDelete = NSBatchDeleteRequest(fetchRequest: translationRequest)
        
        // Clean up old habits
        let habitRequest: NSFetchRequest<NSFetchRequestResult> = UserHabit.fetchRequest()
        habitRequest.predicate = NSPredicate(format: "timestamp < %@", cutoffDate as NSDate)
        let habitDelete = NSBatchDeleteRequest(fetchRequest: habitRequest)
        
        do {
            try context.execute(translationDelete)
            try context.execute(habitDelete)
            try saveContext()
        } catch {
            print("Failed to cleanup old data: \(error)")
            throw error
        }
    }
    
    // MARK: - Initialization
    
    public func initialize() {
        // Ensure user settings exist
        _ = getUserSettings()
        print("Core Data manager initialized")
    }
}

// MARK: - Supporting Structures

public struct DatabaseStatistics {
    public let translationRecords: Int
    public let knowledgeDocuments: Int
    public let userHabits: Int
    public let lastUpdated: Date
}