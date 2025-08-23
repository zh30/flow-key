import Foundation
import SwiftUI
import Combine
import CoreData

// MARK: - Phrase Manager

@MainActor
public class PhraseManager: ObservableObject {
    @Published public private(set) var phrases: [Phrase] = []
    @Published public private(set) var categories: [PhraseCategory] = []
    @Published public private(set) var isProcessing = false
    @Published public private(set) var lastError: Error?
    
    // MARK: - Phrase Models
    
    public struct Phrase: Identifiable, Codable {
        public let id: String
        public let content: String
        public let category: PhraseCategory
        public let tags: [String]
        public let shortcut: String?
        public let priority: Int
        public let usageCount: Int
        public let lastUsed: Date?
        public let isFavorite: Bool
        public let createdAt: Date
        public let updatedAt: Date
        
        public init(
            id: String = UUID().uuidString,
            content: String,
            category: PhraseCategory,
            tags: [String] = [],
            shortcut: String? = nil,
            priority: Int = 0,
            usageCount: Int = 0,
            lastUsed: Date? = nil,
            isFavorite: Bool = false,
            createdAt: Date = Date(),
            updatedAt: Date = Date()
        ) {
            self.id = id
            self.content = content
            self.category = category
            self.tags = tags
            self.shortcut = shortcut
            self.priority = priority
            self.usageCount = usageCount
            self.lastUsed = lastUsed
            self.isFavorite = isFavorite
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }
    
    public enum PhraseCategory: String, CaseIterable, Codable {
        case greeting = "greeting"
        case work = "work"
        case email = "email"
        case meeting = "meeting"
        case social = "social"
        case technical = "technical"
        case personal = "personal"
        case custom = "custom"
        
        var displayName: String {
            switch self {
            case .greeting: return "问候语"
            case .work: return "工作"
            case .email: return "邮件"
            case .meeting: return "会议"
            case .social: return "社交"
            case .technical: return "技术"
            case .personal: return "个人"
            case .custom: return "自定义"
            }
        }
        
        var icon: String {
            switch self {
            case .greeting: return "hand.wave"
            case .work: return "briefcase"
            case .email: return "envelope"
            case .meeting: return "people"
            case .social: return "person.2"
            case .technical: return "code"
            case .personal: return "person"
            case .custom: return "star"
            }
        }
        
        var color: String {
            switch self {
            case .greeting: return "blue"
            case .work: return "green"
            case .email: return "orange"
            case .meeting: return "purple"
            case .social: return "pink"
            case .technical: return "red"
            case .personal: return "indigo"
            case .custom: return "yellow"
            }
        }
    }
    
    // MARK: - Properties
    
    private let context = CoreDataManager.shared.viewContext
    private let userHabitManager = UserHabitManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    public static let shared = PhraseManager()
    
    private init() {
        setupDefaultCategories()
        loadPhrases()
        setupNotificationObservers()
    }
    
    // MARK: - Public Methods
    
    public func addPhrase(
        content: String,
        category: PhraseCategory,
        tags: [String] = [],
        shortcut: String? = nil,
        priority: Int = 0,
        isFavorite: Bool = false
    ) async throws {
        isProcessing = true
        lastError = nil
        
        defer {
            isProcessing = false
        }
        
        let phrase = Phrase(
            content: content,
            category: category,
            tags: tags,
            shortcut: shortcut,
            priority: priority,
            isFavorite: isFavorite
        )
        
        // Save to Core Data
        try await savePhraseToCoreData(phrase)
        
        // Update published array
        phrases.append(phrase)
        
        // Sort by priority and usage
        sortPhrases()
        
        // Log to user habits
        await userHabitManager.logPhraseUsage(phrase.id, action: "created")
    }
    
    public func updatePhrase(_ phrase: Phrase) async throws {
        isProcessing = true
        lastError = nil
        
        defer {
            isProcessing = false
        }
        
        // Update in Core Data
        try await updatePhraseInCoreData(phrase)
        
        // Update in published array
        if let index = phrases.firstIndex(where: { $0.id == phrase.id }) {
            phrases[index] = phrase
        }
        
        // Sort phrases
        sortPhrases()
        
        // Log to user habits
        await userHabitManager.logPhraseUsage(phrase.id, action: "updated")
    }
    
    public func deletePhrase(_ phraseId: String) async throws {
        isProcessing = true
        lastError = nil
        
        defer {
            isProcessing = false
        }
        
        // Remove from Core Data
        try await deletePhraseFromCoreData(phraseId)
        
        // Remove from published array
        phrases.removeAll { $0.id == phraseId }
        
        // Log to user habits
        await userHabitManager.logPhraseUsage(phraseId, action: "deleted")
    }
    
    public func usePhrase(_ phraseId: String) async throws {
        isProcessing = true
        lastError = nil
        
        defer {
            isProcessing = false
        }
        
        guard let index = phrases.firstIndex(where: { $0.id == phraseId }) else {
            throw PhraseError.phraseNotFound
        }
        
        var updatedPhrase = phrases[index]
        updatedPhrase.usageCount += 1
        updatedPhrase.lastUsed = Date()
        updatedPhrase.updatedAt = Date()
        
        // Update in Core Data
        try await updatePhraseInCoreData(updatedPhrase)
        
        // Update in published array
        phrases[index] = updatedPhrase
        
        // Sort phrases
        sortPhrases()
        
        // Log to user habits
        await userHabitManager.logPhraseUsage(phraseId, action: "used")
    }
    
    public func searchPhrases(_ query: String) -> [Phrase] {
        let lowercasedQuery = query.lowercased()
        
        return phrases.filter { phrase in
            phrase.content.localizedCaseInsensitiveContains(query) ||
            phrase.tags.contains { $0.localizedCaseInsensitiveContains(query) } ||
            phrase.category.displayName.localizedCaseInsensitiveContains(query)
        }
    }
    
    public func getPhrasesByCategory(_ category: PhraseCategory) -> [Phrase] {
        return phrases.filter { $0.category == category }
    }
    
    public func getFavoritePhrases() -> [Phrase] {
        return phrases.filter { $0.isFavorite }
    }
    
    public func getRecentPhrases(limit: Int = 10) -> [Phrase] {
        return phrases
            .sorted { ($0.lastUsed ?? .distantPast) > ($1.lastUsed ?? .distantPast) }
            .prefix(limit)
            .map { $0 }
    }
    
    public func getFrequentlyUsedPhrases(limit: Int = 10) -> [Phrase] {
        return phrases
            .sorted { $0.usageCount > $1.usageCount }
            .prefix(limit)
            .map { $0 }
    }
    
    public func importPhrases(_ phrases: [Phrase]) async throws {
        isProcessing = true
        lastError = nil
        
        defer {
            isProcessing = false
        }
        
        for phrase in phrases {
            try await savePhraseToCoreData(phrase)
        }
        
        // Reload all phrases
        loadPhrases()
    }
    
    public func exportPhrases() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(phrases)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return "Failed to export phrases: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Recommendation Support Methods
    
    public func getPhrases(for app: String) -> [Phrase] {
        // Get app-specific phrases
        return phrases.filter { phrase in
            phrase.tags.contains { $0.lowercased().contains(app.lowercased()) }
        }
    }
    
    public func getTimeBasedPhrases(hour: Int, dayOfWeek: Int) -> [Phrase] {
        // Get time-based phrases
        var timePhrases: [Phrase] = []
        
        // Morning greetings
        if hour >= 6 && hour < 12 {
            timePhrases.append(contentsOf: phrases.filter { $0.category == .greeting })
        }
        
        // Work-related phrases during work hours
        if hour >= 9 && hour < 18 && dayOfWeek >= 2 && dayOfWeek <= 6 {
            timePhrases.append(contentsOf: phrases.filter { $0.category == .work })
        }
        
        // Evening phrases
        if hour >= 18 && hour < 22 {
            timePhrases.append(contentsOf: phrases.filter { $0.category == .social })
        }
        
        return timePhrases
    }
    
    public func getAppSpecificPhrases(appName: String) -> [Phrase] {
        // Get app-specific phrases based on app name
        switch appName.lowercased() {
        case "mail", "邮件":
            return phrases.filter { $0.category == .email }
        case "calendar", "日历":
            return phrases.filter { $0.category == .meeting }
        case "notes", "备忘录":
            return phrases.filter { $0.category == .personal }
        case "code", "xcode", "开发":
            return phrases.filter { $0.category == .technical }
        default:
            return getPhrases(for: appName)
        }
    }
    
    public func getPhrasesBasedOnHabits(preferences: UserPreferences) -> [Phrase] {
        // Get phrases based on user preferences and habits
        var habitPhrases: [Phrase] = []
        
        // Get frequently used phrases
        let frequentPhrases = phrases.filter { $0.usageCount > 5 }
        habitPhrases.append(contentsOf: frequentPhrases)
        
        // Get favorite phrases
        let favoritePhrases = phrases.filter { $0.isFavorite }
        habitPhrases.append(contentsOf: favoritePhrases)
        
        // Get recently used phrases
        let recentPhrases = phrases.filter { phrase in
            guard let lastUsed = phrase.lastUsed else { return false }
            let daysSinceUse = Date().timeIntervalSince(lastUsed) / (24 * 60 * 60)
            return daysSinceUse < 7
        }
        habitPhrases.append(contentsOf: recentPhrases)
        
        return Array(Set(habitPhrases))
    }
    
    public func getPhrases(containing text: String) -> [Phrase] {
        // Get phrases containing specific text
        return phrases.filter { phrase in
            phrase.content.lowercased().contains(text.lowercased()) ||
            phrase.tags.contains { $0.lowercased().contains(text.lowercased()) }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultCategories() {
        categories = PhraseCategory.allCases
        
        // Create default phrases if none exist
        if phrases.isEmpty {
            createDefaultPhrases()
        }
    }
    
    private func createDefaultPhrases() {
        let defaultPhrases: [Phrase] = [
            Phrase(
                content: "你好，很高兴见到你！",
                category: .greeting,
                tags: ["问候", "友好"],
                shortcut: "nihao",
                isFavorite: true
            ),
            Phrase(
                content: "谢谢你的帮助！",
                category: .greeting,
                tags: ["感谢", "礼貌"],
                shortcut: "xiexie"
            ),
            Phrase(
                content: "请稍等，我马上处理。",
                category: .work,
                tags: ["工作", "回复"],
                shortcut: "qingdeng"
            ),
            Phrase(
                content: "期待与您的合作！",
                category: .work,
                tags: ["合作", "商务"],
                shortcut: "hezuo"
            ),
            Phrase(
                content: "邮件已发送，请查收。",
                category: .email,
                tags: ["邮件", "通知"],
                shortcut: "email"
            ),
            Phrase(
                content: "会议时间确认，请准时参加。",
                category: .meeting,
                tags: ["会议", "提醒"],
                shortcut: "huiyi"
            ),
            Phrase(
                content: "let result = await function.call()",
                category: .technical,
                tags: ["代码", "JavaScript"],
                shortcut: "letresult"
            ),
            Phrase(
                content: "祝您有美好的一天！",
                category: .personal,
                tags: ["祝福", "日常"],
                shortcut: "zhuhao"
            )
        ]
        
        Task {
            do {
                try await importPhrases(defaultPhrases)
            } catch {
                print("Failed to create default phrases: \(error)")
            }
        }
    }
    
    private func loadPhrases() {
        let fetchRequest: NSFetchRequest<PhraseEntity> = PhraseEntity.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "priority", ascending: false),
            NSSortDescriptor(key: "usageCount", ascending: false)
        ]
        
        do {
            let entities = try context.fetch(fetchRequest)
            phrases = entities.map { entity in
                Phrase(
                    id: entity.id ?? UUID().uuidString,
                    content: entity.content ?? "",
                    category: PhraseCategory(rawValue: entity.category ?? "") ?? .custom,
                    tags: entity.tags as? [String] ?? [],
                    shortcut: entity.shortcut,
                    priority: Int(entity.priority),
                    usageCount: Int(entity.usageCount),
                    lastUsed: entity.lastUsed,
                    isFavorite: entity.isFavorite,
                    createdAt: entity.createdAt ?? Date(),
                    updatedAt: entity.updatedAt ?? Date()
                )
            }
        } catch {
            print("Failed to load phrases: \(error)")
            phrases = []
        }
    }
    
    private func sortPhrases() {
        phrases.sort { phrase1, phrase2 in
            if phrase1.priority != phrase2.priority {
                return phrase1.priority > phrase2.priority
            }
            if phrase1.isFavorite != phrase2.isFavorite {
                return phrase1.isFavorite
            }
            return phrase1.usageCount > phrase2.usageCount
        }
    }
    
    private func savePhraseToCoreData(_ phrase: Phrase) async throws {
        let entity = PhraseEntity(context: context)
        entity.id = phrase.id
        entity.content = phrase.content
        entity.category = phrase.category.rawValue
        entity.tags = phrase.tags as NSObject
        entity.shortcut = phrase.shortcut
        entity.priority = Int16(phrase.priority)
        entity.usageCount = Int16(phrase.usageCount)
        entity.lastUsed = phrase.lastUsed
        entity.isFavorite = phrase.isFavorite
        entity.createdAt = phrase.createdAt
        entity.updatedAt = phrase.updatedAt
        
        try context.save()
    }
    
    private func updatePhraseInCoreData(_ phrase: Phrase) async throws {
        let fetchRequest: NSFetchRequest<PhraseEntity> = PhraseEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", phrase.id)
        
        let entities = try context.fetch(fetchRequest)
        guard let entity = entities.first else {
            throw PhraseError.phraseNotFound
        }
        
        entity.content = phrase.content
        entity.category = phrase.category.rawValue
        entity.tags = phrase.tags as NSObject
        entity.shortcut = phrase.shortcut
        entity.priority = Int16(phrase.priority)
        entity.usageCount = Int16(phrase.usageCount)
        entity.lastUsed = phrase.lastUsed
        entity.isFavorite = phrase.isFavorite
        entity.updatedAt = phrase.updatedAt
        
        try context.save()
    }
    
    private func deletePhraseFromCoreData(_ phraseId: String) async throws {
        let fetchRequest: NSFetchRequest<PhraseEntity> = PhraseEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", phraseId)
        
        let entities = try context.fetch(fetchRequest)
        guard let entity = entities.first else {
            throw PhraseError.phraseNotFound
        }
        
        context.delete(entity)
        try context.save()
    }
    
    private func setupNotificationObservers() {
        // Listen for habit updates that might affect phrase recommendations
        NotificationCenter.default.addObserver(
            forName: .userHabitUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.updatePhraseRecommendations()
            }
        }
    }
    
    private func updatePhraseRecommendations() async {
        // Update phrase recommendations based on user habits
        // This could involve reordering phrases based on usage patterns
        sortPhrases()
    }
}

// MARK: - Core Data Entity

@objc(PhraseEntity)
public class PhraseEntity: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var content: String?
    @NSManaged public var category: String?
    @NSManaged public var tags: NSObject?
    @NSManaged public var shortcut: String?
    @NSManaged public var priority: Int16
    @NSManaged public var usageCount: Int16
    @NSManaged public var lastUsed: Date?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

// MARK: - Phrase Errors

enum PhraseError: Error, LocalizedError {
    case phraseNotFound
    case invalidContent
    case duplicateShortcut
    case categoryNotFound
    
    var errorDescription: String? {
        switch self {
        case .phraseNotFound:
            return "未找到指定的常用语"
        case .invalidContent:
            return "常用语内容无效"
        case .duplicateShortcut:
            return "快捷键已存在"
        case .categoryNotFound:
            return "未找到指定的分类"
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let phraseAdded = Notification.Name("phraseAdded")
    static let phraseUpdated = Notification.Name("phraseUpdated")
    static let phraseDeleted = Notification.Name("phraseDeleted")
    static let phraseUsed = Notification.Name("phraseUsed")
}