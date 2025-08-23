import Foundation
import MLX

public class VectorDatabase {
    public static let shared = VectorDatabase()
    
    private init() {}
    
    // MARK: - Vector Database Core
    
    private var documents: [Document] = []
    private var embeddings: [String: [Float]] = [:]
    private var isInitialized = false
    
    public struct Document {
        public let id: String
        public let title: String
        public let content: String
        public let type: DocumentType
        public let createdAt: Date
        public let tags: [String]
        public let metadata: [String: String]
        
        public init(id: String, title: String, content: String, type: DocumentType, tags: [String] = [], metadata: [String: String] = [:]) {
            self.id = id
            self.title = title
            self.content = content
            self.type = type
            self.createdAt = Date()
            self.tags = tags
            self.metadata = metadata
        }
    }
    
    public enum DocumentType {
        case text
        case pdf
        case docx
        case markdown
        case webpage
        case note
        case code
    }
    
    public struct SearchResult {
        public let document: Document
        public let score: Double
        public let snippet: String
        public let matchedTerms: [String]
    }
    
    // MARK: - Database Operations
    
    public func initialize() async {
        guard !isInitialized else { return }
        
        // Load existing documents from storage
        await loadDocumentsFromStorage()
        
        // Initialize MLX embedding model
        await initializeEmbeddingModel()
        
        isInitialized = true
        print("Vector database initialized")
    }
    
    public func addDocument(_ document: Document) async throws {
        guard isInitialized else {
            throw DatabaseError.notInitialized
        }
        
        // Generate embedding for the document
        let embedding = await generateEmbedding(for: document.content)
        embeddings[document.id] = embedding
        
        // Add to documents array
        documents.append(document)
        
        // Save to storage
        await saveDocumentToStorage(document)
        
        print("Document added: \(document.title)")
    }
    
    public func removeDocument(withId id: String) async throws {
        guard isInitialized else {
            throw DatabaseError.notInitialized
        }
        
        // Remove from documents array
        documents.removeAll { $0.id == id }
        
        // Remove embedding
        embeddings.removeValue(forKey: id)
        
        // Remove from storage
        await removeDocumentFromStorage(withId: id)
        
        print("Document removed: \(id)")
    }
    
    public func search(query: String, limit: Int = 10) async throws -> [SearchResult] {
        guard isInitialized else {
            throw DatabaseError.notInitialized
        }
        
        // Generate query embedding
        let queryEmbedding = await generateEmbedding(for: query)
        
        // Calculate similarity scores
        var results: [SearchResult] = []
        
        for document in documents {
            if let docEmbedding = embeddings[document.id] {
                let similarity = cosineSimilarity(queryEmbedding, docEmbedding)
                
                if similarity > 0.3 { // Threshold for relevance
                    let snippet = generateSnippet(document.content, query: query)
                    let matchedTerms = extractMatchedTerms(document.content, query: query)
                    
                    let result = SearchResult(
                        document: document,
                        score: similarity,
                        snippet: snippet,
                        matchedTerms: matchedTerms
                    )
                    
                    results.append(result)
                }
            }
        }
        
        // Sort by score and limit results
        return results.sorted { $0.score > $1.score }.prefix(limit).map { $0 }
    }
    
    public func getAllDocuments() -> [Document] {
        return documents
    }
    
    public func getDocumentCount() -> Int {
        return documents.count
    }
    
    // MARK: - Private Methods
    
    private func loadDocumentsFromStorage() async {
        // In production, this would load from Core Data or file storage
        print("Loading documents from storage...")
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
    
    private func saveDocumentToStorage(_ document: Document) async {
        // In production, this would save to Core Data or file storage
        print("Saving document to storage: \(document.title)")
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
    
    private func removeDocumentFromStorage(withId id: String) async {
        // In production, this would remove from Core Data or file storage
        print("Removing document from storage: \(id)")
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
    
    private func initializeEmbeddingModel() async {
        // Initialize MLX embedding model
        print("Initializing embedding model...")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        print("Embedding model initialized")
    }
    
    private func generateEmbedding(for text: String) async -> [Float] {
        // In production, this would use MLX to generate actual embeddings
        // For now, return a mock embedding vector
        
        let dimension = 384 // Standard embedding dimension
        var embedding: [Float] = []
        
        // Simple hash-based mock embedding
        for i in 0..<dimension {
            let hash = text.hashValue
            let value = Float(hash % 1000) / 1000.0
            embedding.append(value)
        }
        
        // Normalize the vector
        let magnitude = sqrt(embedding.reduce(0) { $0 + $1 * $1 })
        if magnitude > 0 {
            embedding = embedding.map { $0 / Float(magnitude) }
        }
        
        return embedding
    }
    
    private func cosineSimilarity(_ vec1: [Float], _ vec2: [Float]) -> Double {
        guard vec1.count == vec2.count else { return 0.0 }
        
        var dotProduct: Float = 0
        var mag1: Float = 0
        var mag2: Float = 0
        
        for i in 0..<vec1.count {
            dotProduct += vec1[i] * vec2[i]
            mag1 += vec1[i] * vec1[i]
            mag2 += vec2[i] * vec2[i]
        }
        
        guard mag1 > 0 && mag2 > 0 else { return 0.0 }
        
        return Double(dotProduct / (sqrt(mag1) * sqrt(mag2)))
    }
    
    private func generateSnippet(_ content: String, query: String) -> String {
        let words = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let contentLower = content.lowercased()
        
        // Find the first occurrence of any query word
        for word in words {
            if let range = contentLower.range(of: word) {
                let startIndex = max(0, content.distance(from: content.startIndex, to: range.lowerBound) - 50)
                let endIndex = min(content.count, content.distance(from: content.startIndex, to: range.upperBound) + 50)
                
                let snippetStartIndex = content.index(content.startIndex, offsetBy: startIndex)
                let snippetEndIndex = content.index(content.startIndex, offsetBy: endIndex)
                
                return String(content[snippetStartIndex..<snippetEndIndex])
            }
        }
        
        // If no match found, return first 100 characters
        return String(content.prefix(100))
    }
    
    private func extractMatchedTerms(_ content: String, query: String) -> [String] {
        let queryWords = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let contentWords = content.lowercased().components(separatedBy: .whitespacesAndNewlines)
        
        return queryWords.filter { contentWords.contains($0) }
    }
    
    // MARK: - Error Types
    
    public enum DatabaseError: Error, LocalizedError {
        case notInitialized
        case documentNotFound
        case embeddingFailed
        case searchFailed
        
        public var errorDescription: String? {
            switch self {
            case .notInitialized:
                return "Vector database is not initialized"
            case .documentNotFound:
                return "Document not found"
            case .embeddingFailed:
                return "Failed to generate embedding"
            case .searchFailed:
                return "Search failed"
            }
        }
    }
}

// MARK: - Knowledge Manager

public class KnowledgeManager {
    public static let shared = KnowledgeManager()
    
    private let vectorDB = VectorDatabase.shared
    
    private init() {}
    
    public func initialize() async {
        await vectorDB.initialize()
    }
    
    public func addDocument(title: String, content: String, type: VectorDatabase.DocumentType, tags: [String] = []) async throws -> String {
        let id = UUID().uuidString
        let document = VectorDatabase.Document(
            id: id,
            title: title,
            content: content,
            type: type,
            tags: tags
        )
        
        try await vectorDB.addDocument(document)
        return id
    }
    
    public func searchKnowledge(query: String, limit: Int = 10) async throws -> [VectorDatabase.SearchResult] {
        return try await vectorDB.search(query: query, limit: limit)
    }
    
    public func getAllDocuments() -> [VectorDatabase.Document] {
        return vectorDB.getAllDocuments()
    }
    
    public func removeDocument(withId id: String) async throws {
        try await vectorDB.removeDocument(withId: id)
    }
    
    public func getDocumentCount() -> Int {
        return vectorDB.getDocumentCount()
    }
    
    // MARK: - Document Processing
    
    public func processTextFile(_ url: URL) async throws -> String {
        let content = try String(contentsOf: url)
        let title = url.deletingPathExtension().lastPathComponent
        
        return try await addDocument(title: title, content: content, type: .text)
    }
    
    public func processMarkdownFile(_ url: URL) async throws -> String {
        let content = try String(contentsOf: url)
        let title = url.deletingPathExtension().lastPathComponent
        
        return try await addDocument(title: title, content: content, type: .markdown)
    }
    
    public func addNote(_ title: String, content: String, tags: [String] = []) async throws -> String {
        return try await addDocument(title: title, content: content, type: .note, tags: tags)
    }
    
    public func addCodeSnippet(_ title: String, code: String, language: String, tags: [String] = []) async throws -> String {
        let metadata = ["language": language]
        let document = VectorDatabase.Document(
            id: UUID().uuidString,
            title: title,
            content: code,
            type: .code,
            tags: tags,
            metadata: metadata
        )
        
        try await vectorDB.addDocument(document)
        return document.id
    }
}