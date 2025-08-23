import Foundation

public class TextStyleConversionService: ObservableObject {
    public static let shared = TextStyleConversionService()
    
    private init() {
        // Initialize style patterns and rules
        initializeStylePatterns()
    }
    
    // MARK: - Initialization
    
    public func initialize() async {
        // Pre-load style patterns and models
        await loadStyleModels()
        print("Text style conversion service initialized")
    }
    
    private func initializeStylePatterns() {
        // Initialize style-specific patterns and rules
        // This would typically load from configuration files or databases
    }
    
    private func loadStyleModels() async {
        // Load ML models for style analysis and conversion
        // In production, this would load actual ML models
        try? await Task.sleep(nanoseconds: 100_000_000) // Simulate model loading
    }
    
    // MARK: - Style Types
    
    public enum TextStyle: String, CaseIterable {
        case formal = "formal"
        case casual = "casual"
        case academic = "academic"
        case business = "business"
        case creative = "creative"
        case technical = "technical"
        case friendly = "friendly"
        case professional = "professional"
        case persuasive = "persuasive"
        case narrative = "narrative"
        
        var displayName: String {
            switch self {
            case .formal: return "正式"
            case .casual: return "休闲"
            case .academic: return "学术"
            case .business: return "商务"
            case .creative: return "创意"
            case .technical: return "技术"
            case .friendly: return "友好"
            case .professional: return "专业"
            case .persuasive: return "说服性"
            case .narrative: return "叙述性"
            }
        }
        
        var description: String {
            switch self {
            case .formal: return "正式、礼貌、专业的语言风格"
            case .casual: return "轻松、随意、自然的语言风格"
            case .academic: return "严谨、客观、引用规范的语言风格"
            case .business: return "商务、专业、结果导向的语言风格"
            case .creative: return "富有想象力、生动、独特的语言风格"
            case .technical: return "精确、专业、术语规范的语言风格"
            case .friendly: return "亲切、热情、平易近人的语言风格"
            case .professional: return "专业、可信、权威的语言风格"
            case .persuasive: return "有说服力、感染力、行动导向的语言风格"
            case .narrative: return "故事性、描述性、情节连贯的语言风格"
            }
        }
        
        var icon: String {
            switch self {
            case .formal: return "building.columns"
            case .casual: return "face.smiling"
            case .academic: return "graduationcap"
            case .business: return "briefcase"
            case .creative: return "paintbrush"
            case .technical: return "gear"
            case .friendly: return "hand.wave"
            case .professional: return "person.suit"
            case .persuasive: return "megaphone"
            case .narrative: return "book"
            }
        }
        
        var color: String {
            switch self {
            case .formal: return "#2C3E50"
            case .casual: return "#E74C3C"
            case .academic: return "#8E44AD"
            case .business: return "#3498DB"
            case .creative: return "#E67E22"
            case .technical: return "#95A5A6"
            case .friendly: return "#27AE60"
            case .professional: return "#34495E"
            case .persuasive: return "#F39C12"
            case .narrative: return "#16A085"
            }
        }
    }
    
    // MARK: - Conversion Options
    
    public struct ConversionOptions {
        public let targetStyle: TextStyle
        public let preserveOriginalMeaning: Bool
        public let adaptToContext: Bool
        public let maintainTone: Bool
        public let applyGrammarRules: Bool
        public let useAdvancedVocabulary: Bool
        public let customInstructions: String?
        
        public init(
            targetStyle: TextStyle,
            preserveOriginalMeaning: Bool = true,
            adaptToContext: Bool = true,
            maintainTone: Bool = false,
            applyGrammarRules: Bool = true,
            useAdvancedVocabulary: Bool = false,
            customInstructions: String? = nil
        ) {
            self.targetStyle = targetStyle
            self.preserveOriginalMeaning = preserveOriginalMeaning
            self.adaptToContext = adaptToContext
            self.maintainTone = maintainTone
            self.applyGrammarRules = applyGrammarRules
            self.useAdvancedVocabulary = useAdvancedVocabulary
            self.customInstructions = customInstructions
        }
    }
    
    // MARK: - Conversion Result
    
    public struct ConversionResult {
        public let originalText: String
        public let convertedText: String
        public let targetStyle: TextStyle
        public let confidence: Double
        public let changes: [TextChange]
        public let suggestions: [String]
        public let processingTime: TimeInterval
        
        public init(
            originalText: String,
            convertedText: String,
            targetStyle: TextStyle,
            confidence: Double,
            changes: [TextChange],
            suggestions: [String],
            processingTime: TimeInterval
        ) {
            self.originalText = originalText
            self.convertedText = convertedText
            self.targetStyle = targetStyle
            self.confidence = confidence
            self.changes = changes
            self.suggestions = suggestions
            self.processingTime = processingTime
        }
    }
    
    public struct TextChange {
        public let type: ChangeType
        public let original: String
        public let replacement: String
        public let position: NSRange
        public let reason: String
        
        public init(type: ChangeType, original: String, replacement: String, position: NSRange, reason: String) {
            self.type = type
            self.original = original
            self.replacement = replacement
            self.position = position
            self.reason = reason
        }
    }
    
    public enum ChangeType {
        case vocabulary
        case grammar
        case tone
        case structure
        case formality
        case punctuation
        case spelling
    }
    
    // MARK: - Style Analysis
    
    public struct StyleAnalysis {
        public let detectedStyle: TextStyle
        public let confidence: Double
        public let characteristics: [StyleCharacteristic]
        public let readabilityScore: Double
        public let complexityScore: Double
        public let formalityScore: Double
        
        public init(
            detectedStyle: TextStyle,
            confidence: Double,
            characteristics: [StyleCharacteristic],
            readabilityScore: Double,
            complexityScore: Double,
            formalityScore: Double
        ) {
            self.detectedStyle = detectedStyle
            self.confidence = confidence
            self.characteristics = characteristics
            self.readabilityScore = readabilityScore
            self.complexityScore = complexityScore
            self.formalityScore = formalityScore
        }
    }
    
    public struct StyleCharacteristic {
        public let name: String
        public let value: Double
        public let description: String
        
        public init(name: String, value: Double, description: String) {
            self.name = name
            self.value = value
            self.description = description
        }
    }
    
    // MARK: - Main Conversion Methods
    
    public func convertText(_ text: String, to style: TextStyle, options: ConversionOptions? = nil) async throws -> ConversionResult {
        let startTime = Date()
        
        // Use default options if none provided
        let conversionOptions = options ?? ConversionOptions(targetStyle: style)
        
        // Analyze original text style
        let analysis = await analyzeTextStyle(text)
        
        // Perform the conversion
        let convertedText = try await performConversion(text: text, 
                                                      from: analysis.detectedStyle, 
                                                      to: style, 
                                                      options: conversionOptions)
        
        // Identify changes made
        let changes = identifyChanges(original: text, converted: convertedText)
        
        // Generate suggestions
        let suggestions = generateSuggestions(text: convertedText, style: style)
        
        // Calculate confidence
        let confidence = calculateConfidence(analysis: analysis, conversionQuality: changes.count)
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        return ConversionResult(
            originalText: text,
            convertedText: convertedText,
            targetStyle: style,
            confidence: confidence,
            changes: changes,
            suggestions: suggestions,
            processingTime: processingTime
        )
    }
    
    public func analyzeTextStyle(_ text: String) async -> StyleAnalysis {
        // Mock style analysis - in production, this would use ML models
        let characteristics = analyzeCharacteristics(text)
        
        let detectedStyle = determineStyle(from: characteristics)
        let confidence = calculateStyleConfidence(characteristics: characteristics)
        let readabilityScore = calculateReadabilityScore(text)
        let complexityScore = calculateComplexityScore(text)
        let formalityScore = calculateFormalityScore(text)
        
        return StyleAnalysis(
            detectedStyle: detectedStyle,
            confidence: confidence,
            characteristics: characteristics,
            readabilityScore: readabilityScore,
            complexityScore: complexityScore,
            formalityScore: formalityScore
        )
    }
    
    public func getStyleRecommendations(for text: String) async -> [StyleRecommendation] {
        let analysis = await analyzeTextStyle(text)
        
        var recommendations: [StyleRecommendation] = []
        
        // Recommend styles based on current style
        switch analysis.detectedStyle {
        case .casual:
            recommendations.append(StyleRecommendation(
                style: .business,
                reason: "将休闲风格转换为商务风格，更适合专业场合",
                confidence: 0.8
            ))
            recommendations.append(StyleRecommendation(
                style: .formal,
                reason: "提升文本的正式程度，增加专业性",
                confidence: 0.7
            ))
        case .formal:
            recommendations.append(StyleRecommendation(
                style: .friendly,
                reason: "让正式文本更加亲切友好",
                confidence: 0.8
            ))
            recommendations.append(StyleRecommendation(
                style: .casual,
                reason: "降低正式程度，使文本更加自然",
                confidence: 0.6
            ))
        case .technical:
            recommendations.append(StyleRecommendation(
                style: .narrative,
                reason: "将技术内容转化为更容易理解的叙述形式",
                confidence: 0.7
            ))
        default:
            recommendations.append(StyleRecommendation(
                style: .professional,
                reason: "提升文本的专业性和可信度",
                confidence: 0.75
            ))
        }
        
        // Add context-based recommendations
        if analysis.formalityScore < 0.3 {
            recommendations.append(StyleRecommendation(
                style: .formal,
                reason: "当前文本过于随意，建议提升正式程度",
                confidence: 0.9
            ))
        }
        
        if analysis.readabilityScore < 0.4 {
            recommendations.append(StyleRecommendation(
                style: .casual,
                reason: "文本可读性较低，建议简化语言",
                confidence: 0.8
            ))
        }
        
        return recommendations.sorted { $0.confidence > $1.confidence }
    }
    
    // MARK: - Batch Processing
    
    public func batchConvertTexts(_ texts: [String], to style: TextStyle, options: ConversionOptions? = nil) async throws -> [ConversionResult] {
        let conversionOptions = options ?? ConversionOptions(targetStyle: style)
        
        var results: [ConversionResult] = []
        
        // Process texts in batches to avoid overwhelming the system
        let batchSize = 5
        for i in stride(from: 0, to: texts.count, by: batchSize) {
            let batch = Array(texts[i..<min(i + batchSize, texts.count)])
            let batchResults = try await withThrowingTaskGroup(of: ConversionResult.self) { group in
                for text in batch {
                    group.addTask { [self] in
                        try await convertText(text, to: style, options: conversionOptions)
                    }
                }
                
                var batchResults: [ConversionResult] = []
                for try await result in group {
                    batchResults.append(result)
                }
                return batchResults
            }
            
            results.append(contentsOf: batchResults)
        }
        
        return results
    }
    
    // MARK: - Private Methods
    
    private func performConversion(text: String, from fromStyle: TextStyle, to toStyle: TextStyle, options: ConversionOptions) async throws -> String {
        // Mock conversion - in production, this would use sophisticated ML models
        try await Task.sleep(nanoseconds: 500_000_000) // Simulate processing time
        
        var convertedText = text
        
        // Apply style-specific transformations
        switch toStyle {
        case .formal:
            convertedText = applyFormalStyle(convertedText)
        case .casual:
            convertedText = applyCasualStyle(convertedText)
        case .academic:
            convertedText = applyAcademicStyle(convertedText)
        case .business:
            convertedText = applyBusinessStyle(convertedText)
        case .creative:
            convertedText = applyCreativeStyle(convertedText)
        case .technical:
            convertedText = applyTechnicalStyle(convertedText)
        case .friendly:
            convertedText = applyFriendlyStyle(convertedText)
        case .professional:
            convertedText = applyProfessionalStyle(convertedText)
        case .persuasive:
            convertedText = applyPersuasiveStyle(convertedText)
        case .narrative:
            convertedText = applyNarrativeStyle(convertedText)
        }
        
        // Apply custom instructions if provided
        if let customInstructions = options.customInstructions {
            convertedText = applyCustomInstructions(convertedText, customInstructions)
        }
        
        return convertedText
    }
    
    // MARK: - Style Application Methods
    
    private func applyFormalStyle(_ text: String) -> String {
        var result = text
        
        // Replace informal contractions
        let contractions = [
            "don't": "do not",
            "can't": "cannot",
            "won't": "will not",
            "shouldn't": "should not",
            "wouldn't": "would not",
            "couldn't": "could not",
            "isn't": "is not",
            "aren't": "are not",
            "wasn't": "was not",
            "weren't": "were not",
            "haven't": "have not",
            "hasn't": "has not",
            "hadn't": "had not"
        ]
        
        for (informal, formal) in contractions {
            result = result.replacingOccurrences(of: informal, with: formal, options: .caseInsensitive)
        }
        
        // Replace informal words with formal alternatives
        let informalWords = [
            "get": "obtain",
            "got": "received",
            "good": "excellent",
            "bad": "unsatisfactory",
            "big": "substantial",
            "small": "minimal",
            "lots of": "numerous",
            "a lot of": "considerable",
            "think": "believe",
            "want": "desire",
            "need": "require",
            "show": "demonstrate",
            "tell": "inform",
            "ask": "inquire"
        ]
        
        for (informal, formal) in informalWords {
            result = result.replacingOccurrences(of: informal, with: formal, options: .caseInsensitive)
        }
        
        return result
    }
    
    private func applyCasualStyle(_ text: String) -> String {
        var result = text
        
        // Replace formal words with casual alternatives
        let formalWords = [
            "therefore": "so",
            "however": "but",
            "consequently": "so",
            "furthermore": "also",
            "moreover": "plus",
            "nevertheless": "still",
            "utilize": "use",
            "assist": "help",
            "commence": "start",
            "terminate": "end",
            "sufficient": "enough",
            "approximately": "about",
            "subsequently": "after",
            "additional": "more",
            "numerous": "many",
            "demonstrate": "show",
            "inform": "tell",
            "inquire": "ask"
        ]
        
        for (formal, casual) in formalWords {
            result = result.replacingOccurrences(of: formal, with: casual, options: .caseInsensitive)
        }
        
        return result
    }
    
    private func applyAcademicStyle(_ text: String) -> String {
        var result = text
        
        // Add academic phrasing and precision
        let academicPatterns = [
            (NSRegularExpression("(?i)\\b(this)\\b"), "The aforementioned"),
            (NSRegularExpression("(?i)\\b(that)\\b"), "which"),
            (NSRegularExpression("(?i)\\b(very)\\b"), "extremely"),
            (NSRegularExpression("(?i)\\b(really)\\b"), "significantly"),
            (NSRegularExpression("(?i)\\b(get)\\b"), "obtain"),
            (NSRegularExpression("(?i)\\b(show)\\b"), "demonstrate"),
            (NSRegularExpression("(?i)\\b(tell)\\b"), "indicate")
        ]
        
        for (pattern, replacement) in academicPatterns {
            result = pattern.stringByReplacingMatches(in: result, options: [], range: NSRange(location: 0, length: result.utf16.count), withTemplate: replacement)
        }
        
        return result
    }
    
    private func applyBusinessStyle(_ text: String) -> String {
        var result = text
        
        // Add business terminology and professional tone
        let businessTerms = [
            "problem": "challenge",
            "issue": "opportunity",
            "cost": "investment",
            "spend": "allocate resources",
            "buy": "procure",
            "sell": "provide solutions",
            "customer": "client",
            "user": "stakeholder",
            "team": "cross-functional team",
            "work": "deliverables",
            "project": "initiative",
            "goal": "objective",
            "plan": "strategy",
            "meeting": "alignment session",
            "report": "status update"
        ]
        
        for (general, business) in businessTerms {
            result = result.replacingOccurrences(of: general, with: business, options: .caseInsensitive)
        }
        
        return result
    }
    
    private func applyCreativeStyle(_ text: String) -> String {
        var result = text
        
        // Add creative and descriptive language
        let creativeEnhancements = [
            "good": "exceptional",
            "bad": "disastrous",
            "beautiful": "breathtaking",
            "ugly": "hideous",
            "big": "massive",
            "small": "tiny",
            "fast": "lightning-fast",
            "slow": "sluggish",
            "important": "crucial",
            "interesting": "fascinating",
            "boring": "tedious",
            "easy": "effortless",
            "hard": "challenging"
        ]
        
        for (plain, creative) in creativeEnhancements {
            result = result.replacingOccurrences(of: plain, with: creative, options: .caseInsensitive)
        }
        
        return result
    }
    
    private func applyTechnicalStyle(_ text: String) -> String {
        var result = text
        
        // Add technical precision and terminology
        let technicalTerms = [
            "use": "utilize",
            "make": "implement",
            "do": "execute",
            "run": "execute",
            "show": "display",
            "get": "retrieve",
            "set": "configure",
            "change": "modify",
            "fix": "resolve",
            "break": "compromise",
            "start": "initialize",
            "stop": "terminate",
            "end": "conclude",
            "test": "validate",
            "check": "verify",
            "find": "locate",
            "help": "assist",
            "work": "function"
        ]
        
        for (general, technical) in technicalTerms {
            result = result.replacingOccurrences(of: general, with: technical, options: .caseInsensitive)
        }
        
        return result
    }
    
    private func applyFriendlyStyle(_ text: String) -> String {
        var result = text
        
        // Add friendly and approachable language
        let friendlyPhrases = [
            "I think": "I feel",
            "You should": "You might want to",
            "We need to": "Let's",
            "It is important to": "It's great to",
            "Please": "Could you please",
            "Thank you": "Thanks so much",
            "Hello": "Hi there",
            "Goodbye": "Take care"
        ]
        
        for (formal, friendly) in friendlyPhrases {
            result = result.replacingOccurrences(of: formal, with: friendly, options: .caseInsensitive)
        }
        
        return result
    }
    
    private func applyProfessionalStyle(_ text: String) -> String {
        var result = text
        
        // Add professional and authoritative language
        let professionalTerms = [
            "I think": "Based on my analysis",
            "You should": "I recommend",
            "We need to": "It is recommended that we",
            "This is": "This represents",
            "That is": "That indicates",
            "Good": "Effective",
            "Bad": "Ineffective",
            "Problem": "Challenge",
            "Solution": "Resolution",
            "Help": "Support",
            "Work": "Professional engagement"
        ]
        
        for (general, professional) in professionalTerms {
            result = result.replacingOccurrences(of: general, with: professional, options: .caseInsensitive)
        }
        
        return result
    }
    
    private func applyPersuasiveStyle(_ text: String) -> String {
        var result = text
        
        // Add persuasive and action-oriented language
        let persuasivePhrases = [
            "This is": "This powerful",
            "You can": "You'll discover how to",
            "We offer": "We're excited to offer",
            "Good": "Outstanding",
            "Better": "Superior",
            "Best": "Unmatched",
            "Help": "Empower",
            "Solve": "Transform",
            "Create": "Build something amazing",
            "Learn": "Master",
            "Understand": "Gain deep insights into"
        ]
        
        for (neutral, persuasive) in persuasivePhrases {
            result = result.replacingOccurrences(of: neutral, with: persuasive, options: .caseInsensitive)
        }
        
        return result
    }
    
    private func applyNarrativeStyle(_ text: String) -> String {
        var result = text
        
        // Add narrative and storytelling elements
        let narrativeElements = [
            "This happened": "The story unfolds as",
            "I saw": "I witnessed",
            "We did": "Our journey began when",
            "It was": "In that moment, it became",
            "There was": "Standing before us was",
            "They said": "Their words echoed",
            "We went": "We ventured forth",
            "I found": "I discovered",
            "We learned": "The lesson we learned was"
        ]
        
        for (factual, narrative) in narrativeElements {
            result = result.replacingOccurrences(of: factual, with: narrative, options: .caseInsensitive)
        }
        
        return result
    }
    
    private func applyCustomInstructions(_ text: String, _ instructions: String) -> String {
        // Apply custom transformations based on user instructions
        // This is a simplified version - in production, this would use NLP
        var result = text
        
        let lowerInstructions = instructions.lowercased()
        
        if lowerInstructions.contains("更正式") || lowerInstructions.contains("more formal") {
            result = applyFormalStyle(result)
        }
        
        if lowerInstructions.contains("更友好") || lowerInstructions.contains("more friendly") {
            result = applyFriendlyStyle(result)
        }
        
        if lowerInstructions.contains("更专业") || lowerInstructions.contains("more professional") {
            result = applyProfessionalStyle(result)
        }
        
        return result
    }
    
    // MARK: - Analysis Methods
    
    private func analyzeCharacteristics(_ text: String) -> [StyleCharacteristic] {
        var characteristics: [StyleCharacteristic] = []
        
        // Analyze various text characteristics
        characteristics.append(StyleCharacteristic(
            name: "句子长度",
            value: calculateAverageSentenceLength(text),
            description: "句子的平均长度"
        ))
        
        characteristics.append(StyleCharacteristic(
            name: "词汇复杂度",
            value: calculateVocabularyComplexity(text),
            description: "词汇的复杂程度"
        ))
        
        characteristics.append(StyleCharacteristic(
            name: "正式程度",
            value: calculateFormalityScore(text),
            description: "文本的正式程度"
        ))
        
        characteristics.append(StyleCharacteristic(
            name: "情感色彩",
            value: calculateEmotionalTone(text),
            description: "文本的情感倾向"
        ))
        
        characteristics.append(StyleCharacteristic(
            name: "被动语态使用",
            value: calculatePassiveVoiceUsage(text),
            description: "被动语态的使用频率"
        ))
        
        return characteristics
    }
    
    private func determineStyle(from characteristics: [StyleCharacteristic]) -> TextStyle {
        // Simple style determination based on characteristics
        let formality = characteristics.first { $0.name == "正式程度" }?.value ?? 0.5
        let complexity = characteristics.first { $0.name == "词汇复杂度" }?.value ?? 0.5
        
        if formality > 0.7 {
            return .formal
        } else if formality < 0.3 {
            return .casual
        } else if complexity > 0.7 {
            return .academic
        } else if formality > 0.6 {
            return .business
        } else {
            return .friendly
        }
    }
    
    private func calculateStyleConfidence(characteristics: [StyleCharacteristic]) -> Double {
        // Calculate confidence based on the strength of style indicators
        let formality = characteristics.first { $0.name == "正式程度" }?.value ?? 0.5
        _ = characteristics.first { $0.name == "词汇复杂度" }?.value ?? 0.5
        
        // Confidence is higher when characteristics are strongly indicative of a particular style
        if formality > 0.8 || formality < 0.2 {
            return 0.9
        } else if formality > 0.6 || formality < 0.4 {
            return 0.7
        } else {
            return 0.5
        }
    }
    
    private func calculateReadabilityScore(_ text: String) -> Double {
        // Simple readability score calculation
        let sentences = text.components(separatedBy: .punctuationCharacters).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let words = text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        guard !sentences.isEmpty && !words.isEmpty else { return 0.5 }
        
        let avgWordsPerSentence = Double(words.count) / Double(sentences.count)
        
        // Normalize to 0-1 scale (lower is more readable)
        let score = max(0, min(1, 1.0 - (avgWordsPerSentence - 10) / 20))
        
        return score
    }
    
    private func calculateComplexityScore(_ text: String) -> Double {
        // Calculate text complexity based on various factors
        let words = text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let longWords = words.filter { $0.count > 6 }
        
        guard !words.isEmpty else { return 0.5 }
        
        let longWordRatio = Double(longWords.count) / Double(words.count)
        return min(1.0, longWordRatio * 2)
    }
    
    private func calculateFormalityScore(_ text: String) -> Double {
        // Calculate formality based on word choice and structure
        let formalWords = ["therefore", "however", "furthermore", "moreover", "consequently", "nevertheless"]
        let informalWords = ["don't", "can't", "won't", "isn't", "aren't", "wasn't", "weren't"]
        
        let words = text.lowercased().components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        guard !words.isEmpty else { return 0.5 }
        
        let formalCount = words.filter { formalWords.contains($0) }.count
        let informalCount = words.filter { informalWords.contains($0) }.count
        
        let formalityRatio = Double(formalCount) / Double(words.count)
        let informalityRatio = Double(informalCount) / Double(words.count)
        
        return max(0, min(1, 0.5 + formalityRatio - informalityRatio))
    }
    
    private func calculateAverageSentenceLength(_ text: String) -> Double {
        let sentences = text.components(separatedBy: .punctuationCharacters).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let words = text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        guard !sentences.isEmpty else { return 0 }
        
        return Double(words.count) / Double(sentences.count)
    }
    
    private func calculateVocabularyComplexity(_ text: String) -> Double {
        let words = text.lowercased().components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let uniqueWords = Set(words)
        
        guard !words.isEmpty else { return 0 }
        
        return Double(uniqueWords.count) / Double(words.count)
    }
    
    private func calculateEmotionalTone(_ text: String) -> Double {
        // Simple emotional tone calculation
        let positiveWords = ["good", "great", "excellent", "wonderful", "amazing", "fantastic", "happy", "love", "best"]
        let negativeWords = ["bad", "terrible", "awful", "horrible", "hate", "worst", "sad", "angry"]
        
        let words = text.lowercased().components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        guard !words.isEmpty else { return 0.5 }
        
        let positiveCount = words.filter { positiveWords.contains($0) }.count
        let negativeCount = words.filter { negativeWords.contains($0) }.count
        
        let emotionalRatio = Double(positiveCount - negativeCount) / Double(words.count)
        
        return max(0, min(1, 0.5 + emotionalRatio))
    }
    
    private func calculatePassiveVoiceUsage(_ text: String) -> Double {
        // Simple passive voice detection
        let passivePatterns = ["was", "were", "been", "being"]
        let words = text.lowercased().components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        guard !words.isEmpty else { return 0 }
        
        let passiveCount = words.filter { passivePatterns.contains($0) }.count
        return Double(passiveCount) / Double(words.count)
    }
    
    // MARK: - Helper Methods
    
    private func identifyChanges(original: String, converted: String) -> [TextChange] {
        // Simple change detection - in production, this would use more sophisticated algorithms
        var changes: [TextChange] = []
        
        let originalWords = original.components(separatedBy: .whitespaces)
        let convertedWords = converted.components(separatedBy: .whitespaces)
        
        let minLength = min(originalWords.count, convertedWords.count)
        
        for i in 0..<minLength {
            if originalWords[i] != convertedWords[i] {
                let change = TextChange(
                    type: .vocabulary,
                    original: originalWords[i],
                    replacement: convertedWords[i],
                    position: NSRange(location: i, length: 1),
                    reason: "词汇替换以适应目标风格"
                )
                changes.append(change)
            }
        }
        
        return changes
    }
    
    private func generateSuggestions(text: String, style: TextStyle) -> [String] {
        var suggestions: [String] = []
        
        switch style {
        case .formal:
            suggestions.append("考虑使用更正式的词汇和完整的句子结构")
            suggestions.append("避免使用缩写和口语化表达")
        case .casual:
            suggestions.append("使用更自然的口语化表达")
            suggestions.append("可以适当使用缩写和简短句子")
        case .academic:
            suggestions.append("确保使用准确的学术术语")
            suggestions.append("保持客观、中立的语气")
        case .business:
            suggestions.append("使用专业术语和商务词汇")
            suggestions.append("保持简洁、直接的沟通风格")
        case .creative:
            suggestions.append("使用生动的描述和形象的语言")
            suggestions.append("可以尝试不同的表达方式")
        default:
            suggestions.append("检查文本是否符合目标风格的要求")
        }
        
        return suggestions
    }
    
    private func calculateConfidence(analysis: StyleAnalysis, conversionQuality: Int) -> Double {
        // Calculate confidence based on analysis quality and number of changes
        let baseConfidence = analysis.confidence
        let changePenalty = Double(conversionQuality) * 0.01 // Small penalty for many changes
        
        return max(0.1, min(1.0, baseConfidence - changePenalty))
    }
}

// MARK: - Supporting Structures

public struct StyleRecommendation {
    public let style: TextStyleConversionService.TextStyle
    public let reason: String
    public let confidence: Double
    
    public init(style: TextStyleConversionService.TextStyle, reason: String, confidence: Double) {
        self.style = style
        self.reason = reason
        self.confidence = confidence
    }
}

// MARK: - Helper Extension

extension NSRegularExpression {
    convenience init(_ pattern: String) {
        do {
            try self.init(pattern: pattern)
        } catch {
            fatalError("Invalid regular expression: \(pattern)")
        }
    }
}