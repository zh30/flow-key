import Foundation

@MainActor
public final class ModernTranslationService: ObservableObject {
    public static let shared = ModernTranslationService()
    
    @Published public private(set) var isTranslating = false
    @Published public private(set) var lastTranslationTime: Date?
    @Published public private(set) var translationCount = 0
    @Published public private(set) var lastError: TranslationError?
    
    private let translationCache = NSCache<NSString, NSString>()
    private let maxRetries = 3
    
    private init() {
        translationCache.countLimit = 500
        translationCache.totalCostLimit = 20 * 1024 * 1024
    }
    
    public func translate(text: String, from sourceLanguage: String? = nil, to targetLanguage: String? = nil) async -> String {
        let source = sourceLanguage ?? "auto"
        let target = targetLanguage ?? "en"
        let cacheKey = cacheKeyFor(text: text, source: source, target: target)
        
        if let cached = translationCache.object(forKey: cacheKey) {
            return cached as String
        }
        
        isTranslating = true
        lastError = nil
        
        do {
            let result = try await performTranslationWithRetry(text: text, source: source, target: target)
            isTranslating = false
            lastTranslationTime = Date()
            translationCount += 1
            translationCache.setObject(result as NSString, forKey: cacheKey)
            return result
        } catch {
            isTranslating = false
            lastError = TranslationError.from(error)
            return fallbackTranslation(for: text, target: target)
        }
    }
    
    public func translateBatch(_ texts: [String], source: String? = nil, target: String? = nil) async -> [String] {
        let source = source ?? "auto"
        let target = target ?? "en"
        isTranslating = true
        lastError = nil
        
        do {
            let results = try await performBatchTranslation(texts: texts, source: source, target: target)
            isTranslating = false
            lastTranslationTime = Date()
            translationCount += texts.count
            return results
        } catch {
            isTranslating = false
            lastError = TranslationError.from(error)
            return texts.map { fallbackTranslation(for: $0, target: target) }
        }
    }
    
    public func detectLanguage(text: String) async -> String? {
        try? await Task.sleep(nanoseconds: 100_000_000)
        if text.contains("你") { return "zh" }
        if text.contains("Hola") { return "es" }
        if text.contains("नमस्ते") { return "hi" }
        if text.contains("مرحبا") { return "ar" }
        return "en"
    }
    
    public func clearCache() {
        translationCache.removeAllObjects()
    }
    
    // MARK: - Private helpers
    
    private func cacheKeyFor(text: String, source: String, target: String) -> NSString {
        "\(source)|\(target)|\(text)" as NSString
    }
    
    private func performTranslationWithRetry(text: String, source: String, target: String) async throws -> String {
        var lastError: Error?
        for attempt in 1...maxRetries {
            do {
                return try await performTranslation(text: text, source: source, target: target)
            } catch {
                lastError = error
                if attempt < maxRetries {
                    let delay = pow(2.0, Double(attempt - 1)) * 0.25
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        throw lastError ?? TranslationError.unknown
    }
    
    private func performTranslation(text: String, source: String, target: String) async throws -> String {
        try? await Task.sleep(nanoseconds: 300_000_000)
        return mockTranslation(text: text, target: target)
    }
    
    private func performBatchTranslation(texts: [String], source: String, target: String) async throws -> [String] {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return texts.map { mockTranslation(text: $0, target: target) }
    }
    
    private func mockTranslation(text: String, target: String) -> String {
        switch target {
        case "zh": return "[中] \(text)"
        case "es": return "[ES] \(text)"
        case "hi": return "[HI] \(text)"
        case "ar": return "[AR] \(text)"
        default: return "[EN] \(text)"
        }
    }
    
    private func fallbackTranslation(for text: String, target: String) -> String {
        "[Fallback \(target)] \(text)"
    }
}

public enum TranslationError: Error {
    case network
    case rateLimited
    case unknown
    
    static func from(_ error: Error) -> TranslationError {
        if let error = error as? TranslationError {
            return error
        }
        return .unknown
    }
}
