import Foundation
import CoreData
import Combine
import NaturalLanguage

public class IntelligentRecommendationManager {
    public static let shared = IntelligentRecommendationManager()
    
    private init() {}
    
    public func initialize() async {
        // Initialize recommendation manager
        print("Intelligent recommendation manager initialized")
    }
    
    // MARK: - Properties
    
    private let context = CoreDataManager.shared.viewContext
    private let recommendationQueue = DispatchQueue(label: "com.flowkey.recommendation", qos: .userInitiated)
    private let nlpTagger = NLTagger(tagSchemes: [.lexicalClass])
    
    // MARK: - Recommendation Types
    
    public enum RecommendationType: String, CaseIterable {
        case phrase = "phrase"
        case translation = "translation"
        case knowledge = "knowledge"
        case template = "template"
        case action = "action"
        case correction = "correction"
        case formatting = "formatting"
        case completion = "completion"
        
        var displayName: String {
            switch self {
            case .phrase: return "常用语推荐"
            case .translation: return "翻译推荐"
            case .knowledge: return "知识库推荐"
            case .template: return "模板推荐"
            case .action: return "操作推荐"
            case .correction: return "纠错推荐"
            case .formatting: return "格式化推荐"
            case .completion: return "补全推荐"
            }
        }
        
        var icon: String {
            switch self {
            case .phrase: return "text.bubble"
            case .translation: return "translate"
            case .knowledge: return "brain"
            case .template: return "doc.text"
            case .action: return "hand.tap"
            case .correction: return "checkmark.circle"
            case .formatting: return "textformat"
            case .completion: return "text.cursor"
            }
        }
    }
    
    public enum RecommendationPriority: Int, CaseIterable {
        case low = 1
        case medium = 2
        case high = 3
        case urgent = 4
        
        var displayName: String {
            switch self {
            case .low: return "低"
            case .medium: return "中"
            case .high: return "高"
            case .urgent: return "紧急"
            }
        }
        
        var color: String {
            switch self {
            case .low: return "gray"
            case .medium: return "blue"
            case .high: return "orange"
            case .urgent: return "red"
            }
        }
    }
    
    // MARK: - Recommendation Structures
    
    public struct Recommendation {
        public let id: UUID
        public let type: RecommendationType
        public let title: String
        public let description: String
        public let content: String
        public let priority: RecommendationPriority
        public let confidence: Double
        public let context: RecommendationContext
        public let metadata: [String: Any]
        public let timestamp: Date
        
        public init(
            id: UUID = UUID(),
            type: RecommendationType,
            title: String,
            description: String,
            content: String,
            priority: RecommendationPriority,
            confidence: Double,
            context: RecommendationContext,
            metadata: [String: Any] = [:]
        ) {
            self.id = id
            self.type = type
            self.title = title
            self.description = description
            self.content = content
            self.priority = priority
            self.confidence = confidence
            self.context = context
            self.metadata = metadata
            self.timestamp = Date()
        }
    }
    
    public struct RecommendationContext {
        public let currentApp: String
        public let currentWindow: String?
        public let selectedText: String?
        public let cursorPosition: Int?
        public let surroundingText: String?
        public let timeOfDay: Int
        public let dayOfWeek: Int
        public let recentActions: [String]
        
        public init(
            currentApp: String,
            currentWindow: String? = nil,
            selectedText: String? = nil,
            cursorPosition: Int? = nil,
            surroundingText: String? = nil,
            recentActions: [String] = []
        ) {
            self.currentApp = currentApp
            self.currentWindow = currentWindow
            self.selectedText = selectedText
            self.cursorPosition = cursorPosition
            self.surroundingText = surroundingText
            self.recentActions = recentActions
            
            let now = Date()
            self.timeOfDay = Calendar.current.component(.hour, from: now)
            self.dayOfWeek = Calendar.current.component(.weekday, from: now)
        }
    }
    
    // MARK: - Main Recommendation Interface
    
    public func getRecommendations(for context: RecommendationContext) async -> [Recommendation] {
        return await recommendationQueue.async {
            var recommendations: [Recommendation] = []
            
            // Get phrase recommendations
            recommendations.append(contentsOf: self.getPhraseRecommendations(for: context))
            
            // Get translation recommendations
            recommendations.append(contentsOf: self.getTranslationRecommendations(for: context))
            
            // Get knowledge base recommendations
            recommendations.append(contentsOf: self.getKnowledgeRecommendations(for: context))
            
            // Get action recommendations
            recommendations.append(contentsOf: self.getActionRecommendations(for: context))
            
            // Get completion recommendations
            if let text = context.surroundingText ?? context.selectedText {
                recommendations.append(contentsOf: self.getCompletionRecommendations(for: text, context: context))
            }
            
            // Get formatting recommendations
            if let text = context.selectedText {
                recommendations.append(contentsOf: self.getFormattingRecommendations(for: text, context: context))
            }
            
            // Sort by priority and confidence
            return recommendations.sorted {
                if $0.priority.rawValue != $1.priority.rawValue {
                    return $0.priority.rawValue > $1.priority.rawValue
                }
                return $0.confidence > $1.confidence
            }
        }
    }
    
    public func recordRecommendationInteraction(recommendationId: UUID, action: String) {
        recommendationQueue.async {
            // Record user interaction with recommendation
            let interaction = RecommendationInteraction(
                id: UUID(),
                recommendationId: recommendationId,
                action: action,
                timestamp: Date()
            )
            
            // Update recommendation learning model
            self.updateRecommendationModel(interaction: interaction)
        }
    }
    
    // MARK: - Phrase Recommendations
    
    private func getPhraseRecommendations(for context: RecommendationContext) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // Get frequently used phrases based on context
        let contextPhrases = getContextualPhrases(for: context)
        
        // Get time-based phrases
        let timePhrases = getTimeBasedPhrases(for: context)
        
        // Get app-specific phrases
        let appPhrases = getAppSpecificPhrases(for: context)
        
        // Combine and rank phrases
        let allPhrases = contextPhrases + timePhrases + appPhrases
        
        for phrase in allPhrases.prefix(3) {
            let recommendation = Recommendation(
                type: .phrase,
                title: "推荐常用语",
                description: "基于当前上下文推荐",
                content: phrase.content,
                priority: .medium,
                confidence: phrase.confidence,
                context: context,
                metadata: [
                    "phrase_id": phrase.id,
                    "category": phrase.category.rawValue,
                    "usage_count": phrase.usageCount
                ]
            )
            recommendations.append(recommendation)
        }
        
        return recommendations
    }
    
    // MARK: - Translation Recommendations
    
    private func getTranslationRecommendations(for context: RecommendationContext) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        guard let selectedText = context.selectedText, !selectedText.isEmpty else {
            return []
        }
        
        // Detect if text needs translation
        if shouldTranslate(text: selectedText, context: context) {
            let recommendation = Recommendation(
                type: .translation,
                title: "翻译建议",
                description: "检测到可能需要翻译的文本",
                content: selectedText,
                priority: .high,
                confidence: 0.8,
                context: context,
                metadata: [
                    "detected_language": detectLanguage(text: selectedText),
                    "suggested_target": getPreferredTargetLanguage()
                ]
            )
            recommendations.append(recommendation)
        }
        
        return recommendations
    }
    
    // MARK: - Knowledge Base Recommendations
    
    private func getKnowledgeRecommendations(for context: RecommendationContext) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        guard let queryText = context.selectedText ?? context.surroundingText, !queryText.isEmpty else {
            return []
        }
        
        // Extract keywords from text
        let keywords = extractKeywords(from: queryText)
        
        // Search knowledge base for relevant documents
        let relevantDocs = searchKnowledgeBase(for: keywords)
        
        for doc in relevantDocs.prefix(2) {
            let recommendation = Recommendation(
                type: .knowledge,
                title: "相关知识",
                description: "在知识库中找到相关内容",
                content: doc.title ?? "未命名文档",
                priority: .medium,
                confidence: doc.relevanceScore,
                context: context,
                metadata: [
                    "document_id": doc.id,
                    "document_type": doc.documentType,
                    "tags": doc.tags ?? []
                ]
            )
            recommendations.append(recommendation)
        }
        
        return recommendations
    }
    
    // MARK: - Action Recommendations
    
    private func getActionRecommendations(for context: RecommendationContext) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // Get user habits to predict next action
        let predictedActions = predictNextActions(for: context)
        
        for action in predictedActions.prefix(2) {
            let recommendation = Recommendation(
                type: .action,
                title: "建议操作",
                description: action.reason,
                content: action.actionType,
                priority: action.priority,
                confidence: action.confidence,
                context: context,
                metadata: [
                    "action_type": action.actionType,
                    "based_on_habits": true
                ]
            )
            recommendations.append(recommendation)
        }
        
        return recommendations
    }
    
    // MARK: - Completion Recommendations
    
    private func getCompletionRecommendations(for text: String, context: RecommendationContext) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // Get word completions
        let completions = getWordCompletions(for: text)
        
        for completion in completions.prefix(3) {
            let recommendation = Recommendation(
                type: .completion,
                title: "自动补全",
                description: "基于上下文的智能补全",
                content: completion.text,
                priority: .low,
                confidence: completion.confidence,
                context: context,
                metadata: [
                    "completion_type": completion.type,
                    "source": completion.source
                ]
            )
            recommendations.append(recommendation)
        }
        
        return recommendations
    }
    
    // MARK: - Formatting Recommendations
    
    private func getFormattingRecommendations(for text: String, context: RecommendationContext) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // Check for formatting issues
        let formattingIssues = detectFormattingIssues(in: text)
        
        for issue in formattingIssues {
            let recommendation = Recommendation(
                type: .formatting,
                title: "格式建议",
                description: issue.description,
                content: issue.suggestion,
                priority: issue.severity,
                confidence: issue.confidence,
                context: context,
                metadata: [
                    "issue_type": issue.type,
                    "original_text": issue.originalText
                ]
            )
            recommendations.append(recommendation)
        }
        
        return recommendations
    }
    
    // MARK: - Helper Methods
    
    private func getContextualPhrases(for context: RecommendationContext) -> [RankedPhrase] {
        // Get phrases based on current app context
        let appPhrases = PhraseManager.shared.getPhrases(for: context.currentApp)
        
        // Get phrases based on recent user habits
        let habitPhrases = getHabitBasedPhrases(for: context)
        
        // Combine and rank
        return rankPhrases(appPhrases + habitPhrases, context: context)
    }
    
    private func getTimeBasedPhrases(for context: RecommendationContext) -> [RankedPhrase] {
        let hour = context.timeOfDay
        let dayOfWeek = context.dayOfWeek
        
        // Get time-based phrases
        let timePhrases = PhraseManager.shared.getTimeBasedPhrases(hour: hour, dayOfWeek: dayOfWeek)
        
        return rankPhrases(timePhrases, context: context)
    }
    
    private func getAppSpecificPhrases(for context: RecommendationContext) -> [RankedPhrase] {
        // Get app-specific phrases
        let appPhrases = PhraseManager.shared.getAppSpecificPhrases(appName: context.currentApp)
        
        return rankPhrases(appPhrases, context: context)
    }
    
    private func getHabitBasedPhrases(for context: RecommendationContext) -> [PhraseManager.Phrase] {
        let preferences = UserHabitManager.shared.getLearnedPreferences()
        
        // Get phrases based on user habits
        return PhraseManager.shared.getPhrasesBasedOnHabits(preferences: preferences)
    }
    
    private func rankPhrases(_ phrases: [PhraseManager.Phrase], context: RecommendationContext) -> [RankedPhrase] {
        return phrases.map { phrase in
            let confidence = calculatePhraseConfidence(phrase: phrase, context: context)
            return RankedPhrase(phrase: phrase, confidence: confidence)
        }.sorted { $0.confidence > $1.confidence }
    }
    
    private func calculatePhraseConfidence(phrase: PhraseManager.Phrase, context: RecommendationContext) -> Double {
        var confidence = 0.0
        
        // Base confidence from usage frequency
        confidence += min(Double(phrase.usageCount) / 10.0, 0.5)
        
        // Priority bonus
        confidence += Double(phrase.priority) * 0.1
        
        // Favorite bonus
        if phrase.isFavorite {
            confidence += 0.2
        }
        
        // Recency bonus
        if let lastUsed = phrase.lastUsed {
            let daysSinceUse = Date().timeIntervalSince(lastUsed) / (24 * 60 * 60)
            if daysSinceUse < 7 {
                confidence += 0.1
            }
        }
        
        // Context matching
        if context.currentApp.contains("Mail") && phrase.category == .email {
            confidence += 0.3
        }
        
        return min(confidence, 1.0)
    }
    
    private func shouldTranslate(text: String, context: RecommendationContext) -> Bool {
        // Detect if text is in foreign language
        let detectedLanguage = detectLanguage(text: text)
        let preferredLanguage = getPreferredTargetLanguage()
        
        return detectedLanguage != preferredLanguage && detectedLanguage != "unknown"
    }
    
    private func detectLanguage(text: String) -> String {
        nlpTagger.string = text
        let language = nlpTagger.dominantLanguage
        return language?.rawValue ?? "unknown"
    }
    
    private func getPreferredTargetLanguage() -> String {
        let preferences = UserHabitManager.shared.getLearnedPreferences()
        return preferences.preferredLanguages.first ?? "zh"
    }
    
    private func extractKeywords(from text: String) -> [String] {
        // Simple keyword extraction
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.count > 2 }
        
        return Array(Set(words)).sorted()
    }
    
    private func searchKnowledgeBase(for keywords: [String]) -> [RelevantDocument] {
        // Search knowledge base using existing KnowledgeManager
        let results = KnowledgeManager.shared.searchDocuments(keywords.joined(separator: " "))
        
        return results.map { doc in
            RelevantDocument(
                id: doc.id?.uuidString ?? "",
                title: doc.title,
                documentType: doc.documentType,
                relevanceScore: calculateRelevanceScore(doc: doc, keywords: keywords),
                tags: doc.tags as? [String] ?? []
            )
        }.sorted { $0.relevanceScore > $1.relevanceScore }
    }
    
    private func calculateRelevanceScore(doc: KnowledgeDocument, keywords: [String]) -> Double {
        var score = 0.0
        
        // Check keyword matches in title
        let titleLower = (doc.title ?? "").lowercased()
        for keyword in keywords {
            if titleLower.contains(keyword.lowercased()) {
                score += 0.5
            }
        }
        
        // Check keyword matches in content
        let contentLower = (doc.content ?? "").lowercased()
        for keyword in keywords {
            if contentLower.contains(keyword.lowercased()) {
                score += 0.2
            }
        }
        
        return min(score, 1.0)
    }
    
    private func predictNextActions(for context: RecommendationContext) -> [PredictedAction] {
        let userContext = UserContext(
            currentApp: context.currentApp,
            currentWindow: context.currentWindow,
            selectedText: context.selectedText
        )
        
        if let prediction = UserHabitManager.shared.predictUserAction(context: userContext) {
            return [PredictedAction(
                actionType: prediction.actionType,
                confidence: prediction.confidence,
                reason: prediction.reason,
                priority: .medium
            )]
        }
        
        return []
    }
    
    private func getWordCompletions(for text: String) -> [CompletionSuggestion] {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        guard let lastWord = words.last, !lastWord.isEmpty else { return [] }
        
        // Get completions from various sources
        var completions: [CompletionSuggestion] = []
        
        // Dictionary completions
        completions.append(contentsOf: getDictionaryCompletions(for: lastWord))
        
        // Phrase completions
        completions.append(contentsOf: getPhraseCompletions(for: lastWord))
        
        // Habit-based completions
        completions.append(contentsOf: getHabitCompletions(for: lastWord))
        
        return completions.sorted { $0.confidence > $1.confidence }
    }
    
    private func getDictionaryCompletions(for word: String) -> [CompletionSuggestion] {
        // Simple dictionary-based completions
        return []
    }
    
    private func getPhraseCompletions(for word: String) -> [CompletionSuggestion] {
        let matchingPhrases = PhraseManager.shared.getPhrases(containing: word)
        
        return matchingPhrases.map { phrase in
            CompletionSuggestion(
                text: phrase.content,
                confidence: Double(phrase.usageCount) / 10.0,
                type: "phrase",
                source: "phrase_library"
            )
        }
    }
    
    private func getHabitCompletions(for word: String) -> [CompletionSuggestion] {
        // Get completions based on user habits
        return []
    }
    
    private func detectFormattingIssues(in text: String) -> [FormattingIssue] {
        var issues: [FormattingIssue] = []
        
        // Check for common formatting issues
        if text.contains("  ") {
            issues.append(FormattingIssue(
                type: "extra_spaces",
                description: "检测到多余空格",
                suggestion: "移除多余空格",
                severity: .low,
                confidence: 0.9,
                originalText: text
            ))
        }
        
        if text.hasPrefix(" ") || text.hasSuffix(" ") {
            issues.append(FormattingIssue(
                type: "leading_trailing_spaces",
                description: "检测到开头或结尾空格",
                suggestion: "移除开头和结尾空格",
                severity: .medium,
                confidence: 0.8,
                originalText: text
            ))
        }
        
        return issues
    }
    
    private func updateRecommendationModel(interaction: RecommendationInteraction) {
        // Update machine learning model based on user interaction
        // This would involve updating weights and preferences
    }
    
    // MARK: - Initialization
    
    public func initialize() {
        // Initialize recommendation system
        print("Intelligent recommendation manager initialized")
    }
}

// MARK: - Supporting Structures

private struct RankedPhrase {
    let phrase: PhraseManager.Phrase
    let confidence: Double
}

private struct RelevantDocument {
    let id: String
    let title: String?
    let documentType: String
    let relevanceScore: Double
    let tags: [String]
}

private struct PredictedAction {
    let actionType: String
    let confidence: Double
    let reason: String
    let priority: IntelligentRecommendationManager.RecommendationPriority
}

private struct CompletionSuggestion {
    let text: String
    let confidence: Double
    let type: String
    let source: String
}

private struct FormattingIssue {
    let type: String
    let description: String
    let suggestion: String
    let severity: IntelligentRecommendationManager.RecommendationPriority
    let confidence: Double
    let originalText: String
}

private struct RecommendationInteraction {
    let id: UUID
    let recommendationId: UUID
    let action: String
    let timestamp: Date
}