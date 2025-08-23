import Foundation
import SwiftUI

public class KnowledgeBaseManager {
    public static let shared = KnowledgeBaseManager()
    
    private init() {}
    
    // MARK: - Knowledge Base Types
    
    public enum KnowledgeCategory: String, CaseIterable {
        case personal = "personal"
        case work = "work"
        case study = "study"
        case research = "research"
        case documentation = "documentation"
        case code = "code"
        case notes = "notes"
        case bookmarks = "bookmarks"
        
        public var displayName: String {
            switch self {
            case .personal: return "个人"
            case .work: return "工作"
            case .study: return "学习"
            case .research: return "研究"
            case .documentation: return "文档"
            case .code: return "代码"
            case .notes: return "笔记"
            case .bookmarks: return "书签"
            }
        }
        
        public var icon: String {
            switch self {
            case .personal: return "person"
            case .work: return "briefcase"
            case .study: return "book"
            case .research: return "magnifyingglass"
            case .documentation: return "doc"
            case .code: return "curlybraces"
            case .notes: return "note.text"
            case .bookmarks: return "bookmark"
            }
        }
        
        public var color: String {
            switch self {
            case .personal: return "blue"
            case .work: return "green"
            case .study: return "orange"
            case .research: return "purple"
            case .documentation: return "gray"
            case .code: return "red"
            case .notes: return "yellow"
            case .bookmarks: return "pink"
            }
        }
    }
    
    public enum KnowledgeType: String, CaseIterable {
        case text = "text"
        case markdown = "markdown"
        case code = "code"
        case pdf = "pdf"
        case webpage = "webpage"
        case image = "image"
        case audio = "audio"
        case video = "video"
        case link = "link"
        case note = "note"
        
        public var displayName: String {
            switch self {
            case .text: return "文本"
            case .markdown: return "Markdown"
            case .code: return "代码"
            case .pdf: return "PDF"
            case .webpage: return "网页"
            case .image: return "图片"
            case .audio: return "音频"
            case .video: return "视频"
            case .link: return "链接"
            case .note: return "笔记"
            }
        }
        
        public var fileExtensions: [String] {
            switch self {
            case .text: return ["txt", "text"]
            case .markdown: return ["md", "markdown"]
            case .code: return ["py", "js", "ts", "java", "swift", "cpp", "c", "go", "rs", "rb", "php"]
            case .pdf: return ["pdf"]
            case .webpage: return ["html", "htm"]
            case .image: return ["jpg", "jpeg", "png", "gif", "bmp", "tiff"]
            case .audio: return ["mp3", "wav", "aac", "flac"]
            case .video: return ["mp4", "avi", "mov", "wmv", "flv"]
            case .link: return ["url", "link"]
            case .note: return ["note", "txt"]
            }
        }
    }
    
    public struct KnowledgeItem {
        public let id: String
        public let title: String
        public let content: String
        public let type: KnowledgeType
        public let category: KnowledgeCategory
        public let tags: [String]
        public let metadata: [String: String]
        public let createdAt: Date
        public let updatedAt: Date
        public let fileSize: Int64?
        public let url: URL?
        public let embedding: [Float]?
        public let isStarred: Bool
        public let isArchived: Bool
        
        public init(id: String, title: String, content: String, type: KnowledgeType, category: KnowledgeCategory,
                    tags: [String] = [], metadata: [String: String] = [:], createdAt: Date = Date(),
                    updatedAt: Date = Date(), fileSize: Int64? = nil, url: URL? = nil, embedding: [Float]? = nil,
                    isStarred: Bool = false, isArchived: Bool = false) {
            self.id = id
            self.title = title
            self.content = content
            self.type = type
            self.category = category
            self.tags = tags
            self.metadata = metadata
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.fileSize = fileSize
            self.url = url
            self.embedding = embedding
            self.isStarred = isStarred
            self.isArchived = isArchived
        }
    }
    
    public struct KnowledgeCollection {
        public let id: String
        public let name: String
        public let description: String?
        public let items: [String] // KnowledgeItem IDs
        public let category: KnowledgeCategory?
        public let tags: [String]
        public let createdAt: Date
        public let updatedAt: Date
        public let isPublic: Bool
        
        public init(id: String, name: String, description: String? = nil, items: [String] = [],
                    category: KnowledgeCategory? = nil, tags: [String] = [], createdAt: Date = Date(),
                    updatedAt: Date = Date(), isPublic: Bool = false) {
            self.id = id
            self.name = name
            self.description = description
            self.items = items
            self.category = category
            self.tags = tags
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.isPublic = isPublic
        }
    }
    
    public struct SearchResult {
        public let item: KnowledgeItem
        public let score: Double
        public let snippet: String
        public let matchedTerms: [String]
        public let categoryMatch: Bool
        public let tagMatch: Bool
        
        public init(item: KnowledgeItem, score: Double, snippet: String, matchedTerms: [String],
                    categoryMatch: Bool = false, tagMatch: Bool = false) {
            self.item = item
            self.score = score
            self.snippet = snippet
            self.matchedTerms = matchedTerms
            self.categoryMatch = categoryMatch
            self.tagMatch = tagMatch
        }
    }
    
    public struct KnowledgeStats {
        public let totalItems: Int
        public let itemsByCategory: [KnowledgeCategory: Int]
        public let itemsByType: [KnowledgeType: Int]
        public let totalSize: Int64
        public let starredItems: Int
        public let archivedItems: Int
        public let recentItems: Int
        public let tags: [String: Int]
        
        public init(totalItems: Int, itemsByCategory: [KnowledgeCategory: Int], itemsByType: [KnowledgeType: Int],
                    totalSize: Int64, starredItems: Int, archivedItems: Int, recentItems: Int, tags: [String: Int]) {
            self.totalItems = totalItems
            self.itemsByCategory = itemsByCategory
            self.itemsByType = itemsByType
            self.totalSize = totalSize
            self.starredItems = starredItems
            self.archivedItems = archivedItems
            self.recentItems = recentItems
            self.tags = tags
        }
    }
    
    // MARK: - Properties
    
    private var knowledgeItems: [KnowledgeItem] = []
    private var collections: [KnowledgeCollection] = []
    private let vectorDB = VectorDatabase.shared
    private let knowledgeManager = KnowledgeManager.shared
    private var isInitialized = false
    
    // MARK: - Initialization
    
    public func initialize() async {
        guard !isInitialized else { return }
        
        await knowledgeManager.initialize()
        await loadKnowledgeItems()
        await loadCollections()
        
        isInitialized = true
        print("Knowledge base manager initialized")
    }
    
    // MARK: - Knowledge Item Management
    
    public func addKnowledgeItem(
        title: String,
        content: String,
        type: KnowledgeType,
        category: KnowledgeCategory,
        tags: [String] = [],
        metadata: [String: String] = [:],
        url: URL? = nil
    ) async throws -> String {
        guard isInitialized else { throw KnowledgeError.notInitialized }
        
        let id = UUID().uuidString
        let fileSize = await calculateFileSize(content: content, type: type)
        
        let item = KnowledgeItem(
            id: id,
            title: title,
            content: content,
            type: type,
            category: category,
            tags: tags,
            metadata: metadata,
            fileSize: fileSize,
            url: url
        )
        
        // Add to vector database for search
        let vectorDocument = VectorDatabase.Document(
            id: id,
            title: title,
            content: content,
            type: convertToVectorDocumentType(type),
            tags: tags,
            metadata: metadata
        )
        
        try await vectorDB.addDocument(vectorDocument)
        
        // Add to local storage
        knowledgeItems.append(item)
        await saveKnowledgeItem(item)
        
        // Generate embedding
        let embedding = await generateEmbedding(for: content)
        if let embedding = embedding {
            if let index = knowledgeItems.firstIndex(where: { $0.id == id }) {
                knowledgeItems[index] = KnowledgeItem(
                    id: id,
                    title: title,
                    content: content,
                    type: type,
                    category: category,
                    tags: tags,
                    metadata: metadata,
                    fileSize: fileSize,
                    url: url,
                    embedding: embedding
                )
            }
        }
        
        return id
    }
    
    public func updateKnowledgeItem(
        id: String,
        title: String? = nil,
        content: String? = nil,
        category: KnowledgeCategory? = nil,
        tags: [String]? = nil,
        metadata: [String: String]? = nil,
        isStarred: Bool? = nil,
        isArchived: Bool? = nil
    ) async throws {
        guard isInitialized else { throw KnowledgeError.notInitialized }
        
        guard let index = knowledgeItems.firstIndex(where: { $0.id == id }) else {
            throw KnowledgeError.itemNotFound
        }
        
        var item = knowledgeItems[index]
        
        // Update fields
        if let title = title { item.title = title }
        if let content = content { item.content = content }
        if let category = category { item.category = category }
        if let tags = tags { item.tags = tags }
        if let metadata = metadata { item.metadata = metadata }
        if let isStarred = isStarred { item.isStarred = isStarred }
        if let isArchived = isArchived { item.isArchived = isArchived }
        
        // Update timestamp
        item = KnowledgeItem(
            id: item.id,
            title: item.title,
            content: item.content,
            type: item.type,
            category: item.category,
            tags: item.tags,
            metadata: item.metadata,
            createdAt: item.createdAt,
            updatedAt: Date(),
            fileSize: item.fileSize,
            url: item.url,
            embedding: item.embedding,
            isStarred: item.isStarred,
            isArchived: item.isArchived
        )
        
        // Update vector database
        try await vectorDB.removeDocument(withId: id)
        
        let vectorDocument = VectorDatabase.Document(
            id: id,
            title: item.title,
            content: item.content,
            type: convertToVectorDocumentType(item.type),
            tags: item.tags,
            metadata: item.metadata
        )
        
        try await vectorDB.addDocument(vectorDocument)
        
        // Update local storage
        knowledgeItems[index] = item
        await saveKnowledgeItem(item)
    }
    
    public func removeKnowledgeItem(id: String) async throws {
        guard isInitialized else { throw KnowledgeError.notInitialized }
        
        // Remove from vector database
        try await vectorDB.removeDocument(withId: id)
        
        // Remove from collections
        for i in collections.indices {
            collections[i].items.removeAll { $0 == id }
        }
        
        // Remove from local storage
        knowledgeItems.removeAll { $0.id == id }
        await removeKnowledgeItemFromStorage(id)
    }
    
    public func getKnowledgeItem(id: String) -> KnowledgeItem? {
        return knowledgeItems.first { $0.id == id }
    }
    
    public func getAllKnowledgeItems() -> [KnowledgeItem] {
        return knowledgeItems.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    public func getKnowledgeItems(by category: KnowledgeCategory) -> [KnowledgeItem] {
        return knowledgeItems.filter { $0.category == category }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
    
    public func getKnowledgeItems(by type: KnowledgeType) -> [KnowledgeItem] {
        return knowledgeItems.filter { $0.type == type }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
    
    public func getStarredKnowledgeItems() -> [KnowledgeItem] {
        return knowledgeItems.filter { $0.isStarred }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
    
    public func getArchivedKnowledgeItems() -> [KnowledgeItem] {
        return knowledgeItems.filter { $0.isArchived }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
    
    public func getRecentKnowledgeItems(limit: Int = 10) -> [KnowledgeItem] {
        let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        return knowledgeItems.filter { $0.updatedAt > oneWeekAgo }
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Collection Management
    
    public func createCollection(
        name: String,
        description: String? = nil,
        category: KnowledgeCategory? = nil,
        tags: [String] = [],
        isPublic: Bool = false
    ) async throws -> String {
        guard isInitialized else { throw KnowledgeError.notInitialized }
        
        let id = UUID().uuidString
        let collection = KnowledgeCollection(
            id: id,
            name: name,
            description: description,
            category: category,
            tags: tags,
            isPublic: isPublic
        )
        
        collections.append(collection)
        await saveCollection(collection)
        
        return id
    }
    
    public func updateCollection(
        id: String,
        name: String? = nil,
        description: String? = nil,
        category: KnowledgeCategory? = nil,
        tags: [String]? = nil,
        isPublic: Bool? = nil
    ) async throws {
        guard isInitialized else { throw KnowledgeError.notInitialized }
        
        guard let index = collections.firstIndex(where: { $0.id == id }) else {
            throw KnowledgeError.collectionNotFound
        }
        
        var collection = collections[index]
        
        if let name = name { collection.name = name }
        if let description = description { collection.description = description }
        if let category = category { collection.category = category }
        if let tags = tags { collection.tags = tags }
        if let isPublic = isPublic { collection.isPublic = isPublic }
        
        collection = KnowledgeCollection(
            id: id,
            name: collection.name,
            description: collection.description,
            items: collection.items,
            category: collection.category,
            tags: collection.tags,
            createdAt: collection.createdAt,
            updatedAt: Date(),
            isPublic: collection.isPublic
        )
        
        collections[index] = collection
        await saveCollection(collection)
    }
    
    public func removeCollection(id: String) async throws {
        guard isInitialized else { throw KnowledgeError.notInitialized }
        
        collections.removeAll { $0.id == id }
        await removeCollectionFromStorage(id)
    }
    
    public func addItemToCollection(itemId: String, collectionId: String) async throws {
        guard isInitialized else { throw KnowledgeError.notInitialized }
        
        guard let collectionIndex = collections.firstIndex(where: { $0.id == collectionId }) else {
            throw KnowledgeError.collectionNotFound
        }
        
        guard knowledgeItems.contains(where: { $0.id == itemId }) else {
            throw KnowledgeError.itemNotFound
        }
        
        var collection = collections[collectionIndex]
        
        if !collection.items.contains(itemId) {
            collection.items.append(itemId)
            
            collection = KnowledgeCollection(
                id: collectionId,
                name: collection.name,
                description: collection.description,
                items: collection.items,
                category: collection.category,
                tags: collection.tags,
                createdAt: collection.createdAt,
                updatedAt: Date(),
                isPublic: collection.isPublic
            )
            
            collections[collectionIndex] = collection
            await saveCollection(collection)
        }
    }
    
    public func removeItemFromCollection(itemId: String, collectionId: String) async throws {
        guard isInitialized else { throw KnowledgeError.notInitialized }
        
        guard let collectionIndex = collections.firstIndex(where: { $0.id == collectionId }) else {
            throw KnowledgeError.collectionNotFound
        }
        
        var collection = collections[collectionIndex]
        collection.items.removeAll { $0 == itemId }
        
        collection = KnowledgeCollection(
            id: collectionId,
            name: collection.name,
            description: collection.description,
            items: collection.items,
            category: collection.category,
            tags: collection.tags,
            createdAt: collection.createdAt,
            updatedAt: Date(),
            isPublic: collection.isPublic
        )
        
        collections[collectionIndex] = collection
        await saveCollection(collection)
    }
    
    public func getAllCollections() -> [KnowledgeCollection] {
        return collections.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    public func getCollection(id: String) -> KnowledgeCollection? {
        return collections.first { $0.id == id }
    }
    
    public func getItemsInCollection(id: String) -> [KnowledgeItem] {
        guard let collection = collections.first(where: { $0.id == id }) else {
            return []
        }
        
        return collection.items.compactMap { itemId in
            knowledgeItems.first { $0.id == itemId }
        }.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    // MARK: - Search
    
    public func searchKnowledge(
        query: String,
        category: KnowledgeCategory? = nil,
        type: KnowledgeType? = nil,
        tags: [String]? = nil,
        limit: Int = 20
    ) async throws -> [SearchResult] {
        guard isInitialized else { throw KnowledgeError.notInitialized }
        
        // First, search using vector database
        let vectorResults = try await vectorDB.search(query: query, limit: limit)
        
        // Convert to our search results
        var results: [SearchResult] = []
        
        for vectorResult in vectorResults {
            if let item = knowledgeItems.first(where: { $0.id == vectorResult.document.id }) {
                // Apply filters
                if let category = category, item.category != category { continue }
                if let type = type, item.type != type { continue }
                if let tags = tags, !tags.contains(where: { item.tags.contains($0) }) { continue }
                
                let categoryMatch = category == nil || item.category == category
                let tagMatch = tags == nil || tags.contains(where: { item.tags.contains($0) })
                
                let result = SearchResult(
                    item: item,
                    score: vectorResult.score,
                    snippet: vectorResult.snippet,
                    matchedTerms: vectorResult.matchedTerms,
                    categoryMatch: categoryMatch,
                    tagMatch: tagMatch
                )
                
                results.append(result)
            }
        }
        
        return results.sorted { $0.score > $1.score }
    }
    
    public func searchByTags(_ tags: [String], limit: Int = 20) -> [KnowledgeItem] {
        return knowledgeItems.filter { item in
            tags.contains { item.tags.contains($0) }
        }.sorted { $0.updatedAt > $1.updatedAt }
        .prefix(limit)
        .map { $0 }
    }
    
    // MARK: - Statistics
    
    public func getKnowledgeStats() async -> KnowledgeStats {
        guard isInitialized else { return KnowledgeStats(totalItems: 0, itemsByCategory: [:], itemsByType: [:], totalSize: 0, starredItems: 0, archivedItems: 0, recentItems: 0, tags: [:]) }
        
        let totalItems = knowledgeItems.count
        
        let itemsByCategory = Dictionary(grouping: knowledgeItems, by: { $0.category })
            .mapValues { $0.count }
        
        let itemsByType = Dictionary(grouping: knowledgeItems, by: { $0.type })
            .mapValues { $0.count }
        
        let totalSize = knowledgeItems.reduce(0) { $0 + ($1.fileSize ?? 0) }
        
        let starredItems = knowledgeItems.filter { $0.isStarred }.count
        let archivedItems = knowledgeItems.filter { $0.isArchived }.count
        
        let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        let recentItems = knowledgeItems.filter { $0.updatedAt > oneWeekAgo }.count
        
        let allTags = knowledgeItems.flatMap { $0.tags }
        let tags = Dictionary(grouping: allTags, by: { $0 })
            .mapValues { $0.count }
        
        return KnowledgeStats(
            totalItems: totalItems,
            itemsByCategory: itemsByCategory,
            itemsByType: itemsByType,
            totalSize: totalSize,
            starredItems: starredItems,
            archivedItems: archivedItems,
            recentItems: recentItems,
            tags: tags
        )
    }
    
    // MARK: - File Processing
    
    public func processFile(_ url: URL) async throws -> String {
        guard isInitialized else { throw KnowledgeError.notInitialized }
        
        let fileExtension = url.pathExtension.lowercased()
        
        // Determine file type
        let type: KnowledgeType
        if KnowledgeType.markdown.fileExtensions.contains(fileExtension) {
            type = .markdown
        } else if KnowledgeType.code.fileExtensions.contains(fileExtension) {
            type = .code
        } else if KnowledgeType.text.fileExtensions.contains(fileExtension) {
            type = .text
        } else {
            type = .text // Default
        }
        
        // Read file content
        let content = try String(contentsOf: url)
        let title = url.deletingPathExtension().lastPathComponent
        
        // Determine category based on content or location
        let category = determineCategory(from: content, url: url)
        
        return try await addKnowledgeItem(
            title: title,
            content: content,
            type: type,
            category: category,
            metadata: ["source_url": url.absoluteString, "file_extension": fileExtension]
        )
    }
    
    public func processWebpage(_ url: URL) async throws -> String {
        guard isInitialized else { throw KnowledgeError.notInitialized }
        
        // In a real implementation, this would download and parse the webpage
        let title = "Webpage: \(url.absoluteString)"
        let content = "Content from webpage: \(url.absoluteString)"
        
        return try await addKnowledgeItem(
            title: title,
            content: content,
            type: .webpage,
            category: .bookmarks,
            tags: ["webpage", "bookmark"],
            url: url
        )
    }
    
    // MARK: - Private Methods
    
    private func loadKnowledgeItems() async {
        // In production, this would load from Core Data or file storage
        print("Loading knowledge items...")
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
    
    private func saveKnowledgeItem(_ item: KnowledgeItem) async {
        // In production, this would save to Core Data or file storage
        print("Saving knowledge item: \(item.title)")
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
    
    private func removeKnowledgeItemFromStorage(_ id: String) async {
        // In production, this would remove from Core Data or file storage
        print("Removing knowledge item: \(id)")
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
    
    private func loadCollections() async {
        // In production, this would load from Core Data or file storage
        print("Loading collections...")
        try? await Task.sleep(nanoseconds: 300_000_000)
    }
    
    private func saveCollection(_ collection: KnowledgeCollection) async {
        // In production, this would save to Core Data or file storage
        print("Saving collection: \(collection.name)")
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
    
    private func removeCollectionFromStorage(_ id: String) async {
        // In production, this would remove from Core Data or file storage
        print("Removing collection: \(id)")
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
    
    private func generateEmbedding(for text: String) async -> [Float]? {
        // In production, this would use MLX to generate actual embeddings
        return nil
    }
    
    private func calculateFileSize(content: String, type: KnowledgeType) async -> Int64 {
        // Calculate approximate file size
        let contentSize = Int64(content.utf8.count)
        
        switch type {
        case .text, .markdown, .note:
            return contentSize
        case .code:
            return contentSize * 2 // Code files might be larger when saved
        case .pdf:
            return contentSize * 10 // PDF files are typically larger
        case .webpage:
            return contentSize * 3 // Webpage content with HTML
        default:
            return contentSize
        }
    }
    
    private func determineCategory(from content: String, url: URL) -> KnowledgeCategory {
        // Simple category determination based on content and URL
        let contentLower = content.lowercased()
        let urlString = url.absoluteString.lowercased()
        
        if urlString.contains("github.com") || contentLower.contains("function") || contentLower.contains("class") {
            return .code
        } else if urlString.contains("documentation") || contentLower.contains("api") {
            return .documentation
        } else if urlString.contains("research") || contentLower.contains("study") {
            return .research
        } else if urlString.contains("work") || contentLower.contains("project") {
            return .work
        } else if urlString.contains("personal") {
            return .personal
        } else {
            return .notes
        }
    }
    
    private func convertToVectorDocumentType(_ type: KnowledgeType) -> VectorDatabase.DocumentType {
        switch type {
        case .text: return .text
        case .markdown: return .markdown
        case .code: return .code
        case .pdf: return .pdf
        case .webpage: return .webpage
        default: return .text
        }
    }
    
    // MARK: - Error Types
    
    public enum KnowledgeError: Error, LocalizedError {
        case notInitialized
        case itemNotFound
        case collectionNotFound
        case invalidFileType
        case processingFailed
        case searchFailed
        
        public var errorDescription: String? {
            switch self {
            case .notInitialized:
                return "Knowledge base is not initialized"
            case .itemNotFound:
                return "Knowledge item not found"
            case .collectionNotFound:
                return "Collection not found"
            case .invalidFileType:
                return "Invalid file type"
            case .processingFailed:
                return "Failed to process file"
            case .searchFailed:
                return "Search failed"
            }
        }
    }
}