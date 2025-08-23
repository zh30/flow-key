import Foundation
import MLX

// MARK: - Type Aliases

public enum DocumentType: String, CaseIterable, Codable {
    case text = "text"
    case pdf = "pdf"
    case word = "word"
    case markdown = "markdown"
    case html = "html"
    case custom = "custom"
}

public struct SpeechSegment: Codable {
    public let text: String
    public let startTime: Double
    public let endTime: Double
    public let confidence: Double
    
    public init(text: String, startTime: Double, endTime: Double, confidence: Double) {
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
        self.confidence = confidence
    }
}

public struct PerformanceMetrics: Codable {
    public let translationTime: Double
    public let accuracy: Double
    public let memoryUsage: Double
    public let cpuUsage: Double
    
    public init(translationTime: Double, accuracy: Double, memoryUsage: Double, cpuUsage: Double) {
        self.translationTime = translationTime
        self.accuracy = accuracy
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
    }
}

public class AIService {
    public static let shared = AIService()
    
    private init() {}
    
    // MARK: - Service Components
    private let mlxService = MLXService.shared
    private let speechRecognizer = SpeechRecognizer.shared
    private let knowledgeManager = KnowledgeManager.shared
    private let documentProcessor = DocumentProcessor.shared
    
    // MARK: - Initialization
    
    public func initialize() async throws {
        // Initialize all AI services
        async let mlxInit = Task {
            try? await mlxService.loadTranslationModel(.small)
        }
        
        async let speechInit = Task {
            try? await speechRecognizer.loadSpeechModel(.base)
        }
        
        async let knowledgeInit = Task {
            await knowledgeManager.initialize()
        }
        
        // Wait for all services to initialize
        _ = await [mlxInit.value, speechInit.value, knowledgeInit.value]
        
        print("AI services initialized successfully")
    }
    
    // MARK: - Translation Services
    
    public func translateText(_ text: String, 
                              from sourceLanguage: String = "auto",
                              to targetLanguage: String = "zh",
                              mode: TranslationService.TranslationMode = .hybrid) async throws -> String {
        
        switch mode {
        case .online:
            return try await performOnlineTranslation(text: text, source: sourceLanguage, target: targetLanguage)
        case .local:
            return try await performLocalTranslation(text: text, source: sourceLanguage, target: targetLanguage)
        case .hybrid:
            do {
                return try await performLocalTranslation(text: text, source: sourceLanguage, target: targetLanguage)
            } catch {
                print("Local translation failed, falling back to online: \(error)")
                return try await performOnlineTranslation(text: text, source: sourceLanguage, target: targetLanguage)
            }
        }
    }
    
    private func performLocalTranslation(text: String, source: String, target: String) async throws -> String {
        let translatedText = try await mlxService.translate(text: text, from: source, to: target)
        return translatedText
    }
    
    private func performOnlineTranslation(text: String, source: String, target: String) async throws -> String {
        // In production, this would call a real translation API
        return await mockOnlineTranslation(text: text, source: source, target: target)
    }
    
    private func mockOnlineTranslation(text: String, source: String, target: String) async -> String {
        // Mock online translation
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let translations: [String: String] = [
            "Hello": "你好",
            "World": "世界",
            "Thank you": "谢谢",
            "Good morning": "早上好",
            "Good evening": "晚上好",
            "How are you": "你好吗",
            "Nice to meet you": "很高兴认识你"
        ]
        
        return translations[text] ?? "[在线翻译] \(text)"
    }
    
    // MARK: - Speech Recognition Services
    
    public func startSpeechRecognition() async throws -> SpeechSession {
        let hasPermission = await speechRecognizer.requestPermission()
        guard hasPermission else {
            throw AIServiceError.permissionDenied
        }
        
        let recordingSession = try await speechRecognizer.startRecording()
        
        return SpeechSession(
            id: recordingSession.id,
            startTime: recordingSession.startTime,
            isRecording: true
        )
    }
    
    public func stopSpeechRecognition() async throws -> SpeechRecognitionResult {
        let segments = try await speechRecognizer.stopRecording()
        
        let fullText = segments.map { $0.text }.joined(separator: " ")
        
        return SpeechRecognitionResult(
            segments: segments,
            fullText: fullText,
            detectedLanguage: segments.first?.language ?? "auto",
            confidence: segments.map { $0.confidence }.reduce(0, +) / Double(segments.count)
        )
    }
    
    public func getRealTimeTranscription(sessionId: String) async -> String? {
        // In production, this would return real-time transcription results
        return nil
    }
    
    // MARK: - Knowledge Base Services
    
    public func addDocumentToKnowledgeBase(title: String, 
                                          content: String, 
                                          type: DocumentType, 
                                          tags: [String] = []) async throws -> String {
        
        let docId = try await knowledgeManager.addDocument(
            title: title,
            content: content,
            type: convertDocumentType(type),
            tags: tags
        )
        
        return docId
    }
    
    public func processDocumentFile(_ fileURL: URL) async throws -> String {
        let processedDoc = try await documentProcessor.processDocument(at: fileURL)
        
        let docId = try await knowledgeManager.addDocument(
            title: processedDoc.title,
            content: processedDoc.content,
            type: convertDocumentType(processedDoc.type),
            tags: extractTagsFromMetadata(processedDoc.metadata)
        )
        
        return docId
    }
    
    public func searchKnowledgeBase(_ query: String, limit: Int = 10) async throws -> [KnowledgeSearchResult] {
        let searchResults = try await knowledgeManager.searchKnowledge(query: query, limit: limit)
        
        return searchResults.map { result in
            KnowledgeSearchResult(
                documentId: result.document.id,
                title: result.document.title,
                content: result.snippet,
                score: result.score,
                type: convertToDocumentType(result.document.type),
                tags: result.document.tags
            )
        }
    }
    
    public func getAllKnowledgeDocuments() -> [KnowledgeDocumentInfo] {
        let documents = knowledgeManager.getAllDocuments()
        
        return documents.map { doc in
            KnowledgeDocumentInfo(
                id: doc.id,
                title: doc.title,
                type: convertToDocumentType(doc.type),
                tags: doc.tags,
                createdAt: doc.createdAt
            )
        }
    }
    
    public func removeKnowledgeDocument(withId id: String) async throws {
        try await knowledgeManager.removeDocument(withId: id)
    }
    
    // MARK: - Smart Text Processing
    
    public func processTextWithAI(_ text: String, options: TextProcessingOptions) async throws -> ProcessedTextResult {
        var result = ProcessedTextResult(originalText: text)
        
        if options.shouldSummarize {
            result.summary = documentProcessor.generateSummary(from: text, maxLength: options.summaryMaxLength)
        }
        
        if options.shouldExtractKeywords {
            result.keywords = documentProcessor.extractKeywords(from: text, limit: options.keywordLimit)
        }
        
        if options.shouldDetectLanguage {
            result.detectedLanguage = await detectLanguage(text: text)
        }
        
        if options.shouldCategorize {
            result.category = await categorizeText(text: text)
        }
        
        if options.shouldImproveWriting {
            result.improvedText = await improveWriting(text: text)
        }
        
        return result
    }
    
    // MARK: - AI Assistant
    
    public func askAIAssistant(_ question: String, 
                              context: String = "",
                              useKnowledgeBase: Bool = true) async throws -> AIAssistantResponse {
        
        var response = ""
        var sources: [AISource] = []
        
        if useKnowledgeBase {
            let knowledgeResults = try await searchKnowledgeBase(question, limit: 5)
            if !knowledgeResults.isEmpty {
                sources = knowledgeResults.map { result in
                    AISource(
                        id: result.documentId,
                        title: result.title,
                        content: result.content,
                        type: .knowledgeBase
                    )
                }
                
                // Generate response based on knowledge base
                response = generateResponseFromKnowledge(question: question, sources: sources)
            }
        }
        
        if response.isEmpty {
            // Fallback to general AI response
            response = await generateGeneralResponse(question: question, context: context)
        }
        
        return AIAssistantResponse(
            response: response,
            sources: sources,
            confidence: calculateConfidence(response: response, sources: sources)
        )
    }
    
    // MARK: - Performance Monitoring
    
    public func getAIServiceMetrics() -> AIServiceMetrics {
        return AIServiceMetrics(
            translationMetrics: mlxService.getPerformanceMetrics(),
            speechMetrics: speechRecognizer.getPerformanceMetrics(),
            knowledgeBaseMetrics: KnowledgeBaseMetrics(
                documentCount: knowledgeManager.getDocumentCount(),
                averageSearchTime: 0.1 // Mock value
            ),
            isInitialized: true
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func convertDocumentType(_ type: DocumentType) -> VectorDatabase.DocumentType {
        switch type {
        case .text: return .text
        case .markdown: return .markdown
        case .pdf: return .pdf
        case .docx: return .text // Map to text for now
        case .rtf: return .text
        case .html: return .text
        case .code: return .text
        }
    }
    
    private func convertToDocumentType(_ type: VectorDatabase.DocumentType) -> DocumentType {
        switch type {
        case .text: return .text
        case .markdown: return .markdown
        case .pdf: return .pdf
        case .docx: return .docx
        case .webpage: return .html
        case .note: return .text
        case .code: return .code
        }
    }
    
    private func extractTagsFromMetadata(_ metadata: [String: String]) -> [String] {
        var tags: [String] = []
        
        if let language = metadata["language"] {
            tags.append("language:\(language)")
        }
        
        if let type = metadata["type"] {
            tags.append("type:\(type)")
        }
        
        return tags
    }
    
    private func detectLanguage(text: String) async -> String {
        // Use translation service's language detection
        return await TranslationService.shared.detectLanguage(text: text)
    }
    
    private func categorizeText(text: String) async -> String {
        // Simple text categorization
        let lowercasedText = text.lowercased()
        
        if lowercasedText.contains("code") || lowercasedText.contains("function") || lowercasedText.contains("class") {
            return "programming"
        } else if lowercasedText.contains("meeting") || lowercasedText.contains("agenda") {
            return "meeting"
        } else if lowercasedText.contains("project") || lowercasedText.contains("task") {
            return "project"
        } else if lowercasedText.contains("personal") || lowercasedText.contains("diary") {
            return "personal"
        } else {
            return "general"
        }
    }
    
    private func improveWriting(text: String) async -> String {
        // Mock AI writing improvement
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return "[优化后的文本] \(text)"
    }
    
    private func generateResponseFromKnowledge(question: String, sources: [AISource]) -> String {
        if sources.isEmpty {
            return "I don't have information about that in my knowledge base."
        }
        
        // Simple response generation based on sources
        return "Based on my knowledge base, here's what I found: \(sources.first?.content ?? "")"
    }
    
    private func generateGeneralResponse(question: String, context: String) async -> String {
        // Mock general AI response
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        return "This is a general AI response to your question: \(question). Context: \(context)"
    }
    
    private func calculateConfidence(response: String, sources: [AISource]) -> Double {
        if sources.isEmpty {
            return 0.5 // Medium confidence for general responses
        } else {
            return 0.8 // High confidence for knowledge-based responses
        }
    }
}

// MARK: - Supporting Structures

public struct SpeechSession {
    public let id: String
    public let startTime: Date
    public let isRecording: Bool
}

public struct SpeechRecognitionResult {
    public let segments: [SpeechSegment]
    public let fullText: String
    public let detectedLanguage: String
    public let confidence: Double
}

public struct KnowledgeSearchResult {
    public let documentId: String
    public let title: String
    public let content: String
    public let score: Double
    public let type: DocumentType
    public let tags: [String]
}

public struct KnowledgeDocumentInfo {
    public let id: String
    public let title: String
    public let type: DocumentType
    public let tags: [String]
    public let createdAt: Date
}

public struct ProcessedTextResult {
    public let originalText: String
    public var summary: String?
    public var keywords: [String]?
    public var detectedLanguage: String?
    public var category: String?
    public var improvedText: String?
}

public struct AIAssistantResponse {
    public let response: String
    public let sources: [AISource]
    public let confidence: Double
}

public struct AISource {
    public let id: String
    public let title: String
    public let content: String
    public let type: SourceType
}

public enum SourceType {
    case knowledgeBase
    case web
    case document
}

public struct AIServiceMetrics {
    public let translationMetrics: MLXPerformanceMetrics
    public let speechMetrics: PerformanceMetrics
    public let knowledgeBaseMetrics: KnowledgeBaseMetrics
    public let isInitialized: Bool
}

public struct KnowledgeBaseMetrics {
    public let documentCount: Int
    public let averageSearchTime: Double
}

public struct TextProcessingOptions {
    public let shouldSummarize: Bool
    public let shouldExtractKeywords: Bool
    public let shouldDetectLanguage: Bool
    public let shouldCategorize: Bool
    public let shouldImproveWriting: Bool
    public let summaryMaxLength: Int
    public let keywordLimit: Int
    
    public init(
        shouldSummarize: Bool = false,
        shouldExtractKeywords: Bool = false,
        shouldDetectLanguage: Bool = false,
        shouldCategorize: Bool = false,
        shouldImproveWriting: Bool = false,
        summaryMaxLength: Int = 200,
        keywordLimit: Int = 20
    ) {
        self.shouldSummarize = shouldSummarize
        self.shouldExtractKeywords = shouldExtractKeywords
        self.shouldDetectLanguage = shouldDetectLanguage
        self.shouldCategorize = shouldCategorize
        self.shouldImproveWriting = shouldImproveWriting
        self.summaryMaxLength = summaryMaxLength
        self.keywordLimit = keywordLimit
    }
}

// MARK: - Error Types

public enum AIServiceError: Error, LocalizedError {
    case permissionDenied
    case serviceNotInitialized
    case modelNotLoaded
    case processingFailed
    case knowledgeBaseEmpty
    
    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Permission denied"
        case .serviceNotInitialized:
            return "AI service not initialized"
        case .modelNotLoaded:
            return "AI model not loaded"
        case .processingFailed:
            return "Processing failed"
        case .knowledgeBaseEmpty:
            return "Knowledge base is empty"
        }
    }
}