import Foundation
import NaturalLanguage

public class SmartTextDetector {
    public static let shared = SmartTextDetector()
    
    private init() {}
    
    // MARK: - Text Detection Types
    
    public enum TextType: String {
        case plain = "plain"
        case url = "url"
        case email = "email"
        case phoneNumber = "phoneNumber"
        case address = "address"
        case date = "date"
        case time = "time"
        case currency = "currency"
        case code = "code"
        case markdown = "markdown"
        case mixed = "mixed"
    }
    
    public struct TextDetectionResult {
        public let type: TextType
        public let confidence: Double
        public let language: String?
        public let entities: [TextEntity]
        public let suggestedActions: [SuggestedAction]
    }
    
    public struct TextEntity {
        public let type: EntityType
        public let value: String
        public let range: NSRange
        public let confidence: Double
    }
    
    public enum EntityType {
        case url
        case email
        case phoneNumber
        case streetAddress
        case city
        case state
        case postalCode
        case country
        case date
        case time
        case currency
        case percentage
        case measurement
        case personName
        case organizationName
        case keyword
        case codeSnippet
    }
    
    public struct SuggestedAction {
        public let type: ActionType
        public let title: String
        public let description: String
        public let priority: Int
    }
    
    public enum ActionType: String {
        case translate = "translate"
        case search = "search"
        case openUrl = "openUrl"
        case composeEmail = "composeEmail"
        case makeCall = "makeCall"
        case addToCalendar = "addToCalendar"
        case copyToClipboard = "copyToClipboard"
        case lookupDefinition = "lookupDefinition"
        case formatText = "formatText"
        case extractData = "extractData"
    }
    
    // MARK: - Main Detection Method
    
    public func detectTextType(in text: String) async -> TextDetectionResult {
        var entities: [TextEntity] = []
        var suggestedActions: [SuggestedAction] = []
        var textType: TextType = .plain
        var language: String?
        
        // Basic text analysis
        let (detectedLanguage, languageConfidence) = await detectLanguage(text)
        language = detectedLanguage
        
        // Detect various entities
        entities.append(contentsOf: detectURLs(in: text))
        entities.append(contentsOf: detectEmails(in: text))
        entities.append(contentsOf: detectPhoneNumbers(in: text))
        entities.append(contentsOf: detectDates(in: text))
        entities.append(contentsOf: detectCurrency(in: text))
        entities.append(contentsOf: detectAddresses(in: text))
        entities.append(contentsOf: detectCodeSnippets(in: text))
        entities.append(contentsOf: detectKeywords(in: text))
        
        // Determine overall text type
        textType = determineTextType(from: entities, text: text)
        
        // Generate suggested actions based on detected entities
        suggestedActions = generateSuggestedActions(for: textType, entities: entities, language: language)
        
        // Apply user preferences if available
        let habitService = UserHabitIntegrationService.shared
        let preferredActions = habitService.getPreferredActions(for: textType.rawValue)
        
        // Boost priority of preferred actions
        suggestedActions = suggestedActions.map { action in
            if preferredActions.contains(action.type.rawValue) {
                return SuggestedAction(
                    type: action.type,
                    title: action.title,
                    description: action.description,
                    priority: max(action.priority - 1, 1) // Higher priority
                )
            }
            return action
        }
        
        // Calculate overall confidence
        let confidence = calculateConfidence(entities: entities, languageConfidence: languageConfidence)
        
        return TextDetectionResult(
            type: textType,
            confidence: confidence,
            language: language,
            entities: entities,
            suggestedActions: suggestedActions
        )
    }
    
    // MARK: - Language Detection
    
    private func detectLanguage(_ text: String) async -> (String, Double) {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        let (language, confidence) = await withCheckedContinuation { continuation in
            Task {
                let results = recognizer.languageHypotheses(withMaximum: 1)
                if let (language, confidence) = results.first {
                    continuation.resume(returning: (language.rawValue, Double(confidence)))
                } else {
                    continuation.resume(returning: ("en", 0.5))
                }
            }
        }
        
        return (language, confidence)
    }
    
    // MARK: - Entity Detection Methods
    
    private func detectURLs(in text: String) -> [TextEntity] {
        let pattern = #"(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.)?[a-zA-Z0-9]+\.[^\s]{2,})"#
        return detectEntities(in: text, pattern: pattern, type: .url)
    }
    
    private func detectEmails(in text: String) -> [TextEntity] {
        let pattern = #"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"#
        return detectEntities(in: text, pattern: pattern, type: .email)
    }
    
    private func detectPhoneNumbers(in text: String) -> [TextEntity] {
        // International phone number patterns
        let patterns = [
            #"\+\d{1,3}[-.\s]?\(?\d{1,4}\)?[-.\s]?\d{1,4}[-.\s]?\d{1,4}[-.\s]?\d{1,9}"#, // International
            #"\d{3}[-.\s]?\d{3}[-.\s]?\d{4}"#, // US format
            #"\d{4}[-.\s]?\d{3}[-.\s]?\d{4}"#, // China format
        ]
        
        var entities: [TextEntity] = []
        for pattern in patterns {
            entities.append(contentsOf: detectEntities(in: text, pattern: pattern, type: .phoneNumber))
        }
        return entities
    }
    
    private func detectDates(in text: String) -> [TextEntity] {
        let patterns = [
            #"\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b"#, // MM/DD/YYYY or DD/MM/YYYY
            #"\b\d{4}[/-]\d{1,2}[/-]\d{1,2}\b"#, // YYYY-MM-DD
            #"\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]* \d{1,2},? \d{2,4}\b"#, // Month DD, YYYY
            #"\b\d{1,2} (?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]* \d{2,4}\b"#, // DD Month YYYY
        ]
        
        var entities: [TextEntity] = []
        for pattern in patterns {
            entities.append(contentsOf: detectEntities(in: text, pattern: pattern, type: .date))
        }
        return entities
    }
    
    private func detectCurrency(in text: String) -> [TextEntity] {
        let patterns = [
            #"\$\d+(?:,\d{3})*(?:\.\d{2})?"#, // USD
            #"€\d+(?:,\d{3})*(?:\.\d{2})?"#, // EUR
            #"£\d+(?:,\d{3})*(?:\.\d{2})?"#, // GBP
            #"¥\d+(?:,\d{3})*(?:\.\d{2})?"#, // JPY/CNY
            #"\d+(?:,\d{3})*(?:\.\d{2})?\s*(?:USD|EUR|GBP|JPY|CNY)"#, // Currency codes
        ]
        
        var entities: [TextEntity] = []
        for pattern in patterns {
            entities.append(contentsOf: detectEntities(in: text, pattern: pattern, type: .currency))
        }
        return entities
    }
    
    private func detectAddresses(in text: String) -> [TextEntity] {
        // Use Natural Language framework for address detection
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var entities: [TextEntity] = []
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            if let tag = tag, tag == .placeName {
                let nsRange = NSRange(tokenRange, in: text)
                entities.append(TextEntity(
                    type: .streetAddress,
                    value: String(text[tokenRange]),
                    range: nsRange,
                    confidence: 0.8
                ))
            }
            return true
        }
        
        return entities
    }
    
    private func detectCodeSnippets(in text: String) -> [TextEntity] {
        var entities: [TextEntity] = []
        
        // Detect code blocks (```code```)
        let codeBlockPattern = #"```[\s\S]*?```"#
        entities.append(contentsOf: detectEntities(in: text, pattern: codeBlockPattern, type: .codeSnippet))
        
        // Detect inline code (`code`)
        let inlineCodePattern = #"`[^`\n]+`"#
        entities.append(contentsOf: detectEntities(in: text, pattern: inlineCodePattern, type: .codeSnippet))
        
        // Detect programming keywords
        let programmingKeywords = [
            "function", "def", "class", "import", "return", "if", "else", "for", "while",
            "var", "let", "const", "int", "string", "bool", "array", "object"
        ]
        
        for keyword in programmingKeywords {
            let pattern = #"\b\#(keyword)\b"#
            let keywordEntities = detectEntities(in: text, pattern: pattern, type: .keyword)
            entities.append(contentsOf: keywordEntities)
        }
        
        return entities
    }
    
    private func detectKeywords(in text: String) -> [TextEntity] {
        // Common technical and business keywords
        let keywordPatterns = [
            #"\b(?:API|SDK|UI|UX|JSON|XML|HTML|CSS|JavaScript|Python|Java|Swift|Kotlin)\b"#,
            #"\b(?:meeting|conference|deadline|project|task|agenda|presentation)\b"#,
            #"\b(?:price|cost|budget|revenue|profit|loss|invoice|receipt)\b"#,
            #"\b(?:urgent|important ASAP|priority|critical|emergency)\b"#,
        ]
        
        var entities: [TextEntity] = []
        for pattern in keywordPatterns {
            entities.append(contentsOf: detectEntities(in: text, pattern: pattern, type: .keyword))
        }
        return entities
    }
    
    private func detectEntities(in text: String, pattern: String, type: EntityType) -> [TextEntity] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        return matches.map { match in
            TextEntity(
                type: type,
                value: nsString.substring(with: match.range),
                range: match.range,
                confidence: calculateEntityConfidence(type: type, text: nsString.substring(with: match.range))
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func determineTextType(from entities: [TextEntity], text: String) -> TextType {
        let entityCounts = Dictionary(grouping: entities, by: { $0.type })
            .mapValues { $0.count }
        
        // Check for specific patterns
        if entityCounts[.url] ?? 0 > 0 {
            return .url
        }
        if entityCounts[.email] ?? 0 > 0 {
            return .email
        }
        if entityCounts[.phoneNumber] ?? 0 > 0 {
            return .phoneNumber
        }
        if entityCounts[.codeSnippet] ?? 0 > 0 {
            return .code
        }
        if text.contains("#") || text.contains("*") || text.contains("`") {
            return .markdown
        }
        
        // Mixed type if multiple entity types present
        let uniqueTypes = Set(entities.map { $0.type })
        if uniqueTypes.count > 2 {
            return .mixed
        }
        
        return .plain
    }
    
    private func generateSuggestedActions(for textType: TextType, entities: [TextEntity], language: String?) -> [SuggestedAction] {
        var actions: [SuggestedAction] = []
        
        switch textType {
        case .url:
            actions.append(SuggestedAction(type: .openUrl, title: "打开链接", description: "在浏览器中打开此链接", priority: 1))
            
        case .email:
            actions.append(SuggestedAction(type: .composeEmail, title: "发送邮件", description: "创建新邮件", priority: 1))
            actions.append(SuggestedAction(type: .copyToClipboard, title: "复制邮箱", description: "复制邮箱地址", priority: 2))
            
        case .phoneNumber:
            actions.append(SuggestedAction(type: .makeCall, title: "拨打电话", description: "拨打此号码", priority: 1))
            actions.append(SuggestedAction(type: .copyToClipboard, title: "复制号码", description: "复制电话号码", priority: 2))
            
        case .address:
            actions.append(SuggestedAction(type: .search, title: "地图搜索", description: "在地图中搜索此地址", priority: 1))
            
        case .date, .time:
            actions.append(SuggestedAction(type: .addToCalendar, title: "添加到日历", description: "创建日历事件", priority: 1))
            
        case .currency:
            actions.append(SuggestedAction(type: .extractData, title: "汇率转换", description: "转换货币汇率", priority: 1))
            
        case .code:
            actions.append(SuggestedAction(type: .formatText, title: "格式化代码", description: "格式化代码片段", priority: 1))
            
        default:
            // Default actions for all text types
            actions.append(SuggestedAction(type: .translate, title: "翻译", description: "翻译此文本", priority: 1))
            actions.append(SuggestedAction(type: .search, title: "搜索", description: "在网络上搜索", priority: 2))
            actions.append(SuggestedAction(type: .copyToClipboard, title: "复制", description: "复制到剪贴板", priority: 3))
        }
        
        // Add entity-specific actions
        for entity in entities {
            switch entity.type {
            case .url:
                actions.append(SuggestedAction(type: .openUrl, title: "打开链接", description: "打开检测到的链接", priority: 1))
            case .email:
                actions.append(SuggestedAction(type: .composeEmail, title: "发送邮件", description: "发送邮件到此地址", priority: 1))
            case .phoneNumber:
                actions.append(SuggestedAction(type: .makeCall, title: "拨打电话", description: "拨打此电话号码", priority: 1))
            case .date:
                actions.append(SuggestedAction(type: .addToCalendar, title: "添加到日历", description: "添加日期到日历", priority: 1))
            default:
                break
            }
        }
        
        // Remove duplicates and sort by priority
        let uniqueActions = removeDuplicateActions(actions).sorted { $0.priority < $1.priority }
        return Array(uniqueActions.prefix(5)) // Limit to top 5 actions
    }
    
    private func removeDuplicateActions(_ actions: [SuggestedAction]) -> [SuggestedAction] {
        var uniqueActions: [SuggestedAction] = []
        var seenTypes: Set<ActionType> = []
        
        for action in actions {
            if !seenTypes.contains(action.type) {
                uniqueActions.append(action)
                seenTypes.insert(action.type)
            }
        }
        
        return uniqueActions
    }
    
    private func calculateEntityConfidence(type: EntityType, text: String) -> Double {
        var confidence = 0.5
        
        switch type {
        case .url:
            confidence = text.hasPrefix("http") ? 0.95 : 0.8
        case .email:
            confidence = text.contains("@") && text.contains(".") ? 0.9 : 0.7
        case .phoneNumber:
            confidence = text.count >= 10 ? 0.8 : 0.6
        case .date:
            confidence = text.count >= 6 ? 0.7 : 0.5
        case .currency:
            confidence = text.first?.isCurrencySymbol == true ? 0.8 : 0.6
        case .codeSnippet:
            confidence = text.contains("function") || text.contains("class") ? 0.9 : 0.7
        default:
            confidence = 0.6
        }
        
        return confidence
    }
    
    private func calculateConfidence(entities: [TextEntity], languageConfidence: Double) -> Double {
        let entityCount = entities.count
        let avgEntityConfidence = entities.isEmpty ? 0 : entities.reduce(0) { $0 + $1.confidence } / Double(entityCount)
        
        // Weighted confidence calculation
        let entityWeight = min(Double(entityCount) * 0.1, 0.5) // Max 0.5 for entities
        let languageWeight = languageConfidence * 0.3 // Max 0.3 for language
        let baseConfidence = 0.2 // Base confidence
        
        return min(baseConfidence + entityWeight + languageWeight + avgEntityConfidence * 0.2, 1.0)
    }
    
    // MARK: - Context-Aware Detection
    
    public func detectWithAppContext(_ text: String, appContext: AppContext) async -> TextDetectionResult {
        var result = await detectTextType(in: text)
        
        // Adjust detection based on app context
        var filteredActions: [SuggestedAction] = result.suggestedActions
        
        switch appContext.currentApp {
        case "com.apple.mail":
            // Mail app - prioritize email and address detection
            filteredActions = result.suggestedActions.filter { action in
                action.type == .composeEmail || action.type == .addToCalendar
            }
            
        case "com.apple.Safari":
            // Browser - prioritize URL and search actions
            filteredActions = result.suggestedActions.filter { action in
                action.type == .openUrl || action.type == .search
            }
            
        case "com.apple.calendar":
            // Calendar - prioritize date and time detection
            filteredActions = result.suggestedActions.filter { action in
                action.type == .addToCalendar
            }
            
        default:
            break
        }
        
        // Create new result with filtered actions
        return TextDetectionResult(
            type: result.type,
            confidence: result.confidence,
            language: result.language,
            entities: result.entities,
            suggestedActions: filteredActions
        )
    }
    
    // MARK: - Performance Optimization
    
    private let detectionCache = NSCache<NSString, CachedDetectionResult>()
    
    public func detectWithCache(_ text: String) async -> TextDetectionResult {
        let cacheKey = NSString(string: text)
        
        if let cachedResult = detectionCache.object(forKey: cacheKey) {
            return cachedResult.result
        }
        
        let result = await detectTextType(in: text)
        let cachedResult = CachedDetectionResult(result: result, timestamp: Date())
        detectionCache.setObject(cachedResult, forKey: cacheKey)
        
        return result
    }
}

// MARK: - Supporting Structures

public struct AppContext {
    public let currentApp: String
    public let currentWindow: String?
    public let selectedText: String?
    public let cursorPosition: Int?
    public let nearbyText: String?
    
    public init(currentApp: String, currentWindow: String? = nil, selectedText: String? = nil, cursorPosition: Int? = nil, nearbyText: String? = nil) {
        self.currentApp = currentApp
        self.currentWindow = currentWindow
        self.selectedText = selectedText
        self.cursorPosition = cursorPosition
        self.nearbyText = nearbyText
    }
}

// MARK: - Extensions

extension Character {
    var isCurrencySymbol: Bool {
        return self == "$" || self == "€" || self == "£" || self == "¥"
    }
}

extension Array {
    func toArray() -> [Element] {
        return self
    }
}

// MARK: - Cache Supporting Structures

class CachedDetectionResult: NSObject {
    let result: TextDetectionResult
    let timestamp: Date
    
    init(result: TextDetectionResult, timestamp: Date) {
        self.result = result
        self.timestamp = timestamp
    }
}