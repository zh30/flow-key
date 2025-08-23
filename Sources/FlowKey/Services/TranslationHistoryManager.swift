import Foundation

public class TranslationHistoryManager {
    public static let shared = TranslationHistoryManager()
    
    private init() {}
    
    // MARK: - Data Storage
    
    private var historyRecords: [TranslationRecord] = []
    private let maxRecords = 1000
    private let userDefaultsKey = "FlowKeyTranslationHistory"
    
    // MARK: - Translation Record Structure
    
    public struct TranslationRecord: Codable, Identifiable {
        public let id: String
        public let originalText: String
        public let translatedText: String
        public let sourceLanguage: String
        public let targetLanguage: String
        public let translationMode: String
        public let timestamp: Date
        public let confidence: Double?
        public let context: String?
        
        public init(
            originalText: String,
            translatedText: String,
            sourceLanguage: String,
            targetLanguage: String,
            translationMode: String,
            confidence: Double? = nil,
            context: String? = nil
        ) {
            self.id = UUID().uuidString
            self.originalText = originalText
            self.translatedText = translatedText
            self.sourceLanguage = sourceLanguage
            self.targetLanguage = targetLanguage
            self.translationMode = translationMode
            self.timestamp = Date()
            self.confidence = confidence
            self.context = context
        }
    }
    
    // MARK: - Public Methods
    
    public func addTranslationRecord(
        originalText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String,
        translationMode: String,
        confidence: Double? = nil,
        context: String? = nil
    ) {
        let record = TranslationRecord(
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            translationMode: translationMode,
            confidence: confidence,
            context: context
        )
        
        historyRecords.insert(record, at: 0)
        
        // Limit history size
        if historyRecords.count > maxRecords {
            historyRecords.removeLast()
        }
        
        // Save to persistent storage
        saveHistory()
        
        print("Translation history record added: \(originalText.prefix(50))...")
    }
    
    public func getTranslationHistory(limit: Int = 50) -> [TranslationRecord] {
        return Array(historyRecords.prefix(limit))
    }
    
    public func searchHistory(query: String, limit: Int = 20) -> [TranslationRecord] {
        let lowercasedQuery = query.lowercased()
        
        return historyRecords.filter { record in
            record.originalText.lowercased().contains(lowercasedQuery) ||
            record.translatedText.lowercased().contains(lowercasedQuery) ||
            record.context?.lowercased().contains(lowercasedQuery) ?? false
        }.prefix(limit).map { $0 }
    }
    
    public func getHistoryByDateRange(startDate: Date, endDate: Date) -> [TranslationRecord] {
        return historyRecords.filter { record in
            record.timestamp >= startDate && record.timestamp <= endDate
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    public func getHistoryByLanguagePair(source: String, target: String) -> [TranslationRecord] {
        return historyRecords.filter { record in
            record.sourceLanguage == source && record.targetLanguage == target
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    public func deleteTranslationRecord(withId id: String) {
        historyRecords.removeAll { $0.id == id }
        saveHistory()
    }
    
    public func clearAllHistory() {
        historyRecords.removeAll()
        saveHistory()
    }
    
    public func getHistoryStatistics() -> HistoryStatistics {
        let totalTranslations = historyRecords.count
        
        let languagePairs = Dictionary(grouping: historyRecords) { record in
            "\(record.sourceLanguage)->\(record.targetLanguage)"
        }
        
        let mostUsedPair = languagePairs.max { $0.value.count < $1.value.count }
        
        let translationsByMode = Dictionary(grouping: historyRecords) { $0.translationMode }
        
        let averageConfidence = historyRecords.compactMap { $0.confidence }.reduce(0, +) / Double(historyRecords.compactMap { $0.confidence }.count)
        
        return HistoryStatistics(
            totalTranslations: totalTranslations,
            uniqueLanguagePairs: languagePairs.count,
            mostUsedLanguagePair: mostUsedPair?.key,
            translationsByMode: translationsByMode.mapValues { $0.count },
            averageConfidence: averageConfidence.isNaN ? 0 : averageConfidence
        )
    }
    
    // MARK: - Private Methods
    
    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(historyRecords)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save translation history: \(error)")
        }
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        
        do {
            historyRecords = try JSONDecoder().decode([TranslationRecord].self, from: data)
        } catch {
            print("Failed to load translation history: \(error)")
            historyRecords = []
        }
    }
    
    // MARK: - Initialization
    
    public func initialize() {
        loadHistory()
        print("Translation history manager initialized with \(historyRecords.count) records")
    }
}

// MARK: - Statistics Structure

public struct HistoryStatistics {
    public let totalTranslations: Int
    public let uniqueLanguagePairs: Int
    public let mostUsedLanguagePair: String?
    public let translationsByMode: [String: Int]
    public let averageConfidence: Double
}