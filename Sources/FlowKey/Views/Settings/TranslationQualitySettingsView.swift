import SwiftUI
import Foundation

struct TranslationQualitySettingsView: View {
    @State private var enableQualityOptimization = true
    @State private var optimizationStrategy = 1 // 0: accuracy, 1: balanced, 2: speed
    @State private var autoOptimize = true
    @State private var showQualityScore = true
    @State private var enableSuggestions = true
    @State private var minimumConfidence = 0.7
    @State private var optimizationThreshold = 0.1
    @State private var enableCulturalAdaptation = true
    @State private var enableContextAwareness = true
    @State private var enableTerminologyConsistency = true
    @State private var enableGrammarCheck = true
    @State private var enableFluencyCheck = true
    
    @State private var isProcessing = false
    @State private var qualityMetrics: TranslationQualityOptimizer.QualityMetrics?
    @State private var testText = "Hello, how are you today?"
    @State private var testTranslation = "你好，你今天好吗？"
    @State private var optimizedResult = ""
    
    var body: some View {
        Form {
            Section(header: Text("质量优化设置")) {
                Toggle("启用翻译质量优化", isOn: $enableQualityOptimization)
                Toggle("自动优化翻译", isOn: $autoOptimization)
                Toggle("显示质量评分", isOn: $showQualityScore)
                Toggle("启用改进建议", isOn: $enableSuggestions)
            }
            
            Section(header: Text("优化策略")) {
                Picker("优化策略", selection: $optimizationStrategy) {
                    Text("准确性优先").tag(0)
                    Text("平衡模式").tag(1)
                    Text("速度优先").tag(2)
                }
                .pickerStyle(.segmented)
                .disabled(!enableQualityOptimization)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("最小置信度: \(Int(minimumConfidence * 100))%")
                    Slider(value: $minimumConfidence, in: 0.5...1.0, step: 0.05)
                }
                .disabled(!enableQualityOptimization)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("优化阈值: \(Int(optimizationThreshold * 100))%")
                    Slider(value: $optimizationThreshold, in: 0.05...0.5, step: 0.05)
                }
                .disabled(!enableQualityOptimization)
            }
            
            Section(header: Text("质量检查项目")) {
                Toggle("文化适应性检查", isOn: $enableCulturalAdaptation)
                Toggle("上下文感知优化", isOn: $enableContextAwareness)
                Toggle("术语一致性检查", isOn: $enableTerminologyConsistency)
                Toggle("语法检查", isOn: $enableGrammarCheck)
                Toggle("流畅度检查", isOn: $enableFluencyCheck)
            }
            .disabled(!enableQualityOptimization)
            
            Section(header: Text("质量测试")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("原文")
                        .font(.headline)
                    Text(testText)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("当前翻译")
                        .font(.headline)
                    Text(testTranslation)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    if !optimizedResult.isEmpty {
                        Text("优化结果")
                            .font(.headline)
                        Text(optimizedResult)
                            .font(.body)
                            .foregroundColor(.green)
                    }
                    
                    if let metrics = qualityMetrics {
                        QualityMetricsView(metrics: metrics)
                    }
                }
                
                HStack {
                    Button("测试优化") {
                        testQualityOptimization()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isProcessing)
                    
                    Spacer()
                    
                    Button("重置") {
                        resetTest()
                    }
                    .buttonStyle(.bordered)
                }
                
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            Section(header: Text("优化统计")) {
                HStack {
                    Text("总优化次数")
                    Spacer()
                    Text("1,234")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("平均提升率")
                    Spacer()
                    Text("15.2%")
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("用户满意度")
                    Spacer()
                    Text("92%")
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("优化成功率")
                    Spacer()
                    Text("87%")
                        .foregroundColor(.green)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        // Load settings from user preferences
        let preferences = UserHabitIntegrationService.shared.getLearnedPreferences()
        
        // Load optimization settings
        enableQualityOptimization = preferences.optimizationEnabled ?? true
        autoOptimize = preferences.autoOptimize ?? true
        
        // Load strategy preference
        if let strategy = preferences.optimizationStrategy {
            optimizationStrategy = strategy
        }
        
        // Load confidence threshold
        if let confidence = preferences.minimumConfidence {
            minimumConfidence = confidence
        }
        
        // Load optimization threshold
        if let threshold = preferences.optimizationThreshold {
            optimizationThreshold = threshold
        }
    }
    
    private func saveSettings() {
        // Save settings to user preferences
        // This would be implemented to save to Core Data or UserDefaults
        print("Settings saved")
    }
    
    private func testQualityOptimization() {
        isProcessing = true
        
        Task {
            let strategy: TranslationQualityOptimizer.OptimizationStrategy
            switch optimizationStrategy {
            case 0: strategy = .accuracy
            case 1: strategy = .balanced
            case 2: strategy = .speed
            default: strategy = .balanced
            }
            
            let result = await TranslationService.shared.optimizeTranslationQuality(
                originalText: testText,
                translatedText: testTranslation,
                sourceLanguage: "en",
                targetLanguage: "zh",
                strategy: strategy
            )
            
            let metrics = await TranslationService.shared.getTranslationQualityAnalysis(
                originalText: testText,
                translatedText: testTranslation,
                sourceLanguage: "en",
                targetLanguage: "zh"
            )
            
            await MainActor.run {
                self.optimizedResult = result
                self.qualityMetrics = metrics
                self.isProcessing = false
            }
        }
    }
    
    private func resetTest() {
        optimizedResult = ""
        qualityMetrics = nil
    }
}

struct QualityMetricsView: View {
    let metrics: TranslationQualityOptimizer.QualityMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("总体质量")
                Spacer()
                Text(String(format: "%.1f%%", metrics.overallScore * 100))
                    .foregroundColor(metrics.overallScore >= 0.8 ? .green : .orange)
            }
            
            HStack {
                Text("准确性")
                Spacer()
                Text(String(format: "%.1f%%", metrics.accuracy * 100))
                    .foregroundColor(metrics.accuracy >= 0.8 ? .green : .orange)
            }
            
            HStack {
                Text("流畅度")
                Spacer()
                Text(String(format: "%.1f%%", metrics.fluency * 100))
                    .foregroundColor(metrics.fluency >= 0.8 ? .green : .orange)
            }
            
            HStack {
                Text("一致性")
                Spacer()
                Text(String(format: "%.1f%%", metrics.consistency * 100))
                    .foregroundColor(metrics.consistency >= 0.8 ? .green : .orange)
            }
            
            HStack {
                Text("文化适应性")
                Spacer()
                Text(String(format: "%.1f%%", metrics.culturalAppropriateness * 100))
                    .foregroundColor(metrics.culturalAppropriateness >= 0.8 ? .green : .orange)
            }
            
            HStack {
                Text("上下文保持")
                Spacer()
                Text(String(format: "%.1f%%", metrics.contextPreservation * 100))
                    .foregroundColor(metrics.contextPreservation >= 0.8 ? .green : .orange)
            }
        }
        .font(.caption)
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}

#Preview {
    TranslationQualitySettingsView()
}