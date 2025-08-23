import Foundation
import MLX

public class TranslationQualityOptimizer {
    public static let shared = TranslationQualityOptimizer()
    
    private init() {}
    
    // MARK: - Quality Optimization Types
    
    public enum OptimizationStrategy {
        case accuracy       // Maximize translation accuracy
        case speed          // Optimize for translation speed
        case balanced       // Balance between accuracy and speed
        case contextAware   // Consider context for better translations
    }
    
    public enum QualityIssue {
        case grammaticalError
        case terminologyMismatch
        case contextLoss
        case culturalInappropriateness
        case formattingLoss
        case punctuationError
        case spellingError
        case ambiguity
    }
    
    public struct QualityMetrics {
        public let accuracy: Double          // 0.0 - 1.0
        public let fluency: Double           // 0.0 - 1.0
        public let consistency: Double        // 0.0 - 1.0
        public let culturalAppropriateness: Double // 0.0 - 1.0
        public let contextPreservation: Double    // 0.0 - 1.0
        public let overallScore: Double      // 0.0 - 1.0
        
        public init(accuracy: Double, fluency: Double, consistency: Double, 
                   culturalAppropriateness: Double, contextPreservation: Double) {
            self.accuracy = accuracy
            self.fluency = fluency
            self.consistency = consistency
            self.culturalAppropriateness = culturalAppropriateness
            self.contextPreservation = contextPreservation
            self.overallScore = (accuracy + fluency + consistency + culturalAppropriateness + contextPreservation) / 5.0
        }
    }
    
    public struct TranslationSuggestion {
        public let originalText: String
        public let originalTranslation: String
        public let suggestedTranslation: String
        public let confidence: Double
        public let issues: [QualityIssue]
        public let explanation: String
        public let improvementScore: Double
        
        public init(originalText: String, originalTranslation: String, suggestedTranslation: String,
                    confidence: Double, issues: [QualityIssue], explanation: String, improvementScore: Double) {
            self.originalText = originalText
            self.originalTranslation = originalTranslation
            self.suggestedTranslation = suggestedTranslation
            self.confidence = confidence
            self.issues = issues
            self.explanation = explanation
            self.improvementScore = improvementScore
        }
    }
    
    public struct OptimizationResult {
        public let optimizedTranslation: String
        public let qualityMetrics: QualityMetrics
        public let suggestions: [TranslationSuggestion]
        public let processingTime: TimeInterval
        public let appliedOptimizations: [String]
        
        public init(optimizedTranslation: String, qualityMetrics: QualityMetrics,
                    suggestions: [TranslationSuggestion], processingTime: TimeInterval,
                    appliedOptimizations: [String]) {
            self.optimizedTranslation = optimizedTranslation
            self.qualityMetrics = qualityMetrics
            self.suggestions = suggestions
            self.processingTime = processingTime
            self.appliedOptimizations = appliedOptimizations
        }
    }
    
    // MARK: - Main Optimization Methods
    
    public func optimizeTranslation(
        originalText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String,
        context: String? = nil,
        strategy: OptimizationStrategy = .balanced
    ) async -> OptimizationResult {
        let startTime = Date()
        
        // Step 1: Analyze quality of current translation
        let qualityMetrics = await analyzeTranslationQuality(
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            context: context
        )
        
        // Step 2: Generate improvement suggestions
        let suggestions = await generateImprovementSuggestions(
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            context: context,
            qualityMetrics: qualityMetrics
        )
        
        // Step 3: Apply optimizations based on strategy
        let (optimizedTranslation, appliedOptimizations) = await applyOptimizations(
            originalText: originalText,
            translatedText: translatedText,
            suggestions: suggestions,
            strategy: strategy
        )
        
        // Step 4: Re-analyze optimized translation
        let finalMetrics = await analyzeTranslationQuality(
            originalText: originalText,
            translatedText: optimizedTranslation,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            context: context
        )
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        return OptimizationResult(
            optimizedTranslation: optimizedTranslation,
            qualityMetrics: finalMetrics,
            suggestions: suggestions,
            processingTime: processingTime,
            appliedOptimizations: appliedOptimizations
        )
    }
    
    // MARK: - Quality Analysis Methods
    
    private func analyzeTranslationQuality(
        originalText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String,
        context: String?
    ) async -> QualityMetrics {
        var accuracy = 0.5
        var fluency = 0.5
        var consistency = 0.5
        var culturalAppropriateness = 0.5
        var contextPreservation = 0.5
        
        // Accuracy analysis
        accuracy = await calculateAccuracyScore(
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
        
        // Fluency analysis
        fluency = await calculateFluencyScore(
            translatedText: translatedText,
            targetLanguage: targetLanguage
        )
        
        // Consistency analysis
        consistency = await calculateConsistencyScore(
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
        
        // Cultural appropriateness analysis
        culturalAppropriateness = await calculateCulturalAppropriatenessScore(
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
        
        // Context preservation analysis
        if let context = context {
            contextPreservation = await calculateContextPreservationScore(
                originalText: originalText,
                translatedText: translatedText,
                context: context,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage
            )
        }
        
        return QualityMetrics(
            accuracy: accuracy,
            fluency: fluency,
            consistency: consistency,
            culturalAppropriateness: culturalAppropriateness,
            contextPreservation: contextPreservation
        )
    }
    
    private func calculateAccuracyScore(
        originalText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String
    ) async -> Double {
        // Basic accuracy scoring based on various factors
        var score = 0.5
        
        // Length ratio check (reasonable length difference)
        let lengthRatio = Double(translatedText.count) / Double(originalText.count)
        if lengthRatio >= 0.5 && lengthRatio <= 2.0 {
            score += 0.2
        }
        
        // Check for common translation patterns
        if await hasCommonTranslationPattern(originalText: originalText, translatedText: translatedText) {
            score += 0.1
        }
        
        // Check for proper nouns preservation
        if await preservesProperNouns(originalText: originalText, translatedText: translatedText) {
            score += 0.1
        }
        
        // Check for number preservation
        if await preservesNumbers(originalText: originalText, translatedText: translatedText) {
            score += 0.1
        }
        
        return min(score, 1.0)
    }
    
    private func calculateFluencyScore(
        translatedText: String,
        targetLanguage: String
    ) async -> Double {
        var score = 0.5
        
        // Basic fluency checks
        if translatedText.count > 0 {
            score += 0.1
        }
        
        // Check for proper sentence structure
        if await hasProperSentenceStructure(translatedText: translatedText, language: targetLanguage) {
            score += 0.2
        }
        
        // Check for common grammatical patterns
        if await hasProperGrammar(translatedText: translatedText, language: targetLanguage) {
            score += 0.2
        }
        
        // Check for natural language flow
        if await hasNaturalFlow(translatedText: translatedText, language: targetLanguage) {
            score += 0.1
        }
        
        return min(score, 1.0)
    }
    
    private func calculateConsistencyScore(
        originalText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String
    ) async -> Double {
        var score = 0.5
        
        // Check terminology consistency
        if await hasConsistentTerminology(originalText: originalText, translatedText: translatedText) {
            score += 0.2
        }
        
        // Check style consistency
        if await hasConsistentStyle(originalText: originalText, translatedText: translatedText) {
            score += 0.2
        }
        
        // Check tone consistency
        if await hasConsistentTone(originalText: originalText, translatedText: translatedText) {
            score += 0.1
        }
        
        return min(score, 1.0)
    }
    
    private func calculateCulturalAppropriatenessScore(
        originalText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String
    ) async -> Double {
        var score = 0.7 // Base score
        
        // Check for culturally sensitive terms
        if await avoidsCulturallySensitiveTerms(translatedText: translatedText, targetLanguage: targetLanguage) {
            score += 0.2
        }
        
        // Check for appropriate cultural references
        if await hasAppropriateCulturalReferences(originalText: originalText, translatedText: translatedText) {
            score += 0.1
        }
        
        return min(score, 1.0)
    }
    
    private func calculateContextPreservationScore(
        originalText: String,
        translatedText: String,
        context: String,
        sourceLanguage: String,
        targetLanguage: String
    ) async -> Double {
        var score = 0.5
        
        // Check if translation maintains context relevance
        if await maintainsContextRelevance(originalText: originalText, translatedText: translatedText, context: context) {
            score += 0.3
        }
        
        // Check for domain-specific terminology
        if await preservesDomainTerminology(originalText: originalText, translatedText: translatedText, context: context) {
            score += 0.2
        }
        
        return min(score, 1.0)
    }
    
    // MARK: - Suggestion Generation Methods
    
    private func generateImprovementSuggestions(
        originalText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String,
        context: String?,
        qualityMetrics: QualityMetrics
    ) async -> [TranslationSuggestion] {
        var suggestions: [TranslationSuggestion] = []
        
        // Generate suggestions based on quality issues
        if qualityMetrics.accuracy < 0.8 {
            suggestions.append(contentsOf: await generateAccuracySuggestions(
                originalText: originalText,
                translatedText: translatedText,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage
            ))
        }
        
        if qualityMetrics.fluency < 0.8 {
            suggestions.append(contentsOf: await generateFluencySuggestions(
                translatedText: translatedText,
                targetLanguage: targetLanguage
            ))
        }
        
        if qualityMetrics.consistency < 0.8 {
            suggestions.append(contentsOf: await generateConsistencySuggestions(
                originalText: originalText,
                translatedText: translatedText,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage
            ))
        }
        
        // Sort by improvement score
        return suggestions.sorted { $0.improvementScore > $1.improvementScore }
    }
    
    private func generateAccuracySuggestions(
        originalText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String
    ) async -> [TranslationSuggestion] {
        var suggestions: [TranslationSuggestion] = []
        
        // Check for common mistranslations
        let mistranslations = await findCommonMistranslations(
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
        
        for mistranslation in mistranslations {
            suggestions.append(TranslationSuggestion(
                originalText: originalText,
                originalTranslation: translatedText,
                suggestedTranslation: mistranslation.suggested,
                confidence: mistranslation.confidence,
                issues: [QualityIssue.terminologyMismatch],
                explanation: mistranslation.explanation,
                improvementScore: mistranslation.improvementScore
            ))
        }
        
        return suggestions
    }
    
    private func generateFluencySuggestions(
        translatedText: String,
        targetLanguage: String
    ) async -> [TranslationSuggestion] {
        var suggestions: [TranslationSuggestion] = []
        
        // Check for grammatical issues
        let grammaticalIssues = await findGrammaticalIssues(
            translatedText: translatedText,
            language: targetLanguage
        )
        
        for issue in grammaticalIssues {
            suggestions.append(TranslationSuggestion(
                originalText: "",
                originalTranslation: translatedText,
                suggestedTranslation: issue.suggested,
                confidence: issue.confidence,
                issues: [QualityIssue.grammaticalError],
                explanation: issue.explanation,
                improvementScore: issue.improvementScore
            ))
        }
        
        return suggestions
    }
    
    private func generateConsistencySuggestions(
        originalText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String
    ) async -> [TranslationSuggestion] {
        var suggestions: [TranslationSuggestion] = []
        
        // Check for terminology consistency
        let consistencyIssues = await findConsistencyIssues(
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
        
        for issue in consistencyIssues {
            suggestions.append(TranslationSuggestion(
                originalText: originalText,
                originalTranslation: translatedText,
                suggestedTranslation: issue.suggested,
                confidence: issue.confidence,
                issues: [QualityIssue.terminologyMismatch],
                explanation: issue.explanation,
                improvementScore: issue.improvementScore
            ))
        }
        
        return suggestions
    }
    
    // MARK: - Optimization Application Methods
    
    private func applyOptimizations(
        originalText: String,
        translatedText: String,
        suggestions: [TranslationSuggestion],
        strategy: OptimizationStrategy
    ) async -> (String, [String]) {
        var optimizedText = translatedText
        var appliedOptimizations: [String] = []
        
        // Apply suggestions based on strategy and confidence
        for suggestion in suggestions {
            let shouldApply = await shouldApplySuggestion(suggestion: suggestion, strategy: strategy)
            
            if shouldApply {
                optimizedText = suggestion.suggestedTranslation
                appliedOptimizations.append(suggestion.explanation)
            }
        }
        
        return (optimizedText, appliedOptimizations)
    }
    
    private func shouldApplySuggestion(
        suggestion: TranslationSuggestion,
        strategy: OptimizationStrategy
    ) async -> Bool {
        let threshold: Double
        
        switch strategy {
        case .accuracy:
            threshold = 0.7
        case .speed:
            threshold = 0.8
        case .balanced:
            threshold = 0.75
        case .contextAware:
            threshold = 0.7
        }
        
        return suggestion.confidence >= threshold && suggestion.improvementScore >= 0.1
    }
    
    // MARK: - Helper Methods
    
    private func hasCommonTranslationPattern(originalText: String, translatedText: String) async -> Bool {
        // Check if translation follows common patterns
        let patterns = [
            ("Hello", "你好"),
            ("Thank you", "谢谢"),
            ("Good morning", "早上好"),
            ("Goodbye", "再见")
        ]
        
        for (original, translation) in patterns {
            if originalText.contains(original) && translatedText.contains(translation) {
                return true
            }
        }
        
        return false
    }
    
    private func preservesProperNouns(originalText: String, translatedText: String) async -> Bool {
        // Simple check for proper noun preservation
        let properNouns = extractProperNouns(from: originalText)
        for noun in properNouns {
            if !translatedText.contains(noun) {
                return false
            }
        }
        return true
    }
    
    private func preservesNumbers(originalText: String, translatedText: String) async -> Bool {
        // Check if numbers are preserved
        let numbers = extractNumbers(from: originalText)
        for number in numbers {
            if !translatedText.contains(number) {
                return false
            }
        }
        return true
    }
    
    private func hasProperSentenceStructure(translatedText: String, language: String) async -> Bool {
        // Basic sentence structure check
        return translatedText.first?.isUppercase == true && 
               (translatedText.last == "." || translatedText.last == "!" || translatedText.last == "?")
    }
    
    private func hasProperGrammar(translatedText: String, language: String) async -> Bool {
        // Basic grammar checks
        return !translatedText.contains("  ") && // No double spaces
               translatedText.count > 0
    }
    
    private func hasNaturalFlow(translatedText: String, language: String) async -> Bool {
        // Check for natural language flow
        let words = translatedText.split(separator: " ")
        return words.count >= 2 // At least 2 words
    }
    
    private func hasConsistentTerminology(originalText: String, translatedText: String) async -> Bool {
        // Check for consistent terminology
        return true // Simplified for now
    }
    
    private func hasConsistentStyle(originalText: String, translatedText: String) async -> Bool {
        // Check for consistent style
        return true // Simplified for now
    }
    
    private func hasConsistentTone(originalText: String, translatedText: String) async -> Bool {
        // Check for consistent tone
        return true // Simplified for now
    }
    
    private func avoidsCulturallySensitiveTerms(translatedText: String, targetLanguage: String) async -> Bool {
        // Check for culturally sensitive terms
        return true // Simplified for now
    }
    
    private func hasAppropriateCulturalReferences(originalText: String, translatedText: String) async -> Bool {
        // Check for appropriate cultural references
        return true // Simplified for now
    }
    
    private func maintainsContextRelevance(originalText: String, translatedText: String, context: String) async -> Bool {
        // Check if translation maintains context relevance
        return true // Simplified for now
    }
    
    private func preservesDomainTerminology(originalText: String, translatedText: String, context: String) async -> Bool {
        // Check for domain-specific terminology preservation
        return true // Simplified for now
    }
    
    // MARK: - Helper Structs
    
    private struct Mistranslation {
        let original: String
        let incorrect: String
        let suggested: String
        let confidence: Double
        let explanation: String
        let improvementScore: Double
    }
    
    private struct GrammaticalIssue {
        let incorrect: String
        let suggested: String
        let confidence: Double
        let explanation: String
        let improvementScore: Double
    }
    
    private struct ConsistencyIssue {
        let original: String
        let inconsistent: String
        let suggested: String
        let confidence: Double
        let explanation: String
        let improvementScore: Double
    }
    
    // MARK: - Text Extraction Methods
    
    private func extractProperNouns(from text: String) -> [String] {
        // Simple proper noun extraction
        let words = text.split(separator: " ")
        return words.filter { $0.first?.isUppercase == true && $0.count > 1 }.map(String.init)
    }
    
    private func extractNumbers(from text: String) -> [String] {
        let numberPattern = "\\d+(?:\\.\\d+)?"
        guard let regex = try? NSRegularExpression(pattern: numberPattern) else { return [] }
        
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return matches.compactMap { match in
            if let range = Range(match.range, in: text) {
                return String(text[range])
            }
            return nil
        }
    }
    
    // MARK: - Mistranslation Detection
    
    private func findCommonMistranslations(
        originalText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String
    ) async -> [Mistranslation] {
        var mistranslations: [Mistranslation] = []
        
        // Common mistranslation patterns
        let commonMistranslations: [String: String] = [
            "I think": "我认为",
            "I believe": "我相信",
            "I feel": "我感觉",
            "I want": "我想要",
            "I need": "我需要",
            "I like": "我喜欢",
            "I love": "我爱",
            "I hate": "我讨厌"
        ]
        
        for (original, correctTranslation) in commonMistranslations {
            if originalText.contains(original) && !translatedText.contains(correctTranslation) {
                mistranslations.append(Mistranslation(
                    original: original,
                    incorrect: translatedText,
                    suggested: correctTranslation,
                    confidence: 0.8,
                    explanation: "常见翻译错误：'\(original)' 应该翻译为 '\(correctTranslation)'",
                    improvementScore: 0.3
                ))
            }
        }
        
        return mistranslations
    }
    
    private func findGrammaticalIssues(
        translatedText: String,
        language: String
    ) async -> [GrammaticalIssue] {
        var issues: [GrammaticalIssue] = []
        
        // Check for double spaces
        if translatedText.contains("  ") {
            issues.append(GrammaticalIssue(
                incorrect: translatedText,
                suggested: translatedText.replacingOccurrences(of: "  ", with: " "),
                confidence: 0.9,
                explanation: "移除多余空格",
                improvementScore: 0.1
            ))
        }
        
        return issues
    }
    
    private func findConsistencyIssues(
        originalText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String
    ) async -> [ConsistencyIssue] {
        // Simplified consistency checking
        return []
    }
}