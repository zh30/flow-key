import Foundation
import CoreData
import Combine

public class UserHabitManager {
    public static let shared = UserHabitManager()
    
    private init() {}
    
    // MARK: - Properties
    
    private let context = CoreDataManager.shared.viewContext
    private let habitAnalysisQueue = DispatchQueue(label: "com.flowkey.habit-analysis", qos: .userInitiated)
    
    // MARK: - Habit Types
    
    public enum HabitType: String, CaseIterable {
        case translation = "translation"
        case textDetection = "text_detection"
        case voiceRecognition = "voice_recognition"
        case knowledgeSearch = "knowledge_search"
        case shortcutUsage = "shortcut_usage"
        case formattingPreference = "formatting_preference"
        case languagePreference = "language_preference"
        case timePattern = "time_pattern"
        case appContext = "app_context"
        case textSelection = "text_selection"
        
        var displayName: String {
            switch self {
            case .translation: return "翻译习惯"
            case .textDetection: return "文本检测习惯"
            case .voiceRecognition: return "语音识别习惯"
            case .knowledgeSearch: return "知识搜索习惯"
            case .shortcutUsage: return "快捷键使用习惯"
            case .formattingPreference: return "格式化偏好"
            case .languagePreference: return "语言偏好"
            case .timePattern: return "时间模式"
            case .appContext: return "应用上下文习惯"
            case .textSelection: return "文本选择习惯"
            }
        }
    }
    
    public enum HabitPriority: Int, CaseIterable {
        case low = 1
        case medium = 2
        case high = 3
        case critical = 4
        
        var displayName: String {
            switch self {
            case .low: return "低"
            case .medium: return "中"
            case .high: return "高"
            case .critical: return "关键"
            }
        }
    }
    
    // MARK: - Habit Recording
    
    public func recordTranslationHabit(
        sourceText: String,
        targetText: String,
        sourceLanguage: String,
        targetLanguage: String,
        confidence: Double,
        context: String? = nil,
        appContext: String? = nil
    ) {
        habitAnalysisQueue.async {
            let habit = self.createOrUpdateHabit(
                type: .translation,
                details: [
                    "source_language": sourceLanguage,
                    "target_language": targetLanguage,
                    "text_length": sourceText.count,
                    "confidence": confidence,
                    "context": context ?? "",
                    "app_context": appContext ?? ""
                ]
            )
            
            // Analyze language preference
            self.analyzeLanguagePreference(sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
            
            // Analyze translation patterns
            self.analyzeTranslationPatterns(text: sourceText, result: targetText)
            
            self.saveContext()
        }
    }
    
    public func recordTextDetectionHabit(
        detectedText: String,
        textType: String,
        entities: [String],
        suggestedActions: [String],
        selectedAction: String?,
        confidence: Double,
        appContext: String? = nil
    ) {
        habitAnalysisQueue.async {
            let habit = self.createOrUpdateHabit(
                type: .textDetection,
                details: [
                    "text_type": textType,
                    "text_length": detectedText.count,
                    "entities": entities,
                    "suggested_actions": suggestedActions,
                    "selected_action": selectedAction ?? "",
                    "confidence": confidence,
                    "app_context": appContext ?? ""
                ]
            )
            
            // Analyze action preferences
            if let action = selectedAction {
                self.analyzeActionPreference(actionType: action, textType: textType)
            }
            
            self.saveContext()
        }
    }
    
    public func recordVoiceRecognitionHabit(
        audioDuration: TimeInterval,
        detectedText: String,
        confidence: Double,
        language: String?,
        context: String? = nil
    ) {
        habitAnalysisQueue.async {
            let habit = self.createOrUpdateHabit(
                type: .voiceRecognition,
                details: [
                    "audio_duration": audioDuration,
                    "text_length": detectedText.count,
                    "confidence": confidence,
                    "language": language ?? "",
                    "context": context ?? ""
                ]
            )
            
            self.saveContext()
        }
    }
    
    public func recordKnowledgeSearchHabit(
        query: String,
        resultsCount: Int,
        selectedDocument: String?,
        searchDuration: TimeInterval,
        context: String? = nil
    ) {
        habitAnalysisQueue.async {
            let habit = self.createOrUpdateHabit(
                type: .knowledgeSearch,
                details: [
                    "query_length": query.count,
                    "results_count": resultsCount,
                    "selected_document": selectedDocument ?? "",
                    "search_duration": searchDuration,
                    "context": context ?? ""
                ]
            )
            
            self.saveContext()
        }
    }
    
    public func recordShortcutUsage(
        shortcutType: String,
        triggerCount: Int,
        successRate: Double,
        context: String? = nil
    ) {
        habitAnalysisQueue.async {
            let habit = self.createOrUpdateHabit(
                type: .shortcutUsage,
                details: [
                    "shortcut_type": shortcutType,
                    "trigger_count": triggerCount,
                    "success_rate": successRate,
                    "context": context ?? ""
                ]
            )
            
            self.saveContext()
        }
    }
    
    public func recordAppContextUsage(
        appName: String,
        windowTitle: String?,
        actionsPerformed: [String],
        duration: TimeInterval
    ) {
        habitAnalysisQueue.async {
            let habit = self.createOrUpdateHabit(
                type: .appContext,
                details: [
                    "app_name": appName,
                    "window_title": windowTitle ?? "",
                    "actions_performed": actionsPerformed,
                    "duration": duration
                ]
            )
            
            self.saveContext()
        }
    }
    
    public func recordTimePattern(
        actionType: String,
        timestamp: Date = Date(),
        duration: TimeInterval? = nil
    ) {
        habitAnalysisQueue.async {
            let hour = Calendar.current.component(.hour, from: timestamp)
            let dayOfWeek = Calendar.current.component(.weekday, from: timestamp)
            
            let habit = self.createOrUpdateHabit(
                type: .timePattern,
                details: [
                    "action_type": actionType,
                    "hour": hour,
                    "day_of_week": dayOfWeek,
                    "duration": duration ?? 0
                ]
            )
            
            self.saveContext()
        }
    }
    
    // MARK: - Habit Analysis
    
    public func getLearnedPreferences() -> UserPreferences {
        var preferences = UserPreferences()
        
        habitAnalysisQueue.sync {
            // Analyze language preferences
            preferences.preferredLanguages = analyzePreferredLanguages()
            
            // Analyze translation patterns
            preferences.translationPatterns = analyzeTranslationPatterns()
            
            // Analyze action preferences
            preferences.actionPreferences = analyzeActionPreferences()
            
            // Analyze time patterns
            preferences.activeHours = analyzeActiveHours()
            
            // Analyze app context preferences
            preferences.appContextPreferences = analyzeAppContextPreferences()
        }
        
        return preferences
    }
    
    public func predictUserAction(context: UserContext) -> PredictedAction? {
        return habitAnalysisQueue.sync {
            // Predict based on app context
            if let appPrediction = predictBasedOnAppContext(context) {
                return appPrediction
            }
            
            // Predict based on time patterns
            if let timePrediction = predictBasedOnTimePatterns() {
                return timePrediction
            }
            
            // Predict based on general habits
            return predictBasedOnGeneralHabits()
        }
    }
    
    public func getHabitInsights() -> [HabitInsight] {
        return habitAnalysisQueue.sync {
            var insights: [HabitInsight] = []
            
            // Translation insights
            insights.append(contentsOf: analyzeTranslationInsights())
            
            // Time pattern insights
            insights.append(contentsOf: analyzeTimePatternInsights())
            
            // App context insights
            insights.append(contentsOf: analyzeAppContextInsights())
            
            // Action preference insights
            insights.append(contentsOf: analyzeActionPreferenceInsights())
            
            return insights.sorted { $0.priority.rawValue > $1.priority.rawValue }
        }
    }
    
    // MARK: - Private Methods
    
    private func createOrUpdateHabit(type: HabitType, details: [String: Any]) -> UserHabit? {
        let request: NSFetchRequest<UserHabit> = UserHabit.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@", type.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "lastUsed", ascending: false)]
        request.fetchLimit = 1
        
        do {
            let existingHabits = try context.fetch(request)
            
            if let existingHabit = existingHabits.first {
                // Update existing habit
                existingHabit.frequency += 1
                existingHabit.lastUsed = Date()
                existingHabit.details = mergeDetails(existingHabit.details, newDetails: details)
                return existingHabit
            } else {
                // Create new habit
                let newHabit = UserHabit(context: context)
                newHabit.id = UUID()
                newHabit.type = type.rawValue
                newHabit.details = details
                newHabit.frequency = 1
                newHabit.lastUsed = Date()
                newHabit.createdAt = Date()
                return newHabit
            }
        } catch {
            print("Error creating/updating habit: \(error)")
            return nil
        }
    }
    
    private func mergeDetails(_ existing: [String: Any], newDetails: [String: Any]) -> [String: Any] {
        var merged = existing
        
        for (key, value) in newDetails {
            if let existingValue = merged[key] {
                // Handle numeric values (accumulate)
                if let existingNum = existingValue as? Int, let newNum = value as? Int {
                    merged[key] = existingNum + newNum
                } else if let existingNum = existingValue as? Double, let newNum = value as? Double {
                    merged[key] = existingNum + newNum
                } else {
                    // Replace non-numeric values
                    merged[key] = value
                }
            } else {
                merged[key] = value
            }
        }
        
        return merged
    }
    
    private func analyzeLanguagePreference(sourceLanguage: String, targetLanguage: String) {
        let languagePair = "\(sourceLanguage)_\(targetLanguage)"
        
        _ = createOrUpdateHabit(
            type: .languagePreference,
            details: [
                "language_pair": languagePair,
                "source_language": sourceLanguage,
                "target_language": targetLanguage,
                "usage_count": 1
            ]
        )
    }
    
    private func analyzeTranslationPatterns(text: String, result: String) {
        // Analyze text length patterns
        let textLength = text.count
        let lengthCategory = categorizeTextLength(textLength)
        
        _ = createOrUpdateHabit(
            type: .translation,
            details: [
                "length_category": lengthCategory,
                "length_usage": 1
            ]
        )
    }
    
    private func analyzeActionPreference(actionType: String, textType: String) {
        _ = createOrUpdateHabit(
            type: .formattingPreference,
            details: [
                "action_type": actionType,
                "text_type": textType,
                "usage_count": 1
            ]
        )
    }
    
    private func categorizeTextLength(_ length: Int) -> String {
        switch length {
        case 0...20: return "short"
        case 21...100: return "medium"
        case 101...500: return "long"
        default: return "very_long"
        }
    }
    
    private func analyzePreferredLanguages() -> [String] {
        let request: NSFetchRequest<UserHabit> = UserHabit.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@", HabitType.languagePreference.rawValue)
        
        do {
            let habits = try context.fetch(request)
            let languagePairs = habits.compactMap { $0.details["language_pair"] as? String }
            
            // Count frequency and return top languages
            let frequency = Dictionary(grouping: languagePairs, by: { $0 })
                .mapValues { $0.count }
            
            return frequency.sorted { $0.value > $1.value }
                .prefix(3)
                .map { $0.key }
        } catch {
            return []
        }
    }
    
    private func analyzeTranslationPatterns() -> [String: Any] {
        return [:]
    }
    
    private func analyzeActionPreferences() -> [String: Any] {
        return [:]
    }
    
    private func analyzeActiveHours() -> [Int] {
        return []
    }
    
    private func analyzeAppContextPreferences() -> [String: Any] {
        return [:]
    }
    
    private func predictBasedOnAppContext(_ context: UserContext) -> PredictedAction? {
        return nil
    }
    
    private func predictBasedOnTimePatterns() -> PredictedAction? {
        return nil
    }
    
    private func predictBasedOnGeneralHabits() -> PredictedAction? {
        return nil
    }
    
    private func analyzeTranslationInsights() -> [HabitInsight] {
        return []
    }
    
    private func analyzeTimePatternInsights() -> [HabitInsight] {
        return []
    }
    
    private func analyzeAppContextInsights() -> [HabitInsight] {
        return []
    }
    
    private func analyzeActionPreferenceInsights() -> [HabitInsight] {
        return []
    }
    
    private func saveContext() {
        DispatchQueue.main.async {
            do {
                try self.context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    // MARK: - Initialization
    
    public func initialize() {
        // Perform any necessary initialization
        print("User habit manager initialized")
    }
    
    public func clearAllHabits() {
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "UserHabit")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print("Error clearing habits: \(error)")
        }
    }
}

// MARK: - Supporting Structures

public struct UserPreferences {
    public var preferredLanguages: [String] = []
    public var translationPatterns: [String: Any] = [:]
    public var actionPreferences: [String: Any] = [:]
    public var activeHours: [Int] = []
    public var appContextPreferences: [String: Any] = [:]
    
    // Translation Quality Optimization Preferences
    public var optimizationEnabled: Bool? = nil
    public var autoOptimize: Bool? = nil
    public var optimizationStrategy: Int? = nil
    public var minimumConfidence: Double? = nil
    public var optimizationThreshold: Double? = nil
    public var qualityFeedbackEnabled: Bool? = nil
    
    public init() {}
}

public struct UserContext {
    public let currentApp: String
    public let currentWindow: String?
    public let selectedText: String?
    public let timeOfDay: Int
    public let dayOfWeek: Int
    
    public init(currentApp: String, currentWindow: String? = nil, selectedText: String? = nil) {
        self.currentApp = currentApp
        self.currentWindow = currentWindow
        self.selectedText = selectedText
        
        let now = Date()
        self.timeOfDay = Calendar.current.component(.hour, from: now)
        self.dayOfWeek = Calendar.current.component(.weekday, from: now)
    }
}

public struct PredictedAction {
    public let actionType: String
    public let confidence: Double
    public let reason: String
    public let context: UserContext
    
    public init(actionType: String, confidence: Double, reason: String, context: UserContext) {
        self.actionType = actionType
        self.confidence = confidence
        self.reason = reason
        self.context = context
    }
}

public struct HabitInsight {
    public let type: String
    public let title: String
    public let description: String
    public let priority: HabitPriority
    public let data: [String: Any]
    public let timestamp: Date
    
    public init(type: String, title: String, description: String, priority: HabitPriority, data: [String: Any]) {
        self.type = type
        self.title = title
        self.description = description
        self.priority = priority
        self.data = data
        self.timestamp = Date()
    }
}