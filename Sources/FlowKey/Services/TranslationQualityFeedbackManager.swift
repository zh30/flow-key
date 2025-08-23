import Foundation
import CoreData

public class TranslationQualityFeedbackManager {
    public static let shared = TranslationQualityFeedbackManager()
    
    private init() {}
    
    // MARK: - Feedback Types
    
    public enum FeedbackType: String, CaseIterable {
        case accuracy = "accuracy"
        case fluency = "fluency"
        case naturalness = "naturalness"
        case culturalAppropriateness = "cultural"
        case terminology = "terminology"
        case grammar = "grammar"
        case style = "style"
        case overall = "overall"
        
        public var displayName: String {
            switch self {
            case .accuracy: return "准确性"
            case .fluency: return "流畅度"
            case .naturalness: return "自然度"
            case .culturalAppropriateness: return "文化适应性"
            case .terminology: return "术语准确性"
            case .grammar: return "语法正确性"
            case .style: return "风格一致性"
            case .overall: return "整体质量"
            }
        }
    }
    
    public enum Rating: Int, CaseIterable {
        case poor = 1
        case fair = 2
        case good = 3
        case veryGood = 4
        case excellent = 5
        
        public var displayName: String {
            switch self {
            case .poor: return "差"
            case .fair: return "一般"
            case .good: return "好"
            case .veryGood: return "很好"
            case .excellent: return "优秀"
            }
        }
    }
    
    public struct TranslationFeedback {
        public let id: String
        public let originalText: String
        public let translatedText: String
        public let sourceLanguage: String
        public let targetLanguage: String
        public let ratings: [FeedbackType: Rating]
        public let userComments: String?
        public let suggestedImprovement: String?
        public let timestamp: Date
        public let context: String?
        public let wasOptimized: Bool
        public let optimizationApplied: Bool
        
        public init(id: String, originalText: String, translatedText: String, sourceLanguage: String, targetLanguage: String,
                    ratings: [FeedbackType: Rating], userComments: String? = nil, suggestedImprovement: String? = nil,
                    timestamp: Date = Date(), context: String? = nil, wasOptimized: Bool = false, optimizationApplied: Bool = false) {
            self.id = id
            self.originalText = originalText
            self.translatedText = translatedText
            self.sourceLanguage = sourceLanguage
            self.targetLanguage = targetLanguage
            self.ratings = ratings
            self.userComments = userComments
            self.suggestedImprovement = suggestedImprovement
            self.timestamp = timestamp
            self.context = context
            self.wasOptimized = wasOptimized
            self.optimizationApplied = optimizationApplied
        }
    }
    
    public struct QualityInsight {
        public let issueType: FeedbackType
        public let severity: Double
        public let frequency: Int
        public let commonPhrases: [String]
        public let suggestedImprovements: [String]
        public let impact: Double
        
        public init(issueType: FeedbackType, severity: Double, frequency: Int, commonPhrases: [String],
                    suggestedImprovements: [String], impact: Double) {
            self.issueType = issueType
            self.severity = severity
            self.frequency = frequency
            self.commonPhrases = commonPhrases
            self.suggestedImprovements = suggestedImprovements
            self.impact = impact
        }
    }
    
    // MARK: - Feedback Management
    
    public func submitFeedback(
        originalText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String,
        ratings: [FeedbackType: Rating],
        userComments: String? = nil,
        suggestedImprovement: String? = nil,
        context: String? = nil,
        wasOptimized: Bool = false,
        optimizationApplied: Bool = false
    ) async {
        let feedback = TranslationFeedback(
            id: UUID().uuidString,
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            ratings: ratings,
            userComments: userComments,
            suggestedImprovement: suggestedImprovement,
            context: context,
            wasOptimized: wasOptimized,
            optimizationApplied: optimizationApplied
        )
        
        await saveFeedback(feedback)
        await analyzeFeedbackForInsights(feedback)
    }
    
    public func getFeedbackHistory(limit: Int = 100) async -> [TranslationFeedback] {
        // In a real implementation, this would fetch from Core Data
        return await loadFeedbackFromDatabase(limit: limit)
    }
    
    public func getQualityInsights() async -> [QualityInsight] {
        let feedback = await getFeedbackHistory()
        return await analyzeFeedbackForPatterns(feedback)
    }
    
    public func getAverageRating(for feedbackType: FeedbackType) async -> Double {
        let feedback = await getFeedbackHistory()
        let relevantFeedback = feedback.filter { $0.ratings[feedbackType] != nil }
        
        guard !relevantFeedback.isEmpty else { return 0.0 }
        
        let totalRating = relevantFeedback.reduce(0) { sum, item in
            sum + (item.ratings[feedbackType]?.rawValue ?? 0)
        }
        
        return Double(totalRating) / Double(relevantFeedback.count)
    }
    
    public func getOptimizationEffectiveness() async -> (optimized: Double, nonOptimized: Double) {
        let feedback = await getFeedbackHistory()
        
        let optimizedFeedback = feedback.filter { $0.wasOptimized && $0.optimizationApplied }
        let nonOptimizedFeedback = feedback.filter { !$0.wasOptimized }
        
        let optimizedAvg = await calculateAverageOverallRating(for: optimizedFeedback)
        let nonOptimizedAvg = await calculateAverageOverallRating(for: nonOptimizedFeedback)
        
        return (optimizedAvg, nonOptimizedAvg)
    }
    
    // MARK: - Private Methods
    
    private func saveFeedback(_ feedback: TranslationFeedback) async {
        // Save to Core Data
        let context = CoreDataManager.shared.context
        
        await context.perform {
            let feedbackEntity = TranslationFeedbackEntity(context: context)
            feedbackEntity.id = feedback.id
            feedbackEntity.originalText = feedback.originalText
            feedbackEntity.translatedText = feedback.translatedText
            feedbackEntity.sourceLanguage = feedback.sourceLanguage
            feedbackEntity.targetLanguage = feedback.targetLanguage
            feedbackEntity.timestamp = feedback.timestamp
            feedbackEntity.userComments = feedback.userComments
            feedbackEntity.suggestedImprovement = feedback.suggestedImprovement
            feedbackEntity.context = feedback.context
            feedbackEntity.wasOptimized = feedback.wasOptimized
            feedbackEntity.optimizationApplied = feedback.optimizationApplied
            
            // Save ratings
            for (type, rating) in feedback.ratings {
                let ratingEntity = FeedbackRatingEntity(context: context)
                ratingEntity.type = type.rawValue
                ratingEntity.rating = Int16(rating.rawValue)
                ratingEntity.feedback = feedbackEntity
            }
            
            do {
                try context.save()
            } catch {
                print("Failed to save feedback: \(error)")
            }
        }
    }
    
    private func loadFeedbackFromDatabase(limit: Int) async -> [TranslationFeedback] {
        let context = CoreDataManager.shared.context
        
        return await withCheckedContinuation { continuation in
            context.perform {
                let fetchRequest: NSFetchRequest<TranslationFeedbackEntity> = TranslationFeedbackEntity.fetchRequest()
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
                fetchRequest.fetchLimit = limit
                
                do {
                    let entities = try context.fetch(fetchRequest)
                    let feedback = entities.compactMap { entity in
                        self.convertEntityToFeedback(entity)
                    }
                    continuation.resume(returning: feedback)
                } catch {
                    print("Failed to load feedback: \(error)")
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    private func convertEntityToFeedback(_ entity: TranslationFeedbackEntity) -> TranslationFeedback? {
        var ratings: [FeedbackType: Rating] = [:]
        
        for ratingEntity in entity.ratings as? Set<FeedbackRatingEntity> ?? [] {
            if let type = FeedbackType(rawValue: ratingEntity.type ?? ""),
               let rating = Rating(rawValue: Int(ratingEntity.rating)) {
                ratings[type] = rating
            }
        }
        
        return TranslationFeedback(
            id: entity.id ?? UUID().uuidString,
            originalText: entity.originalText ?? "",
            translatedText: entity.translatedText ?? "",
            sourceLanguage: entity.sourceLanguage ?? "",
            targetLanguage: entity.targetLanguage ?? "",
            ratings: ratings,
            userComments: entity.userComments,
            suggestedImprovement: entity.suggestedImprovement,
            timestamp: entity.timestamp ?? Date(),
            context: entity.context,
            wasOptimized: entity.wasOptimized,
            optimizationApplied: entity.optimizationApplied
        )
    }
    
    private func analyzeFeedbackForInsights(_ feedback: TranslationFeedback) async {
        // Analyze feedback for immediate insights
        // This could trigger real-time improvements to the optimization system
        let lowRatings = feedback.ratings.filter { $0.value.rawValue <= 2 }
        
        if !lowRatings.isEmpty {
            await handleLowQualityFeedback(feedback, lowRatings: lowRatings)
        }
        
        if let suggestion = feedback.suggestedImprovement, !suggestion.isEmpty {
            await processUserSuggestion(feedback, suggestion: suggestion)
        }
    }
    
    private func analyzeFeedbackForPatterns(_ feedback: [TranslationFeedback]) async -> [QualityInsight] {
        var insights: [QualityInsight] = []
        
        // Analyze each feedback type
        for feedbackType in FeedbackType.allCases {
            let typeFeedback = feedback.filter { $0.ratings[feedbackType] != nil }
            
            guard !typeFeedback.isEmpty else { continue }
            
            let averageRating = typeFeedback.reduce(0.0) { sum, item in
                sum + Double(item.ratings[feedbackType]?.rawValue ?? 0)
            } / Double(typeFeedback.count)
            
            let severity = 1.0 - (averageRating / 5.0)
            
            // Find common phrases with issues
            let commonPhrases = await findCommonPhrasesWithIssues(typeFeedback, for: feedbackType)
            
            // Generate suggested improvements
            let improvements = await generateImprovementsForIssue(feedbackType, severity: severity)
            
            // Calculate impact based on frequency and severity
            let impact = severity * Double(typeFeedback.count) / Double(feedback.count)
            
            insights.append(QualityInsight(
                issueType: feedbackType,
                severity: severity,
                frequency: typeFeedback.count,
                commonPhrases: commonPhrases,
                suggestedImprovements: improvements,
                impact: impact
            ))
        }
        
        // Sort by impact
        return insights.sorted { $0.impact > $1.impact }
    }
    
    private func findCommonPhrasesWithIssues(_ feedback: [TranslationFeedback], for feedbackType: FeedbackType) async -> [String] {
        let lowQualityFeedback = feedback.filter { ($0.ratings[feedbackType]?.rawValue ?? 0) <= 2 }
        
        // Extract common phrases from low quality translations
        var phraseFrequency: [String: Int] = [:]
        
        for item in lowQualityFeedback {
            let phrases = extractPhrases(from: item.originalText)
            for phrase in phrases {
                phraseFrequency[phrase, default: 0] += 1
            }
        }
        
        // Return most frequent phrases
        return phraseFrequency.filter { $0.value >= 2 }.map { $0.key }.sorted()
    }
    
    private func generateImprovementsForIssue(_ feedbackType: FeedbackType, severity: Double) async -> [String] {
        var improvements: [String] = []
        
        switch feedbackType {
        case .accuracy:
            improvements = [
                "改进术语词典",
                "增强上下文理解",
                "优化翻译模型参数"
            ]
        case .fluency:
            improvements = [
                "改进语言模型",
                "增强语法检查",
                "优化句子结构"
            ]
        case .naturalness:
            improvements = [
                "增加自然语料库",
                "改进表达方式",
                "优化语言风格"
            ]
        case .culturalAppropriateness:
            improvements = [
                "增加文化适应性检查",
                "改进本地化处理",
                "优化文化敏感词处理"
            ]
        case .terminology:
            improvements = [
                "完善专业术语库",
                "改进术语一致性检查",
                "增加领域词典"
            ]
        case .grammar:
            improvements = [
                "增强语法检查",
                "改进语法规则",
                "优化语法纠错"
            ]
        case .style:
            improvements = [
                "改进风格一致性",
                "优化表达方式",
                "增强风格识别"
            ]
        case .overall:
            improvements = [
                "综合优化翻译质量",
                "改进用户体验",
                "增强系统稳定性"
            ]
        }
        
        return improvements
    }
    
    private func calculateAverageOverallRating(for feedback: [TranslationFeedback]) async -> Double {
        guard !feedback.isEmpty else { return 0.0 }
        
        let totalRating = feedback.reduce(0) { sum, item in
            let overallRating = item.ratings[.overall]?.rawValue ?? 
                             item.ratings.values.map { $0.rawValue }.reduce(0, +) / item.ratings.count
            return sum + overallRating
        }
        
        return Double(totalRating) / Double(feedback.count)
    }
    
    private func handleLowQualityFeedback(_ feedback: TranslationFeedback, lowRatings: [FeedbackType: Rating]) async {
        // Handle immediate feedback for low quality translations
        print("Low quality feedback detected for: \(feedback.originalText)")
        
        // This could trigger:
        // - Model retraining
        // - Rule updates
        // - User preference adjustments
    }
    
    private func processUserSuggestion(_ feedback: TranslationFeedback, suggestion: String) async {
        // Process user suggestions for improvement
        print("User suggestion: \(suggestion)")
        
        // This could:
        // - Add to user preference database
        // - Update translation rules
        // - Improve optimization algorithms
    }
    
    private func extractPhrases(from text: String) -> [String] {
        // Extract meaningful phrases from text
        let words = text.split(separator: " ")
        var phrases: [String] = []
        
        // Extract single words
        phrases.append(contentsOf: words.map(String.init))
        
        // Extract two-word phrases
        for i in 0..<(words.count - 1) {
            phrases.append("\(words[i]) \(words[i+1])")
        }
        
        // Extract three-word phrases
        for i in 0..<(words.count - 2) {
            phrases.append("\(words[i]) \(words[i+1]) \(words[i+2])")
        }
        
        return phrases
    }
    
    // MARK: - Public Utility Methods
    
    public func clearAllFeedback() async {
        let context = CoreDataManager.shared.context
        
        await context.perform {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = TranslationFeedbackEntity.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
                try context.save()
            } catch {
                print("Failed to clear feedback: \(error)")
            }
        }
    }
    
    public func exportFeedbackData() async -> Data {
        let feedback = await getFeedbackHistory()
        
        // Convert to JSON for export
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            return try encoder.encode(feedback)
        } catch {
            print("Failed to encode feedback data: \(error)")
            return Data()
        }
    }
}

// MARK: - Core Data Entities

@objc(TranslationFeedbackEntity)
public class TranslationFeedbackEntity: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var originalText: String?
    @NSManaged public var translatedText: String?
    @NSManaged public var sourceLanguage: String?
    @NSManaged public var targetLanguage: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var userComments: String?
    @NSManaged public var suggestedImprovement: String?
    @NSManaged public var context: String?
    @NSManaged public var wasOptimized: Bool
    @NSManaged public var optimizationApplied: Bool
    @NSManaged public var ratings: Set<FeedbackRatingEntity>?
}

@objc(FeedbackRatingEntity)
public class FeedbackRatingEntity: NSManagedObject {
    @NSManaged public var type: String?
    @NSManaged public var rating: Int16
    @NSManaged public var feedback: TranslationFeedbackEntity?
}