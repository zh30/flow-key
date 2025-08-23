import Foundation

public class UserHabitIntegrationService {
    public static let shared = UserHabitIntegrationService()
    
    private init() {}
    
    // MARK: - Integration Points
    
    private let habitManager = UserHabitManager.shared
    private let textDetector = SmartTextDetector.shared
    
    // MARK: - Translation Integration
    
    public func recordTranslationInteraction(
        sourceText: String,
        targetText: String,
        sourceLanguage: String,
        targetLanguage: String,
        confidence: Double,
        context: String? = nil
    ) {
        // Get current app context
        let appContext = getCurrentAppContext()
        
        // Record the translation habit
        habitManager.recordTranslationHabit(
            sourceText: sourceText,
            targetText: targetText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            confidence: confidence,
            context: context,
            appContext: appContext.currentApp
        )
        
        // Record time pattern
        habitManager.recordTimePattern(
            actionType: "translation",
            duration: nil
        )
        
        // Record app context usage
        habitManager.recordAppContextUsage(
            appName: appContext.currentApp,
            windowTitle: appContext.currentWindow,
            actionsPerformed: ["translation"],
            duration: 0
        )
    }
    
    // MARK: - Text Detection Integration
    
    public func recordTextDetectionInteraction(
        detectedText: String,
        result: SmartTextDetector.TextDetectionResult,
        selectedAction: SmartTextDetector.SuggestedAction?,
        context: String? = nil
    ) {
        let appContext = getCurrentAppContext()
        
        // Convert entities to string array
        let entities = result.entities.map { "\($0.type):\($0.value)" }
        
        // Convert suggested actions to string array
        let suggestedActions = result.suggestedActions.map { $0.title }
        
        // Record text detection habit
        habitManager.recordTextDetectionHabit(
            detectedText: detectedText,
            textType: result.type.rawValue,
            entities: entities,
            suggestedActions: suggestedActions,
            selectedAction: selectedAction?.title,
            confidence: result.confidence,
            appContext: appContext.currentApp
        )
        
        // Record time pattern
        habitManager.recordTimePattern(
            actionType: "text_detection",
            duration: nil
        )
    }
    
    // MARK: - Voice Recognition Integration
    
    public func recordVoiceRecognitionInteraction(
        audioDuration: TimeInterval,
        detectedText: String,
        confidence: Double,
        language: String?
    ) {
        let appContext = getCurrentAppContext()
        
        // Record voice recognition habit
        habitManager.recordVoiceRecognitionHabit(
            audioDuration: audioDuration,
            detectedText: detectedText,
            confidence: confidence,
            language: language,
            context: appContext.currentApp
        )
        
        // Record time pattern
        habitManager.recordTimePattern(
            actionType: "voice_recognition",
            duration: audioDuration
        )
    }
    
    // MARK: - Knowledge Search Integration
    
    public func recordKnowledgeSearchInteraction(
        query: String,
        resultsCount: Int,
        selectedDocument: String?,
        searchDuration: TimeInterval
    ) {
        let appContext = getCurrentAppContext()
        
        // Record knowledge search habit
        habitManager.recordKnowledgeSearchHabit(
            query: query,
            resultsCount: resultsCount,
            selectedDocument: selectedDocument,
            searchDuration: searchDuration,
            context: appContext.currentApp
        )
        
        // Record time pattern
        habitManager.recordTimePattern(
            actionType: "knowledge_search",
            duration: searchDuration
        )
    }
    
    // MARK: - Shortcut Integration
    
    public func recordShortcutUsage(
        shortcutType: String,
        success: Bool = true
    ) {
        let appContext = getCurrentAppContext()
        
        // Calculate success rate (simplified)
        let successRate = success ? 1.0 : 0.0
        
        // Record shortcut usage habit
        habitManager.recordShortcutUsage(
            shortcutType: shortcutType,
            triggerCount: 1,
            successRate: successRate,
            context: appContext.currentApp
        )
        
        // Record time pattern
        habitManager.recordTimePattern(
            actionType: "shortcut_usage",
            duration: nil
        )
    }
    
    // MARK: - Predictive Features
    
    public func getPredictedActions() -> [PredictedAction] {
        let appContext = getCurrentAppContext()
        var predictions: [PredictedAction] = []
        
        // Get prediction based on current context
        if let prediction = habitManager.predictUserAction(context: appContext) {
            predictions.append(prediction)
        }
        
        // Get time-based predictions
        if let timePrediction = getTimeBasedPrediction() {
            predictions.append(timePrediction)
        }
        
        return predictions
    }
    
    public func shouldAutoTranslate(_ text: String) -> Bool {
        let preferences = habitManager.getLearnedPreferences()
        
        // Check if user has language preferences that suggest auto-translation
        if !preferences.preferredLanguages.isEmpty {
            // This would integrate with language detection
            // For now, return true if user has translation habits
            return preferences.preferredLanguages.contains { $0.contains("translation") }
        }
        
        return false
    }
    
    public func getPreferredTranslationLanguages() -> (source: String, target: String)? {
        let preferences = habitManager.getLearnedPreferences()
        
        // Get the most frequently used language pair
        if let mostUsedPair = preferences.preferredLanguages.first {
            let components = mostUsedPair.split(separator: "_").map(String.init)
            if components.count == 2 {
                return (components[0], components[1])
            }
        }
        
        return nil
    }
    
    public func getPreferredActions(for textType: String) -> [String] {
        let preferences = habitManager.getLearnedPreferences()
        
        // Extract preferred actions from preferences
        if let actionPrefs = preferences.actionPreferences as? [String: Any],
           let preferredActions = actionPrefs[textType] as? [String] {
            return preferredActions
        }
        
        return []
    }
    
    public func getOptimalActionTiming() -> Date? {
        let preferences = habitManager.getLearnedPreferences()
        
        // Find the optimal time based on user's active hours
        if !preferences.activeHours.isEmpty {
            let currentHour = Calendar.current.component(.hour, from: Date())
            
            // Find the closest active hour
            let closestHour = preferences.activeHours.min { hour1, hour2 in
                abs(hour1 - currentHour) < abs(hour2 - currentHour)
            }
            
            if let optimalHour = closestHour {
                // Create a date for today at the optimal hour
                var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                components.hour = optimalHour
                
                return Calendar.current.date(from: components)
            }
        }
        
        return nil
    }
    
    // MARK: - Habit Insights
    
    public func getRelevantInsights() -> [HabitInsight] {
        let allInsights = habitManager.getHabitInsights()
        let currentTime = Date()
        
        // Filter insights that are relevant to current context
        return allInsights.filter { insight in
            // Keep recent insights (last 7 days)
            let daysSinceInsight = currentTime.timeIntervalSince(insight.timestamp) / (24 * 60 * 60)
            return daysSinceInsight <= 7
        }.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    public func getHabitSummary() -> HabitSummary {
        let preferences = habitManager.getLearnedPreferences()
        let insights = getRelevantInsights()
        
        return HabitSummary(
            totalHabits: preferences.preferredLanguages.count + 
                          preferences.activeHours.count +
                          preferences.actionPreferences.count,
            primaryLanguagePair: preferences.preferredLanguages.first,
            mostActiveTime: preferences.activeHours.first,
            recentInsights: insights.count,
            lastUpdated: Date()
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func getCurrentAppContext() -> UserContext {
        // This would use NSWorkspace to get the current application
        // For now, return a mock context
        return UserContext(
            currentApp: getCurrentAppName(),
            currentWindow: getCurrentWindowTitle(),
            selectedText: getSelectedText()
        )
    }
    
    private func getCurrentAppName() -> String {
        // In a real implementation, this would use NSWorkspace
        return "com.apple.unknown" // Mock value
    }
    
    private func getCurrentWindowTitle() -> String? {
        // In a real implementation, this would use accessibility APIs
        return nil
    }
    
    private func getSelectedText() -> String? {
        // In a real implementation, this would use pasteboard or accessibility
        return nil
    }
    
    private func getTimeBasedPrediction() -> PredictedAction? {
        let currentHour = Calendar.current.component(.hour, from: Date())
        let preferences = habitManager.getLearnedPreferences()
        
        // Check if current hour is in user's active hours
        if preferences.activeHours.contains(currentHour) {
            // Return a prediction based on time of day
            let actionType: String
            let reason: String
            
            switch currentHour {
            case 6...11: // Morning
                actionType = "translation"
                reason = "您通常在上午进行翻译"
            case 12...17: // Afternoon
                actionType = "text_detection"
                reason = "您通常在下午进行文本检测"
            case 18...22: // Evening
                actionType = "knowledge_search"
                reason = "您通常在晚上搜索知识库"
            default: // Night
                actionType = "voice_recognition"
                reason = "您通常在夜间使用语音识别"
            }
            
            return PredictedAction(
                actionType: actionType,
                confidence: 0.7,
                reason: reason,
                context: getCurrentAppContext()
            )
        }
        
        return nil
    }
}

// MARK: - Supporting Structures

public struct HabitSummary {
    public let totalHabits: Int
    public let primaryLanguagePair: String?
    public let mostActiveTime: Int?
    public let recentInsights: Int
    public let lastUpdated: Date
    
    public init(totalHabits: Int, primaryLanguagePair: String?, mostActiveTime: Int?, recentInsights: Int, lastUpdated: Date) {
        self.totalHabits = totalHabits
        self.primaryLanguagePair = primaryLanguagePair
        self.mostActiveTime = mostActiveTime
        self.recentInsights = recentInsights
        self.lastUpdated = lastUpdated
    }
}