import Foundation
import Alamofire
import SwiftyJSON

public class TranslationService {
    public static let shared = TranslationService()
    
    private init() {}
    
    private let googleTranslateAPI = "https://translation.googleapis.com/language/translate/v2"
    private let apiKey = "YOUR_API_KEY" // Replace with actual API key
    private let mlxService = MLXService.shared
    private let historyManager = TranslationHistoryManager.shared
    private let qualityOptimizer = TranslationQualityOptimizer.shared
    private let habitService = UserHabitIntegrationService.shared
    
    // Translation mode
    public enum TranslationMode: String {
        case online = "online"
        case local = "local"
        case hybrid = "hybrid" // Try local first, fallback to online
    }
    
    private var currentMode: TranslationMode = .hybrid
    
    public func setTranslationMode(_ mode: TranslationMode) {
        self.currentMode = mode
    }
    
    public func getTranslationMode() -> TranslationMode {
        return currentMode
    }
    
    public func translate(text: String, source: String = "auto", target: String = "zh", enableOptimization: Bool = true) async -> String {
        // Check user preferences for auto-translation
        var finalSource = source
        var finalTarget = target
        
        if let preferredLanguages = habitService.getPreferredTranslationLanguages() {
            if source == "auto" {
                finalSource = preferredLanguages.source
            }
            finalTarget = preferredLanguages.target
        }
        
        let result: String
        
        switch currentMode {
        case .online:
            result = await performOnlineTranslation(text: text, source: finalSource, target: finalTarget)
        case .local:
            result = await performLocalTranslation(text: text, source: finalSource, target: finalTarget)
        case .hybrid:
            // Try local first, fallback to online
            let localResult = await performLocalTranslation(text: text, source: finalSource, target: finalTarget)
            if localResult.contains("[MLX翻译]") {
                // Local translation failed or is mock, try online
                result = await performOnlineTranslation(text: text, source: finalSource, target: finalTarget)
            } else {
                result = localResult
            }
        }
        
        // Apply quality optimization if enabled
        let finalResult: String
        if enableOptimization && shouldOptimizeTranslation(text: text, result: result) {
            finalResult = await optimizeTranslationQuality(
                originalText: text,
                translatedText: result,
                sourceLanguage: finalSource,
                targetLanguage: finalTarget
            )
        } else {
            finalResult = result
        }
        
        // Add to history
        await addToHistory(text: text, translation: finalResult, source: finalSource, target: finalTarget)
        
        // Record user habit for learning
        let confidence = calculateTranslationConfidence(text: text, result: finalResult, mode: currentMode)
        habitService.recordTranslationInteraction(
            sourceText: text,
            targetText: finalResult,
            sourceLanguage: finalSource,
            targetLanguage: finalTarget,
            confidence: confidence
        )
        
        return finalResult
    }
    
    private func performOnlineTranslation(text: String, source: String, target: String) async -> String {
        // Mock translation for development
        if text.isEmpty {
            return ""
        }
        
        // Simple mock translation logic
        let mockTranslations: [String: String] = [
            "Hello": "你好",
            "World": "世界",
            "Good morning": "早上好",
            "Thank you": "谢谢",
            "Goodbye": "再见",
            "How are you": "你好吗",
            "Nice to meet you": "很高兴认识你",
            "I love you": "我爱你",
            "What is your name": "你叫什么名字",
            "Where are you from": "你从哪里来"
        ]
        
        if let translation = mockTranslations[text] {
            return translation
        }
        
        // If no exact match, use simple character mapping
        return await mockTranslate(text: text)
    }
    
    private func performLocalTranslation(text: String, source: String, target: String) async -> String {
        do {
            // Try to use MLX local translation
            let translatedText = try await mlxService.translate(text: text, from: source, to: target)
            return translatedText
        } catch {
            // Fallback to simple mock translation
            print("Local translation failed: \(error)")
            return await mockLocalTranslate(text: text, target: target)
        }
    }
    
    private func mockTranslate(text: String) async -> String {
        // This is a very basic mock translation
        // In a real implementation, you would call a translation API
        return "[翻译: \(text)]"
    }
    
    private func mockLocalTranslate(text: String, target: String) async -> String {
        // This is a placeholder for MLX-based translation
        return "[本地翻译: \(text) -> \(target)]"
    }
    
    // MARK: - MLX Model Management
    
    public func loadMLXModel() async throws {
        try await mlxService.loadTranslationModel(.small)
    }
    
    public func unloadMLXModel() {
        mlxService.unloadModel()
    }
    
    public func getMLXModelInfo() -> MLXModelInfo {
        return mlxService.getModelInfo()
    }
    
    public func optimizeMLXModel() async {
        await mlxService.optimizeForDevice()
    }
    
    public func getMLXPerformanceMetrics() -> MLXPerformanceMetrics {
        return mlxService.getPerformanceMetrics()
    }
    
    // MARK: - Language Detection Enhancement
    
    public func detectLanguage(text: String) async -> String {
        // Enhanced language detection
        if text.isEmpty {
            return "auto"
        }
        
        // Check for Chinese characters
        if text.contains(where: { "\u{4E00}"..."\u{9FFF}" ~= $0 }) {
            return "zh"
        }
        
        // Check for Japanese characters
        if text.contains(where: { "\u{3040}"..."\u{309F}" ~= $0 || "\u{30A0}"..."\u{30FF}" ~= $0 }) {
            return "ja"
        }
        
        // Check for Korean characters
        if text.contains(where: { "\u{AC00}"..."\u{D7AF}" ~= $0 }) {
            return "ko"
        }
        
        // Check for common English words
        let englishWords = ["the", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "is", "are", "was", "were", "be", "been", "being", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should", "may", "might", "must", "can", "this", "that", "these", "those"]
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let englishWordCount = words.filter { englishWords.contains($0) }.count
        
        if englishWordCount > 0 && englishWordCount > Int(Double(words.count) * 0.1) {
            return "en"
        }
        
        return "auto"
    }
    
    public func getSupportedLanguages() async -> [String] {
        return [
            "auto", "zh", "en", "ja", "ko", "fr", "de", "es", "ru", "pt", "it"
        ]
    }
    
    // MARK: - History Management
    
    public func getTranslationHistory(limit: Int = 50) -> [TranslationHistoryManager.TranslationRecord] {
        return historyManager.getTranslationHistory(limit: limit)
    }
    
    public func searchTranslationHistory(query: String, limit: Int = 20) -> [TranslationHistoryManager.TranslationRecord] {
        return historyManager.searchHistory(query: query, limit: limit)
    }
    
    public func clearTranslationHistory() {
        historyManager.clearAllHistory()
    }
    
    public func getTranslationStatistics() -> HistoryStatistics {
        return historyManager.getHistoryStatistics()
    }
    
    public func deleteTranslationRecord(withId id: String) {
        historyManager.deleteTranslationRecord(withId: id)
    }
    
    // MARK: - Quality Optimization Methods
    
    public func optimizeTranslationQuality(
        originalText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String,
        context: String? = nil,
        strategy: TranslationQualityOptimizer.OptimizationStrategy = .balanced
    ) async -> String {
        let optimizationResult = await qualityOptimizer.optimizeTranslation(
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            context: context,
            strategy: strategy
        )
        
        return optimizationResult.optimizedTranslation
    }
    
    public func getTranslationQualityAnalysis(
        originalText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String,
        context: String? = nil
    ) async -> TranslationQualityOptimizer.QualityMetrics {
        return await qualityOptimizer.analyzeTranslationQuality(
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            context: context
        )
    }
    
    public func getTranslationSuggestions(
        originalText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String,
        context: String? = nil
    ) async -> [TranslationQualityOptimizer.TranslationSuggestion] {
        let qualityMetrics = await qualityOptimizer.analyzeTranslationQuality(
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            context: context
        )
        
        return await qualityOptimizer.generateImprovementSuggestions(
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            context: context,
            qualityMetrics: qualityMetrics
        )
    }
    
    private func shouldOptimizeTranslation(text: String, result: String) -> Bool {
        // Don't optimize very short texts or mock translations
        guard text.count > 3 && !result.contains("[") && !result.contains("]") else {
            return false
        }
        
        // Check user preferences for optimization
        let preferences = habitService.getLearnedPreferences()
        if let optimizationEnabled = preferences.optimizationEnabled {
            return optimizationEnabled
        }
        
        // Default to true for longer texts
        return text.count > 10
    }
    
    // MARK: - Private Methods
    
    private func calculateTranslationConfidence(text: String, result: String, mode: TranslationMode) -> Double {
        var confidence = 0.5
        
        // Base confidence based on translation mode
        switch mode {
        case .online:
            confidence = 0.8
        case .local:
            confidence = 0.7
        case .hybrid:
            confidence = 0.75
        }
        
        // Adjust based on text length
        if text.count > 10 {
            confidence += 0.1
        }
        
        // Adjust based on result quality
        if !result.contains("[") && !result.contains("]") {
            confidence += 0.1
        }
        
        return min(confidence, 1.0)
    }
    
    private func addToHistory(text: String, translation: String, source: String, target: String) async {
        // Skip empty or very short translations
        guard text.count > 1 && !translation.isEmpty else { return }
        
        // Skip mock translations
        guard !translation.contains("[") && !translation.contains("]") else { return }
        
        await MainActor.run {
            historyManager.addTranslationRecord(
                originalText: text,
                translatedText: translation,
                sourceLanguage: source,
                targetLanguage: target,
                translationMode: currentMode.rawValue,
                confidence: nil,
                context: nil
            )
        }
    }
}

// MARK: - Online Translation Service
public class OnlineTranslator {
    private let apiKey: String
    private let session: Session
    
    public init(apiKey: String) {
        self.apiKey = apiKey
        self.session = Session.default
    }
    
    public func translate(
        text: String,
        from source: String = "auto",
        to target: String = "zh"
    ) async throws -> String {
        let parameters: [String: Any] = [
            "q": text,
            "source": source,
            "target": target,
            "format": "text",
            "key": apiKey
        ]
        
        let response: DataResponse<TranslationResponse, AFError> = await session.request(
            "https://translation.googleapis.com/language/translate/v2",
            method: .post,
            parameters: parameters,
            encoding: URLEncoding.default,
            headers: [:]
        ).serializingDecodable(TranslationResponse.self).response
        
        switch response.result {
        case .success(let translationResponse):
            return translationResponse.data.translations.first?.translatedText ?? text
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - Translation Response Models
struct TranslationResponse: Decodable {
    let data: TranslationData
}

struct TranslationData: Decodable {
    let translations: [Translation]
}

struct Translation: Decodable {
    let translatedText: String
    let detectedSourceLanguage: String?
}

// MARK: - Local Translation Service
public class LocalTranslator {
    private let model: LocalTranslationModel
    
    public init() {
        self.model = LocalTranslationModel()
    }
    
    public func translate(text: String, to target: String) async -> String {
        return await model.translate(text: text, target: target)
    }
    
    public func isModelDownloaded(for language: String) -> Bool {
        return model.isModelAvailable(for: language)
    }
    
    public func downloadModel(for language: String) async throws {
        try await model.downloadModel(for: language)
    }
}

// MARK: - Translation Model
class LocalTranslationModel {
    private var loadedModels: [String: Any] = [:]
    
    func translate(text: String, target: String) async -> String {
        // Mock local translation
        // In production, this would use MLX for local inference
        return await mockLocalTranslate(text: text, target: target)
    }
    
    private func mockLocalTranslate(text: String, target: String) async -> String {
        // This is a placeholder for MLX-based translation
        return "[本地翻译: \(text) -> \(target)]"
    }
    
    func isModelAvailable(for language: String) -> Bool {
        return loadedModels[language] != nil
    }
    
    func downloadModel(for language: String) async throws {
        // Mock model download
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        loadedModels[language] = "model_\(language)"
    }
}