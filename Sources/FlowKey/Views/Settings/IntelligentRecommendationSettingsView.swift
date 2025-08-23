import SwiftUI

struct IntelligentRecommendationSettingsView: View {
    @StateObject private var recommendationManager = IntelligentRecommendationManager.shared
    @State private var recommendationsEnabled = true
    @State private var autoRefresh = true
    @State private var refreshInterval = 30.0
    @State private var maxRecommendations = 10
    @State private var minConfidence = 0.5
    @State private var learningEnabled = true
    @State private var personalizedRecommendations = true
    @State private var contextAwareRecommendations = true
    @State private var timeBasedRecommendations = true
    @State private var showRecommendationsInOverlay = true
    @State private var recommendationHistoryEnabled = true
    @State private var analyticsEnabled = false
    
    // Recommendation type toggles
    @State private var phraseRecommendations = true
    @State private var translationRecommendations = true
    @State private var knowledgeRecommendations = true
    @State private var actionRecommendations = true
    @State private var completionRecommendations = true
    @State private var formattingRecommendations = true
    
    @State private var isProcessing = false
    @State private var statistics = RecommendationStatistics()
    
    var body: some View {
        Form {
            Section(header: Text("基础设置")) {
                Toggle("启用智能推荐", isOn: $recommendationsEnabled)
                Toggle("自动刷新", isOn: $autoRefresh)
                
                if autoRefresh {
                    VStack(alignment: .leading) {
                        Text("刷新间隔: \(Int(refreshInterval)) 秒")
                        Slider(value: $refreshInterval, in: 10...300, step: 10)
                    }
                }
                
                Stepper("最大推荐数量: \(maxRecommendations)", 
                       value: $maxRecommendations,
                       in: 1...50
                )
                
                VStack(alignment: .leading) {
                    Text("最小置信度: \(String(format: "%.0f%%", minConfidence * 100))")
                    Slider(value: $minConfidence, in: 0.1...1.0, step: 0.1)
                }
            }
            
            Section(header: Text("推荐类型")) {
                Toggle("常用语推荐", isOn: $phraseRecommendations)
                Toggle("翻译推荐", isOn: $translationRecommendations)
                Toggle("知识库推荐", isOn: $knowledgeRecommendations)
                Toggle("操作推荐", isOn: $actionRecommendations)
                Toggle("自动补全推荐", isOn: $completionRecommendations)
                Toggle("格式化推荐", isOn: $formattingRecommendations)
            }
            
            Section(header: Text("个性化设置")) {
                Toggle("启用学习功能", isOn: $learningEnabled)
                Toggle("个性化推荐", isOn: $personalizedRecommendations)
                Toggle("上下文感知推荐", isOn: $contextAwareRecommendations)
                Toggle("时间模式推荐", isOn: $timeBasedRecommendations)
            }
            
            Section(header: Text("显示设置")) {
                Toggle("在悬浮窗中显示推荐", isOn: $showRecommendationsInOverlay)
                Toggle("记录推荐历史", isOn: $recommendationHistoryEnabled)
                Toggle("启用分析统计", isOn: $analyticsEnabled)
            }
            
            Section(header: Text("数据管理")) {
                Button("清除推荐历史") {
                    clearRecommendationHistory()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                
                Button("重置学习模型") {
                    resetLearningModel()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                
                Button("导出推荐数据") {
                    exportRecommendationData()
                }
                .buttonStyle(.bordered)
                
                Button("重新训练模型") {
                    retrainModel()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing)
            }
            
            Section(header: Text("统计信息")) {
                StatisticsView(statistics: statistics)
                
                Button("刷新统计") {
                    loadStatistics()
                }
                .buttonStyle(.bordered)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            loadSettings()
            loadStatistics()
        }
    }
    
    // MARK: - Statistics View
    
    private struct StatisticsView: View {
        let statistics: RecommendationStatistics
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    StatItem(title: "总推荐数", value: "\(statistics.totalRecommendations)")
                    StatItem(title: "接受率", value: "\(String(format: "%.1f%%", statistics.acceptanceRate))")
                    StatItem(title: "平均置信度", value: "\(String(format: "%.1f%%", statistics.averageConfidence * 100))")
                }
                
                HStack {
                    StatItem(title: "今日推荐", value: "\(statistics.todayRecommendations)")
                    StatItem(title: "本周推荐", value: "\(statistics.weekRecommendations)")
                    StatItem(title: "本月推荐", value: "\(statistics.monthRecommendations)")
                }
                
                if !statistics.topRecommendationTypes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("热门推荐类型")
                            .font(.headline)
                        
                        ForEach(statistics.topRecommendationTypes.prefix(3), id: \.type) { item in
                            HStack {
                                Text(item.type)
                                Spacer()
                                Text("\(item.count)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private struct StatItem: View {
        let title: String
        let value: String
        
        var body: some View {
            VStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Methods
    
    private func loadSettings() {
        // Load settings from user preferences
        // This would load from UserDefaults or Core Data
    }
    
    private func loadStatistics() {
        isProcessing = true
        
        Task {
            // Load recommendation statistics
            await MainActor.run {
                self.statistics = RecommendationStatistics(
                    totalRecommendations: 1234,
                    acceptanceRate: 0.75,
                    averageConfidence: 0.82,
                    todayRecommendations: 45,
                    weekRecommendations: 234,
                    monthRecommendations: 892,
                    topRecommendationTypes: [
                        RecommendationTypeCount(type: "常用语", count: 456),
                        RecommendationTypeCount(type: "翻译", count: 234),
                        RecommendationTypeCount(type: "知识库", count: 178),
                        RecommendationTypeCount(type: "操作", count: 145),
                        RecommendationTypeCount(type: "补全", count: 98),
                        RecommendationTypeCount(type: "格式化", count: 67)
                    ]
                )
                self.isProcessing = false
            }
        }
    }
    
    private func clearRecommendationHistory() {
        let alert = NSAlert()
        alert.messageText = "清除推荐历史"
        alert.informativeText = "确定要清除所有推荐历史记录吗？此操作不可撤销。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            // Clear recommendation history
            isProcessing = true
            
            Task {
                // Perform clear operation
                await MainActor.run {
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func resetLearningModel() {
        let alert = NSAlert()
        alert.messageText = "重置学习模型"
        alert.informativeText = "确定要重置学习模型吗？这将清除所有学习数据，系统需要重新学习您的习惯。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            // Reset learning model
            isProcessing = true
            
            Task {
                // Perform reset operation
                await MainActor.run {
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func exportRecommendationData() {
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["json"]
        savePanel.nameFieldStringValue = "recommendation_data_\(Date().timeIntervalSince1970).json"
        
        if savePanel.runModal() == .OK {
            guard let url = savePanel.url else { return }
            
            isProcessing = true
            
            Task {
                do {
                    // Export recommendation data
                    let data = try JSONEncoder().encode(statistics)
                    try data.write(to: url)
                    
                    await MainActor.run {
                        self.isProcessing = false
                    }
                } catch {
                    await MainActor.run {
                        self.isProcessing = false
                    }
                }
            }
        }
    }
    
    private func retrainModel() {
        isProcessing = true
        
        Task {
            // Retrain recommendation model
            try? await Task.sleep(nanoseconds: 2_000_000_000) // Simulate training
            
            await MainActor.run {
                self.isProcessing = false
            }
        }
    }
}

// MARK: - Supporting Structures

struct RecommendationStatistics {
    let totalRecommendations: Int
    let acceptanceRate: Double
    let averageConfidence: Double
    let todayRecommendations: Int
    let weekRecommendations: Int
    let monthRecommendations: Int
    let topRecommendationTypes: [RecommendationTypeCount]
}

struct RecommendationTypeCount {
    let type: String
    let count: Int
}

#Preview {
    IntelligentRecommendationSettingsView()
}