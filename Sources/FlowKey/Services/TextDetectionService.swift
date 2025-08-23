import Foundation
import AppKit

public class TextDetectionService {
    public static let shared = TextDetectionService()
    
    private init() {}
    
    // MARK: - Text Detection Integration
    
    private let smartTextDetector = SmartTextDetector.shared
    private let userHabitManager = UserHabitManager.shared
    
    public func detectAndProcessText(_ text: String, 
                                    context: AppContext? = nil) async -> TextProcessingResult {
        
        // Detect text type and entities
        let detectionResult = await smartTextDetector.detectTextType(in: text)
        
        // Apply user habits and preferences
        let enhancedResult = await applyUserHabits(to: detectionResult, text: text)
        
        // Generate contextual suggestions
        let suggestions = await generateContextualSuggestions(for: enhancedResult, context: context)
        
        // Record user interaction for learning
        await userHabitManager.recordTextDetection(
            text: text,
            result: enhancedResult,
            context: context
        )
        
        return TextProcessingResult(
            originalText: text,
            detectionResult: enhancedResult,
            suggestions: suggestions,
            processingTime: Date(),
            shouldAutoTranslate: shouldAutoTranslate(enhancedResult),
            shouldAutoFormat: shouldAutoFormat(enhancedResult)
        )
    }
    
    // MARK: - Auto-detection Logic
    
    private func shouldAutoTranslate(_ result: SmartTextDetector.TextDetectionResult) -> Bool {
        // Auto-translate if:
        // 1. Text is in a different language than user preference
        // 2. High confidence detection
        // 3. User has enabled auto-translate
        // 4. Text is not code or structured data
        
        let userLanguage = UserSettingsManager.shared.preferredLanguage
        guard let detectedLanguage = result.language,
              userLanguage != detectedLanguage else {
            return false
        }
        
        let isCodeOrStructured = result.type == .code || 
                               result.type == .url || 
                               result.type == .email
        
        return result.confidence > 0.8 && 
               !isCodeOrStructured &&
               UserSettingsManager.shared.autoTranslateEnabled
    }
    
    private func shouldAutoFormat(_ result: SmartTextDetector.TextDetectionResult) -> Bool {
        // Auto-format if:
        // 1. Code detected with low formatting quality
        // 2. Addresses detected that could be standardized
        // 3. Dates that could be reformatted
        
        switch result.type {
        case .code:
            return result.entities.contains { $0.type == .codeSnippet }
        case .address:
            return result.entities.contains { $0.type == .streetAddress }
        case .date:
            return result.entities.contains { $0.type == .date }
        default:
            return false
        }
    }
    
    // MARK: - User Habit Integration
    
    private func applyUserHabits(to result: SmartTextDetector.TextDetectionResult, 
                               text: String) async -> SmartTextDetector.TextDetectionResult {
        
        let habits = await userHabitManager.getRelevantHabits(for: text)
        
        var modifiedConfidence = result.confidence
        var modifiedActions = result.suggestedActions
        
        // Adjust confidence based on user patterns
        for habit in habits {
            switch habit.type {
            case .translation:
                if habit.details["language_preference"] as? String == result.language {
                    modifiedConfidence = min(modifiedConfidence + 0.1, 1.0)
                }
                
            case .action:
                if let preferredAction = habit.details["preferred_action"] as? String {
                    // Boost priority of preferred action
                    modifiedActions = modifiedActions.map { action in
                        if actionTypeToString(action.type) == preferredAction {
                            return SmartTextDetector.SuggestedAction(
                                type: action.type,
                                title: action.title,
                                description: action.description,
                                priority: max(action.priority - 1, 1) // Higher priority
                            )
                        }
                        return action
                    }
                }
                
            case .formatting:
                if habit.details["format_preference"] as? String == textTypeToString(result.type) {
                    // Apply formatting preferences
                    modifiedActions.append(
                        SmartTextDetector.SuggestedAction(
                            type: .formatText,
                            title: "按习惯格式化",
                            description: "根据您的使用习惯格式化文本",
                            priority: 1
                        )
                    )
                }
                
            case .search:
                // Handle search habits
                break
            }
        }
        
        // Create new result with modified values
        return SmartTextDetector.TextDetectionResult(
            type: result.type,
            confidence: modifiedConfidence,
            language: result.language,
            entities: result.entities,
            suggestedActions: modifiedActions
        )
    }
    
    // MARK: - Contextual Suggestions
    
    private func generateContextualSuggestions(for result: SmartTextDetector.TextDetectionResult,
                                             context: AppContext?) async -> [ContextualSuggestion] {
        
        guard let context = context else { return [] }
        
        var suggestions: [ContextualSuggestion] = []
        
        // App-specific suggestions
        switch context.currentApp {
        case "com.apple.mail":
            suggestions.append(contentsOf: generateMailSuggestions(result))
            
        case "com.apple.Safari":
            suggestions.append(contentsOf: generateBrowserSuggestions(result))
            
        case "com.apple.calendar":
            suggestions.append(contentsOf: generateCalendarSuggestions(result))
            
        case "com.apple.Notes":
            suggestions.append(contentsOf: generateNotesSuggestions(result))
            
        case "com.apple.finder":
            suggestions.append(contentsOf: generateFinderSuggestions(result))
            
        default:
            suggestions.append(contentsOf: generateGenericSuggestions(result))
        }
        
        // Time-based suggestions
        suggestions.append(contentsOf: generateTimeBasedSuggestions(result))
        
        // Location-based suggestions (if available)
        if let location = context.currentWindow {
            suggestions.append(contentsOf: generateLocationBasedSuggestions(result, location: location))
        }
        
        return Array(suggestions.sorted { $0.priority < $1.priority }.prefix(5))
    }
    
    // MARK: - App-specific Suggestion Generators
    
    private func generateMailSuggestions(_ result: SmartTextDetector.TextDetectionResult) -> [ContextualSuggestion] {
        var suggestions: [ContextualSuggestion] = []
        
        // Email composition suggestions
        if result.entities.contains(where: { $0.type == .email }) {
            suggestions.append(ContextualSuggestion(
                type: .composeEmail,
                title: "快速回复",
                description: "基于检测到的邮箱地址创建回复",
                priority: 1
            ))
        }
        
        // Date-based scheduling
        if result.entities.contains(where: { $0.type == .date }) {
            suggestions.append(ContextualSuggestion(
                type: .scheduleEmail,
                title: "定时发送",
                description: "安排邮件在检测到的日期发送",
                priority: 2
            ))
        }
        
        return suggestions
    }
    
    private func generateBrowserSuggestions(_ result: SmartTextDetector.TextDetectionResult) -> [ContextualSuggestion] {
        var suggestions: [ContextualSuggestion] = []
        
        // URL suggestions
        if result.entities.contains(where: { $0.type == .url }) {
            suggestions.append(ContextualSuggestion(
                type: .openInNewTab,
                title: "新标签页打开",
                description: "在新标签页中打开检测到的链接",
                priority: 1
            ))
        }
        
        // Search suggestions
        if result.type == .plain || result.type == .mixed {
            suggestions.append(ContextualSuggestion(
                type: .searchSelection,
                title: "搜索选中内容",
                description: "在搜索引擎中搜索此文本",
                priority: 2
            ))
        }
        
        return suggestions
    }
    
    private func generateCalendarSuggestions(_ result: SmartTextDetector.TextDetectionResult) -> [ContextualSuggestion] {
        var suggestions: [ContextualSuggestion] = []
        
        // Event creation
        if result.entities.contains(where: { $0.type == .date || $0.type == .time }) {
            suggestions.append(ContextualSuggestion(
                type: .createEvent,
                title: "创建日程",
                description: "基于检测到的日期时间创建事件",
                priority: 1
            ))
        }
        
        return suggestions
    }
    
    private func generateNotesSuggestions(_ result: SmartTextDetector.TextDetectionResult) -> [ContextualSuggestion] {
        var suggestions: [ContextualSuggestion] = []
        
        // Note organization
        if result.entities.contains(where: { $0.type == .keyword }) {
            suggestions.append(ContextualSuggestion(
                type: .tagNote,
                title: "添加标签",
                description: "基于检测到的关键词为笔记添加标签",
                priority: 1
            ))
        }
        
        // Code formatting
        if result.type == .code {
            suggestions.append(ContextualSuggestion(
                type: .formatCode,
                title: "格式化代码",
                description: "格式化检测到的代码片段",
                priority: 2
            ))
        }
        
        return suggestions
    }
    
    private func generateFinderSuggestions(_ result: SmartTextDetector.TextDetectionResult) -> [ContextualSuggestion] {
        var suggestions: [ContextualSuggestion] = []
        
        // File naming suggestions
        if result.entities.contains(where: { $0.type == .date }) {
            suggestions.append(ContextualSuggestion(
                type: .suggestFileName,
                title: "建议文件名",
                description: "基于日期生成文件名建议",
                priority: 1
            ))
        }
        
        return suggestions
    }
    
    private func generateGenericSuggestions(_ result: SmartTextDetector.TextDetectionResult) -> [ContextualSuggestion] {
        var suggestions: [ContextualSuggestion] = []
        
        // Translation suggestion
        if result.confidence > 0.7 {
            suggestions.append(ContextualSuggestion(
                type: .quickTranslate,
                title: "快速翻译",
                description: "翻译检测到的文本",
                priority: 1
            ))
        }
        
        // Copy suggestion
        suggestions.append(ContextualSuggestion(
            type: .smartCopy,
            title: "智能复制",
            description: "根据文本类型优化复制格式",
            priority: 2
        ))
        
        return suggestions
    }
    
    private func generateTimeBasedSuggestions(_ result: SmartTextDetector.TextDetectionResult) -> [ContextualSuggestion] {
        var suggestions: [ContextualSuggestion] = []
        
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Morning suggestions
        if hour >= 6 && hour < 12 {
            if result.entities.contains(where: { $0.type == .date }) {
                suggestions.append(ContextualSuggestion(
                    type: .scheduleMorning,
                    title: "安排到上午",
                    description: "将此事项安排到上午处理",
                    priority: 3
                ))
            }
        }
        
        // Evening suggestions
        if hour >= 18 && hour < 22 {
            if result.type == .plain {
                suggestions.append(ContextualSuggestion(
                    type: .eveningReview,
                    title: "晚间回顾",
                    description: "将此内容添加到晚间回顾清单",
                    priority: 3
                ))
            }
        }
        
        return suggestions
    }
    
    private func generateLocationBasedSuggestions(_ result: SmartTextDetector.TextDetectionResult, 
                                                 location: String) -> [ContextualSuggestion] {
        var suggestions: [ContextualSuggestion] = []
        
        // Location-specific suggestions
        if location.lowercased().contains("desktop") {
            suggestions.append(ContextualSuggestion(
                type: .saveToDesktop,
                title: "保存到桌面",
                description: "将此内容保存为桌面文件",
                priority: 2
            ))
        }
        
        if location.lowercased().contains("documents") {
            suggestions.append(ContextualSuggestion(
                type: .saveToDocuments,
                title: "保存到文档",
                description: "将此内容保存到文档文件夹",
                priority: 2
            ))
        }
        
        return suggestions
    }
    
    // MARK: - Helper Methods
    
    private func actionTypeToString(_ type: SmartTextDetector.ActionType) -> String {
        switch type {
        case .translate: return "translate"
        case .search: return "search"
        case .openUrl: return "openUrl"
        case .composeEmail: return "composeEmail"
        case .makeCall: return "makeCall"
        case .addToCalendar: return "addToCalendar"
        case .copyToClipboard: return "copyToClipboard"
        case .lookupDefinition: return "lookupDefinition"
        case .formatText: return "formatText"
        case .extractData: return "extractData"
        }
    }
    
    private func textTypeToString(_ type: SmartTextDetector.TextType) -> String {
        switch type {
        case .plain: return "plain"
        case .url: return "url"
        case .email: return "email"
        case .phoneNumber: return "phoneNumber"
        case .address: return "address"
        case .date: return "date"
        case .time: return "time"
        case .currency: return "currency"
        case .code: return "code"
        case .markdown: return "markdown"
        case .mixed: return "mixed"
        }
    }
}

// MARK: - Supporting Structures

public struct TextProcessingResult {
    public let originalText: String
    public let detectionResult: SmartTextDetector.TextDetectionResult
    public let suggestions: [ContextualSuggestion]
    public let processingTime: Date
    public let shouldAutoTranslate: Bool
    public let shouldAutoFormat: Bool
}

public struct ContextualSuggestion {
    public let type: SuggestionType
    public let title: String
    public let description: String
    public let priority: Int
}

public enum SuggestionType {
    case composeEmail
    case scheduleEmail
    case openInNewTab
    case searchSelection
    case createEvent
    case tagNote
    case formatCode
    case suggestFileName
    case quickTranslate
    case smartCopy
    case scheduleMorning
    case eveningReview
    case saveToDesktop
    case saveToDocuments
}

// MARK: - User Settings Manager

public class UserSettingsManager {
    public static let shared = UserSettingsManager()
    
    private init() {}
    
    public var preferredLanguage: String {
        get { UserDefaults.standard.string(forKey: "preferredLanguage") ?? "zh" }
        set { UserDefaults.standard.set(newValue, forKey: "preferredLanguage") }
    }
    
    public var autoTranslateEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "autoTranslateEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "autoTranslateEnabled") }
    }
    
    public var smartDetectionEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "smartDetectionEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "smartDetectionEnabled") }
    }
}

// MARK: - User Habit Manager

public class UserHabitManager {
    public static let shared = UserHabitManager()
    
    private init() {}
    
    public func recordTextDetection(text: String, 
                                  result: SmartTextDetector.TextDetectionResult,
                                  context: AppContext?) async {
        // Record user interaction for learning
        // This would integrate with Core Data to store habits
    }
    
    public func getRelevantHabits(for text: String) async -> [TextDetectionUserHabit] {
        // Return relevant user habits based on text content
        // This would query Core Data for matching habits
        return []
    }
}

public struct TextDetectionUserHabit {
    public let type: HabitType
    public let details: [String: Any]
    public let frequency: Int
    public let lastUsed: Date
}

public enum HabitType {
    case translation
    case action
    case formatting
    case search
}