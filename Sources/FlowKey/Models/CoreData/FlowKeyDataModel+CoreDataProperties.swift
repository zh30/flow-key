import Foundation
import CoreData

extension TranslationRecord {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TranslationRecord> {
        return NSFetchRequest<TranslationRecord>(entityName: "TranslationRecord")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var originalText: String
    @NSManaged public var translatedText: String
    @NSManaged public var sourceLanguage: String
    @NSManaged public var targetLanguage: String
    @NSManaged public var translationMode: String
    @NSManaged public var timestamp: Date
    @NSManaged public var confidence: Double
    @NSManaged public var contextText: String?
    @NSManaged public var createdAt: Date
}

extension UserSettings {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserSettings> {
        return NSFetchRequest<UserSettings>(entityName: "UserSettings")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var launchAtLogin: Bool
    @NSManaged public var showInMenuBar: Bool
    @NSManaged public var autoCheckUpdates: Bool
    @NSManaged public var interfaceLanguage: String
    @NSManaged public var translationMode: String
    @NSManaged public var sourceLanguage: String
    @NSManaged public var targetLanguage: String
    @NSManaged public var showTranslationPopup: Bool
    @NSManaged public var popupDuration: Double
    @NSManaged public var mlxModelSize: String
    @NSManaged public var knowledgeBaseEnabled: Bool
    @NSManaged public var autoIndexDocuments: Bool
    @NSManaged public var searchLimit: Int
    @NSManaged public var icloudSyncEnabled: Bool
    @NSManaged public var autoSync: Bool
    @NSManaged public var syncInterval: Int
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

extension KnowledgeDocument {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<KnowledgeDocument> {
        return NSFetchRequest<KnowledgeDocument>(entityName: "KnowledgeDocument")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var content: String
    @NSManaged public var documentType: String
    @NSManaged public var tags: NSObject
    @NSManaged public var metadata: NSObject
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var isIndexed: Bool
}

extension UserHabit {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserHabit> {
        return NSFetchRequest<UserHabit>(entityName: "UserHabit")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var actionType: String
    @NSManaged public var details: NSObject
    @NSManaged public var context: String?
    @NSManaged public var timestamp: Date
}