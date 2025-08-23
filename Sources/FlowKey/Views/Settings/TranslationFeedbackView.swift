import SwiftUI

struct TranslationFeedbackView: View {
    @State private var originalText: String
    @State private var translatedText: String
    @State private var sourceLanguage: String
    @State private var targetLanguage: String
    @State private var wasOptimized: Bool
    @State private var optimizationApplied: Bool
    
    @State private var ratings: [TranslationQualityFeedbackManager.FeedbackType: TranslationQualityFeedbackManager.Rating] = [:]
    @State private var userComments: String = ""
    @State private var suggestedImprovement: String = ""
    @State private var showSuccessAlert = false
    @State private var isSubmitting = false
    
    private let feedbackManager = TranslationQualityFeedbackManager.shared
    
    init(originalText: String, translatedText: String, sourceLanguage: String, targetLanguage: String, 
         wasOptimized: Bool = false, optimizationApplied: Bool = false) {
        self.originalText = originalText
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.wasOptimized = wasOptimized
        self.optimizationApplied = optimizationApplied
        
        // Initialize ratings with default values
        _ratings = State(initialValue: Dictionary(
            uniqueKeysWithValues: TranslationQualityFeedbackManager.FeedbackType.allCases.map { ($0, .good) }
        ))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("翻译内容")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("原文")
                            .font(.headline)
                        Text(originalText)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(4)
                        
                        Text("译文")
                            .font(.headline)
                        Text(translatedText)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(4)
                    }
                    
                    if wasOptimized {
                        HStack {
                            Text("优化状态")
                            Spacer()
                            Text(optimizationApplied ? "已优化" : "未优化")
                                .foregroundColor(optimizationApplied ? .green : .orange)
                        }
                    }
                }
                
                Section(header: Text("质量评分")) {
                    ForEach(TranslationQualityFeedbackManager.FeedbackType.allCases, id: \.self) { type in
                        RatingRow(
                            type: type,
                            rating: $ratings[type]
                        )
                    }
                }
                
                Section(header: Text("反馈意见")) {
                    TextEditor(text: $userComments)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }
                
                Section(header: Text("改进建议")) {
                    TextField("请提供您的改进建议...", text: $suggestedImprovement, axis: .vertical)
                        .lineLimit(3)
                }
                
                Section {
                    Button("提交反馈") {
                        submitFeedback()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSubmitting)
                    
                    if isSubmitting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .navigationTitle("翻译质量反馈")
            .navigationBarTitleDisplayMode(.inline)
            .alert("反馈提交成功", isPresented: $showSuccessAlert) {
                Button("确定") { }
            } message: {
                Text("感谢您的反馈！我们将根据您的意见不断改进翻译质量。")
            }
        }
        .frame(width: 500, height: 600)
    }
    
    private func submitFeedback() {
        isSubmitting = true
        
        Task {
            await feedbackManager.submitFeedback(
                originalText: originalText,
                translatedText: translatedText,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                ratings: ratings,
                userComments: userComments.isEmpty ? nil : userComments,
                suggestedImprovement: suggestedImprovement.isEmpty ? nil : suggestedImprovement,
                wasOptimized: wasOptimized,
                optimizationApplied: optimizationApplied
            )
            
            await MainActor.run {
                isSubmitting = false
                showSuccessAlert = true
            }
        }
    }
}

struct RatingRow: View {
    let type: TranslationQualityFeedbackManager.FeedbackType
    @Binding var rating: TranslationQualityFeedbackManager.Rating?
    
    var body: some View {
        HStack {
            Text(type.displayName)
            Spacer()
            RatingStars(rating: $rating)
        }
    }
}

struct RatingStars: View {
    @Binding var rating: TranslationQualityFeedbackManager.Rating?
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(TranslationQualityFeedbackManager.Rating.allCases, id: \.self) { starRating in
                Button(action: {
                    rating = starRating
                }) {
                    Image(systemName: starRating.rawValue <= (rating?.rawValue ?? 0) ? "star.fill" : "star")
                        .foregroundColor(starRating.rawValue <= (rating?.rawValue ?? 0) ? .yellow : .gray)
                        .font(.system(size: 16))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct TranslationQualityInsightsView: View {
    @State private var insights: [TranslationQualityFeedbackManager.QualityInsight] = []
    @State private var averageRatings: [TranslationQualityFeedbackManager.FeedbackType: Double] = [:]
    @State private var optimizationEffectiveness: (optimized: Double, nonOptimized: Double) = (0, 0)
    @State private var isLoading = false
    
    private let feedbackManager = TranslationQualityFeedbackManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        qualityOverviewSection
                        
                        if !insights.isEmpty {
                            insightsSection
                        }
                        
                        optimizationEffectivenessSection
                        
                        averageRatingsSection
                    }
                }
                .padding()
            }
            .navigationTitle("质量洞察")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("刷新") {
                        loadInsights()
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear {
                loadInsights()
            }
        }
        .frame(width: 600, height: 500)
    }
    
    private var qualityOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("质量概览")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                QualityMetricCard(
                    title: "优化效果",
                    value: String(format: "%.1f%%", optimizationEffectiveness.optimized),
                    subtitle: "优化后平均评分",
                    color: .green
                )
                
                QualityMetricCard(
                    title: "基准质量",
                    value: String(format: "%.1f%%", optimizationEffectiveness.nonOptimized),
                    subtitle: "未优化平均评分",
                    color: .blue
                )
                
                QualityMetricCard(
                    title: "质量提升",
                    value: String(format: "%.1f%%", (optimizationEffectiveness.optimized - optimizationEffectiveness.nonOptimized)),
                    subtitle: "优化提升幅度",
                    color: optimizationEffectiveness.optimized > optimizationEffectiveness.nonOptimized ? .green : .red
                )
            }
        }
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("质量洞察")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(insights.indices, id: \.self) { index in
                InsightCard(insight: insights[index])
            }
        }
    }
    
    private var optimizationEffectivenessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("优化效果分析")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("优化后平均评分")
                    Spacer()
                    Text(String(format: "%.1f/5.0", optimizationEffectiveness.optimized))
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("未优化平均评分")
                    Spacer()
                    Text(String(format: "%.1f/5.0", optimizationEffectiveness.nonOptimized))
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("提升幅度")
                    Spacer()
                    Text(String(format: "%.1f%%", (optimizationEffectiveness.optimized - optimizationEffectiveness.nonOptimized) * 20))
                        .foregroundColor(optimizationEffectiveness.optimized > optimizationEffectiveness.nonOptimized ? .green : .red)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    private var averageRatingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("各项指标评分")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(TranslationQualityFeedbackManager.FeedbackType.allCases, id: \.self) { type in
                HStack {
                    Text(type.displayName)
                    Spacer()
                    Text(String(format: "%.1f/5.0", averageRatings[type] ?? 0))
                        .foregroundColor(averageRatings[type] ?? 0 >= 3.5 ? .green : .orange)
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private func loadInsights() {
        isLoading = true
        
        Task {
            async let insightsTask = feedbackManager.getQualityInsights()
            async let effectivenessTask = feedbackManager.getOptimizationEffectiveness()
            
            let (loadedInsights, effectiveness) = await (insightsTask, effectivenessTask)
            
            var ratings: [TranslationQualityFeedbackManager.FeedbackType: Double] = [:]
            for type in TranslationQualityFeedbackManager.FeedbackType.allCases {
                ratings[type] = await feedbackManager.getAverageRating(for: type)
            }
            
            await MainActor.run {
                self.insights = loadedInsights
                self.optimizationEffectiveness = effectiveness
                self.averageRatings = ratings
                self.isLoading = false
            }
        }
    }
}

struct QualityMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct InsightCard: View {
    let insight: TranslationQualityFeedbackManager.QualityInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.issueType.displayName)
                    .font(.headline)
                Spacer()
                Text(String(format: "%.1f%%", insight.severity * 100))
                    .foregroundColor(insight.severity > 0.5 ? .red : .orange)
            }
            
            Text("出现频率: \(insight.frequency)次")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("影响程度: \(String(format: "%.1f%%", insight.impact * 100))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !insight.commonPhrases.isEmpty {
                Text("常见问题短语:")
                    .font(.caption)
                    .fontWeight(.bold)
                Text(insight.commonPhrases.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !insight.suggestedImprovements.isEmpty {
                Text("建议改进:")
                    .font(.caption)
                    .fontWeight(.bold)
                ForEach(insight.suggestedImprovements, id: \.self) { improvement in
                    Text("• \(improvement)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    TranslationFeedbackView(
        originalText: "Hello, how are you today?",
        translatedText: "你好，你今天好吗？",
        sourceLanguage: "en",
        targetLanguage: "zh",
        wasOptimized: true,
        optimizationApplied: true
    )
}