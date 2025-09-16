import Foundation

// Modern Translation Service with async/await and error handling
@MainActor
public class ModernTranslationService: ObservableObject {

    // Singleton instance
    public static let shared = ModernTranslationService()

    // Modern state management
    @Published public private(set) var isTranslating = false
    @Published public private(set) var lastTranslationTime: Date?
    @Published public private(set) var translationCount = 0

    // Modern error handling
    @Published public var lastError: TranslationError?

    // Translation cache for performance
    private let translationCache = NSCache<NSString, NSString>()
    private let cacheQueue = DispatchQueue(label: "com.flowkey.translation.cache", attributes: .concurrent)

    // Modern async/await configuration
    private let apiTimeout: TimeInterval = 30.0
    private let maxRetries = 3

    private init() {
        setupCache()
    }

    // MARK: - Setup

    private func setupCache() {
        translationCache.countLimit = 1000
        translationCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }

    // MARK: - Modern Translation Methods

    public func translate(text: String, from sourceLanguage: String? = nil, to targetLanguage: String? = nil) async -> String {
        let source = sourceLanguage ?? "auto"
        let target = targetLanguage ?? "en"

        // Check cache first
        if let cachedResult = getCachedTranslation(text: text, source: source, target: target) {
            return cachedResult
        }

        // Show translation state
        isTranslating = true
        lastError = nil

        do {
            // Perform translation with retry logic
            let result = try await performTranslationWithRetry(
                text: text,
                source: source,
                target: target
            )

            // Update state
            isTranslating = false
            lastTranslationTime = Date()
            translationCount += 1

            // Cache the result
            cacheTranslation(result: result, text: text, source: source, target: target)

            return result
        } catch {
            // Handle error
            isTranslating = false
            lastError = TranslationError.from(error)

            // Return fallback result
            return getFallbackTranslation(text: text, target: target)
        }
    }

    // Modern batch translation
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

            // Return fallback for each text
            return texts.map { getFallbackTranslation(text: $0, target: target) }
        }
    }

    // Modern language detection
    public func detectLanguage(text: String) async -> String? {
        // Simulate language detection
        // In a real implementation, this would call a language detection API
        await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay

        // Simple heuristic based on character sets
        if text.contains("你") || text.contains("好") {
            return "zh"
        } else if text.contains("Hola") || text.contains("mundo") {
            return "es"
        } else if text.contains("नमस्ते") || text.contains("दुनिया") {
            return "hi"
        } else if text.contains("مرحبا") || text.contains("العالم") {
            return "ar"
        } else {
            return "en"
        }
    }

    // MARK: - Private Implementation

    private func performTranslationWithRetry(text: String, source: String, target: String) async throws -> String {
        var lastError: Error?

        for attempt in 1...maxRetries {
            do {
                return try await performTranslation(text: text, source: source, target: target)
            } catch {
                lastError = error

                // Don't retry on certain errors
                if error is TranslationError {
                    throw error
                }

                // Exponential backoff
                if attempt < maxRetries {
                    let delay = pow(2.0, Double(attempt)) * 0.5
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        throw lastError ?? TranslationError.unknown
    }

    private func performTranslation(text: String, source: String, target: String) async throws -> String {
        // Simulate API call with delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay

        // Mock translation logic
        return getMockTranslation(text: text, target: target)
    }

    private func performBatchTranslation(texts: [String], source: String, target: String) async throws -> [String] {
        // Simulate batch API call
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay

        // Mock batch translation
        return texts.map { getMockTranslation(text: $0, target: target) }
    }

    // MARK: - Cache Management

    private func getCachedTranslation(text: String, source: String, target: String) -> String? {
        let cacheKey = "\(source):\(target):\(text)" as NSString

        return cacheQueue.sync {
            return translationCache.object(forKey: cacheKey) as String?
        }
    }

    private func cacheTranslation(result: String, text: String, source: String, target: String) {
        let cacheKey = "\(source):\(target):\(text)" as NSString

        cacheQueue.async(flags: .barrier) {
            self.translationCache.setObject(result as NSString, forKey: cacheKey)
        }
    }

    public func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.translationCache.removeAllObjects()
        }
    }

    // MARK: - Mock Translation Logic

    private func getMockTranslation(text: String, target: String) -> String {
        switch target {
        case "zh":
            return mockChineseTranslation(text: text)
        case "es":
            return mockSpanishTranslation(text: text)
        case "hi":
            return mockHindiTranslation(text: text)
        case "ar":
            return mockArabicTranslation(text: text)
        default:
            return text // Return original for English or unknown
        }
    }

    private func mockChineseTranslation(text: String) -> String {
        let translations = [
            "Hello World": "你好世界",
            "Good morning": "早上好",
            "Thank you": "谢谢",
            "Goodbye": "再见",
            "How are you": "你好吗"
        ]

        return translations[text] ?? "[翻译: \(text)]"
    }

    private func mockSpanishTranslation(text: String) -> String {
        let translations = [
            "Hello World": "Hola Mundo",
            "Good morning": "Buenos días",
            "Thank you": "Gracias",
            "Goodbye": "Adiós",
            "How are you": "¿Cómo estás"
        ]

        return translations[text] ?? "[Traducción: \(text)]"
    }

    private func mockHindiTranslation(text: String) -> String {
        let translations = [
            "Hello World": "नमस्ते दुनिया",
            "Good morning": "सुप्रभात",
            "Thank you": "धन्यवाद",
            "Goodbye": "अलविदा",
            "How are you": "आप कैसे हैं"
        ]

        return translations[text] ?? "[अनुवाद: \(text)]"
    }

    private func mockArabicTranslation(text: String) -> String {
        let translations = [
            "Hello World": "مرحبا بالعالم",
            "Good morning": "صباح الخير",
            "Thank you": "شكرا",
            "Goodbye": "وداعا",
            "How are you": "كيف حالك"
        ]

        return translations[text] ?? "[ترجمة: \(text)]"
    }

    private func getFallbackTranslation(text: String, target: String) -> String {
        return "[Fallback: \(text) → \(target)]"
    }

    // MARK: - Modern Configuration

    public func configure(timeout: TimeInterval, maxRetries: Int, cacheSize: Int) {
        // Thread-safe configuration update
        cacheQueue.async(flags: .barrier) {
            self.translationCache.countLimit = cacheSize
        }
    }
}

// MARK: - Modern Translation Error

public enum TranslationError: Error, LocalizedError {
    case networkUnavailable
    case timeout
    case invalidAPIKey
    case quotaExceeded
    case unsupportedLanguage
    case invalidText
    case serverError(Int)
    case unknown

    public var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network is unavailable"
        case .timeout:
            return "Translation request timed out"
        case .invalidAPIKey:
            return "Invalid API key"
        case .quotaExceeded:
            return "Translation quota exceeded"
        case .unsupportedLanguage:
            return "Unsupported language pair"
        case .invalidText:
            return "Invalid text for translation"
        case .serverError(let code):
            return "Server error: \(code)"
        case .unknown:
            return "Unknown translation error"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Please check your internet connection"
        case .timeout:
            return "Please try again"
        case .invalidAPIKey:
            return "Please update your API key in settings"
        case .quotaExceeded:
            return "Please upgrade your plan or wait for quota reset"
        case .unsupportedLanguage:
            return "Please select a different language pair"
        case .invalidText:
            return "Please enter valid text to translate"
        case .serverError:
            return "Please try again later"
        case .unknown:
            return "Please contact support"
        }
    }

    // Modern error creation from other error types
    static func from(_ error: Error) -> TranslationError {
        if let translationError = error as? TranslationError {
            return translationError
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnavailable
            case .timedOut:
                return .timeout
            default:
                return .unknown
            }
        }

        return .unknown
    }
}

// MARK: - Modern Translation Request

public struct TranslationRequest {
    public let text: String
    public let sourceLanguage: String
    public let targetLanguage: String
    public let id = UUID()

    public init(text: String, sourceLanguage: String = "auto", targetLanguage: String) {
        self.text = text
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
    }
}

// MARK: - Modern Translation Response

public struct TranslationResponse {
    public let request: TranslationRequest
    public let translatedText: String
    public let detectedLanguage: String?
    public let confidence: Double?
    public let timestamp: Date

    public init(request: TranslationRequest, translatedText: String, detectedLanguage: String? = nil, confidence: Double? = nil) {
        self.request = request
        self.translatedText = translatedText
        self.detectedLanguage = detectedLanguage
        self.confidence = confidence
        self.timestamp = Date()
    }
}

// MARK: - Modern Translation History

@MainActor
public class TranslationHistory: ObservableObject {
    @Published public private(set) var translations: [TranslationResponse] = []
    private let maxHistorySize = 100

    public func add(_ response: TranslationResponse) {
        translations.insert(response, at: 0)

        // Maintain history size
        if translations.count > maxHistorySize {
            translations.removeLast()
        }
    }

    public func clear() {
        translations.removeAll()
    }

    public func search(query: String) -> [TranslationResponse] {
        return translations.filter { response in
            response.request.text.localizedCaseInsensitiveContains(query) ||
            response.translatedText.localizedCaseInsensitiveContains(query)
        }
    }
}

// MARK: - Modern Translation Metrics

public struct TranslationMetrics {
    public let totalTranslations: Int
    public let averageResponseTime: TimeInterval
    public let successRate: Double
    public let mostUsedLanguagePair: (source: String, target: String)?
    public let cacheHitRate: Double

    public init(translations: [TranslationResponse], totalRequests: Int, cacheHits: Int) {
        self.totalTranslations = translations.count
        self.averageResponseTime = calculateAverageResponseTime(translations)
        self.successRate = calculateSuccessRate(translations, totalRequests)
        self.mostUsedLanguagePair = calculateMostUsedLanguagePair(translations)
        self.cacheHitRate = Double(cacheHits) / Double(totalRequests)
    }

    private func calculateAverageResponseTime(_ translations: [TranslationResponse]) -> TimeInterval {
        guard !translations.isEmpty else { return 0 }

        let now = Date()
        let timeIntervals = translations.map { now.timeIntervalSince($0.timestamp) }
        return timeIntervals.reduce(0, +) / Double(timeIntervals.count)
    }

    private func calculateSuccessRate(_ translations: [TranslationResponse], _ totalRequests: Int) -> Double {
        guard totalRequests > 0 else { return 0 }
        return Double(translations.count) / Double(totalRequests)
    }

    private func calculateMostUsedLanguagePair(_ translations: [TranslationResponse]) -> (String, String)? {
        let languagePairs = translations.map { ($0.request.sourceLanguage, $0.request.targetLanguage) }

        let frequency = languagePairs.reduce(into: [:]) { counts, pair in
            counts[pair, default: 0] += 1
        }

        return frequency.max { $0.value < $1.value }?.key
    }
}