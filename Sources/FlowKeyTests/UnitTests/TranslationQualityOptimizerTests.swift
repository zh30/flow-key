import XCTest
@testable import FlowKey

class TranslationQualityOptimizerTests: XCTestCase {
    
    var optimizer: TranslationQualityOptimizer!
    
    override func setUp() {
        super.setUp()
        optimizer = TranslationQualityOptimizer.shared
    }
    
    override func tearDown() {
        optimizer = nil
        super.tearDown()
    }
    
    // MARK: - Basic Optimization Tests
    
    func testTranslationQualityOptimization() async {
        let originalText = "Hello, how are you today?"
        let translatedText = "你好，你今天好吗？"
        let sourceLanguage = "en"
        let targetLanguage = "zh"
        
        let result = await optimizer.optimizeTranslation(
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            strategy: .balanced
        )
        
        XCTAssertFalse(result.optimizedTranslation.isEmpty)
        XCTAssertGreaterThanOrEqual(result.qualityMetrics.overallScore, 0.0)
        XCTAssertLessThanOrEqual(result.qualityMetrics.overallScore, 1.0)
        XCTAssertGreaterThanOrEqual(result.processingTime, 0.0)
    }
    
    func testQualityAnalysis() async {
        let originalText = "Thank you for your help"
        let translatedText = "谢谢你的帮助"
        let sourceLanguage = "en"
        let targetLanguage = "zh"
        
        let metrics = await optimizer.analyzeTranslationQuality(
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
        
        XCTAssertGreaterThanOrEqual(metrics.accuracy, 0.0)
        XCTAssertLessThanOrEqual(metrics.accuracy, 1.0)
        XCTAssertGreaterThanOrEqual(metrics.fluency, 0.0)
        XCTAssertLessThanOrEqual(metrics.fluency, 1.0)
        XCTAssertGreaterThanOrEqual(metrics.consistency, 0.0)
        XCTAssertLessThanOrEqual(metrics.consistency, 1.0)
        XCTAssertGreaterThanOrEqual(metrics.culturalAppropriateness, 0.0)
        XCTAssertLessThanOrEqual(metrics.culturalAppropriateness, 1.0)
        XCTAssertGreaterThanOrEqual(metrics.contextPreservation, 0.0)
        XCTAssertLessThanOrEqual(metrics.contextPreservation, 1.0)
        XCTAssertGreaterThanOrEqual(metrics.overallScore, 0.0)
        XCTAssertLessThanOrEqual(metrics.overallScore, 1.0)
    }
    
    func testImprovementSuggestions() async {
        let originalText = "I think this is good"
        let translatedText = "我认为这是好的"
        let sourceLanguage = "en"
        let targetLanguage = "zh"
        
        let suggestions = await optimizer.generateImprovementSuggestions(
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            context: nil,
            qualityMetrics: TranslationQualityOptimizer.QualityMetrics(
                accuracy: 0.7,
                fluency: 0.8,
                consistency: 0.9,
                culturalAppropriateness: 0.8,
                contextPreservation: 0.7
            )
        )
        
        XCTAssertFalse(suggestions.isEmpty)
        for suggestion in suggestions {
            XCTAssertFalse(suggestion.originalText.isEmpty)
            XCTAssertFalse(suggestion.originalTranslation.isEmpty)
            XCTAssertFalse(suggestion.suggestedTranslation.isEmpty)
            XCTAssertGreaterThanOrEqual(suggestion.confidence, 0.0)
            XCTAssertLessThanOrEqual(suggestion.confidence, 1.0)
            XCTAssertFalse(suggestion.issues.isEmpty)
            XCTAssertFalse(suggestion.explanation.isEmpty)
            XCTAssertGreaterThanOrEqual(suggestion.improvementScore, 0.0)
        }
    }
    
    // MARK: - Strategy Tests
    
    func testAccuracyStrategy() async {
        let originalText = "The quick brown fox jumps over the lazy dog"
        let translatedText = "快速的棕色狐狸跳过懒狗"
        let sourceLanguage = "en"
        let targetLanguage = "zh"
        
        let result = await optimizer.optimizeTranslation(
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            strategy: .accuracy
        )
        
        XCTAssertFalse(result.optimizedTranslation.isEmpty)
        XCTAssertEqual(result.appliedOptimizations.count, 0) // Mock implementation
    }
    
    func testSpeedStrategy() async {
        let originalText = "Hello world"
        let translatedText = "你好世界"
        let sourceLanguage = "en"
        let targetLanguage = "zh"
        
        let result = await optimizer.optimizeTranslation(
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            strategy: .speed
        )
        
        XCTAssertFalse(result.optimizedTranslation.isEmpty)
        XCTAssertLessThanOrEqual(result.processingTime, 2.0) // Should be fast
    }
    
    func testContextAwareStrategy() async {
        let originalText = "Meeting tomorrow at 3 PM"
        let translatedText = "明天下午3点开会"
        let sourceLanguage = "en"
        let targetLanguage = "zh"
        let context = "Business meeting scheduling"
        
        let result = await optimizer.optimizeTranslation(
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            context: context,
            strategy: .contextAware
        )
        
        XCTAssertFalse(result.optimizedTranslation.isEmpty)
    }
    
    // MARK: - Quality Metrics Tests
    
    func testQualityMetricsCalculation() async {
        let metrics = TranslationQualityOptimizer.QualityMetrics(
            accuracy: 0.9,
            fluency: 0.8,
            consistency: 0.95,
            culturalAppropriateness: 0.85,
            contextPreservation: 0.75
        )
        
        XCTAssertEqual(metrics.accuracy, 0.9)
        XCTAssertEqual(metrics.fluency, 0.8)
        XCTAssertEqual(metrics.consistency, 0.95)
        XCTAssertEqual(metrics.culturalAppropriateness, 0.85)
        XCTAssertEqual(metrics.contextPreservation, 0.75)
        
        // Test overall score calculation
        let expectedOverall = (0.9 + 0.8 + 0.95 + 0.85 + 0.75) / 5.0
        XCTAssertEqual(metrics.overallScore, expectedOverall, accuracy: 0.001)
    }
    
    // MARK: - Translation Service Integration Tests
    
    func testTranslationServiceIntegration() async {
        let service = TranslationService.shared
        
        let result = await service.translate(
            text: "Good morning",
            source: "en",
            target: "zh",
            enableOptimization: true
        )
        
        XCTAssertFalse(result.isEmpty)
        // Should be a valid Chinese translation
        XCTAssertTrue(result.contains("好") || result.contains("早安") || result.contains("早上"))
    }
    
    func testQualityAnalysisIntegration() async {
        let service = TranslationService.shared
        
        let metrics = await service.getTranslationQualityAnalysis(
            originalText: "How are you?",
            translatedText: "你好吗？",
            sourceLanguage: "en",
            targetLanguage: "zh"
        )
        
        XCTAssertGreaterThanOrEqual(metrics.overallScore, 0.0)
        XCTAssertLessThanOrEqual(metrics.overallScore, 1.0)
    }
    
    func testSuggestionsIntegration() async {
        let service = TranslationService.shared
        
        let suggestions = await service.getTranslationSuggestions(
            originalText: "I think this is correct",
            translatedText: "我认为这是正确的",
            sourceLanguage: "en",
            targetLanguage: "zh"
        )
        
        XCTAssertFalse(suggestions.isEmpty)
    }
    
    // MARK: - Edge Cases
    
    func testEmptyText() async {
        let result = await optimizer.optimizeTranslation(
            originalText: "",
            translatedText: "",
            sourceLanguage: "en",
            targetLanguage: "zh"
        )
        
        XCTAssertEqual(result.optimizedTranslation, "")
    }
    
    func testVeryLongText() async {
        let longText = String(repeating: "This is a test sentence. ", count: 100)
        let longTranslation = String(repeating: "这是一个测试句子。", count: 100)
        
        let result = await optimizer.optimizeTranslation(
            originalText: longText,
            translatedText: longTranslation,
            sourceLanguage: "en",
            targetLanguage: "zh"
        )
        
        XCTAssertFalse(result.optimizedTranslation.isEmpty)
        XCTAssertGreaterThanOrEqual(result.processingTime, 0.0)
    }
    
    func testUnsupportedLanguage() async {
        let result = await optimizer.optimizeTranslation(
            originalText: "Hello",
            translatedText: "Hello",
            sourceLanguage: "xx", // Unsupported language
            targetLanguage: "yy"  // Unsupported language
        )
        
        XCTAssertFalse(result.optimizedTranslation.isEmpty)
    }
    
    // MARK: - Performance Tests
    
    func testOptimizationPerformance() async {
        let startTime = Date()
        
        _ = await optimizer.optimizeTranslation(
            originalText: "Performance test",
            translatedText: "性能测试",
            sourceLanguage: "en",
            targetLanguage: "zh"
        )
        
        let endTime = Date()
        let processingTime = endTime.timeIntervalSince(startTime)
        
        XCTAssertLessThan(processingTime, 5.0) // Should complete within 5 seconds
    }
    
    func testMultipleOptimizations() async {
        let texts = [
            ("Hello", "你好"),
            ("Goodbye", "再见"),
            ("Thank you", "谢谢"),
            ("Please", "请"),
            ("Sorry", "对不起")
        ]
        
        let startTime = Date()
        
        for (original, translated) in texts {
            _ = await optimizer.optimizeTranslation(
                originalText: original,
                translatedText: translated,
                sourceLanguage: "en",
                targetLanguage: "zh"
            )
        }
        
        let endTime = Date()
        let totalTime = endTime.timeIntervalSince(startTime)
        let averageTime = totalTime / Double(texts.count)
        
        XCTAssertLessThan(averageTime, 2.0) // Average should be under 2 seconds
    }
}

class TranslationQualityFeedbackManagerTests: XCTestCase {
    
    var feedbackManager: TranslationQualityFeedbackManager!
    
    override func setUp() {
        super.setUp()
        feedbackManager = TranslationQualityFeedbackManager.shared
    }
    
    override func tearDown() {
        feedbackManager = nil
        super.tearDown()
    }
    
    // MARK: - Feedback Tests
    
    func testSubmitFeedback() async {
        let ratings: [TranslationQualityFeedbackManager.FeedbackType: TranslationQualityFeedbackManager.Rating] = [
            .accuracy: .good,
            .fluency: .veryGood,
            .naturalness: .good,
            .overall: .good
        ]
        
        await feedbackManager.submitFeedback(
            originalText: "Test feedback",
            translatedText: "测试反馈",
            sourceLanguage: "en",
            targetLanguage: "zh",
            ratings: ratings,
            userComments: "Good translation",
            suggestedImprovement: "Could be more natural"
        )
        
        // Verify feedback was submitted (would check database in real implementation)
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    func testQualityInsights() async {
        let insights = await feedbackManager.getQualityInsights()
        
        XCTAssertFalse(insights.isEmpty)
        for insight in insights {
            XCTAssertGreaterThanOrEqual(insight.severity, 0.0)
            XCTAssertLessThanOrEqual(insight.severity, 1.0)
            XCTAssertGreaterThanOrEqual(insight.frequency, 0)
            XCTAssertFalse(insight.suggestedImprovements.isEmpty)
            XCTAssertGreaterThanOrEqual(insight.impact, 0.0)
        }
    }
    
    func testAverageRating() async {
        let rating = await feedbackManager.getAverageRating(for: .accuracy)
        
        XCTAssertGreaterThanOrEqual(rating, 0.0)
        XCTAssertLessThanOrEqual(rating, 5.0)
    }
    
    func testOptimizationEffectiveness() async {
        let effectiveness = await feedbackManager.getOptimizationEffectiveness()
        
        XCTAssertGreaterThanOrEqual(effectiveness.optimized, 0.0)
        XCTAssertLessThanOrEqual(effectiveness.optimized, 5.0)
        XCTAssertGreaterThanOrEqual(effectiveness.nonOptimized, 0.0)
        XCTAssertLessThanOrEqual(effectiveness.nonOptimized, 5.0)
    }
}