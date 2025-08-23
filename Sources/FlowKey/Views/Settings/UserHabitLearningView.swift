import SwiftUI

struct UserHabitLearningView: View {
    @State private var learnedPreferences: UserPreferences = UserPreferences()
    @State private var habitInsights: [HabitInsight] = []
    @State private var isLoading = false
    @State private var showHabitDetails = false
    @State private var selectedInsight: HabitInsight?
    @State private var enableLearning = true
    @State private var dataRetentionDays = 90
    @State private var habitHistory: [UserHabitData] = []
    
    private let habitManager = UserHabitManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("用户习惯学习")
                    .font(.headline)
                Spacer()
                
                Button(action: {
                    loadData()
                }) {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            Divider()
            
            if isLoading {
                ProgressView("正在分析用户习惯...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Learning Settings
                        LearningSettingsSection(
                            enableLearning: $enableLearning,
                            dataRetentionDays: $dataRetentionDays
                        )
                        
                        // Learned Preferences
                        if !learnedPreferences.preferredLanguages.isEmpty ||
                           !learnedPreferences.activeHours.isEmpty {
                            LearnedPreferencesSection(preferences: learnedPreferences)
                        }
                        
                        // Habit Insights
                        if !habitInsights.isEmpty {
                            HabitInsightsSection(
                                insights: habitInsights,
                                onInsightSelected: { insight in
                                    selectedInsight = insight
                                    showHabitDetails = true
                                }
                            )
                        }
                        
                        // Habit History
                        if !habitHistory.isEmpty {
                            HabitHistorySection(history: habitHistory)
                        }
                        
                        // Actions
                        ActionSection(
                            onClearHabits: {
                                clearAllHabits()
                            },
                            onExportData: {
                                exportHabitData()
                            }
                        )
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadData()
        }
        .sheet(isPresented: $showHabitDetails) {
            if let insight = selectedInsight {
                HabitInsightDetailView(insight: insight) {
                    showHabitDetails = false
                }
            }
        }
    }
    
    private func loadData() {
        isLoading = true
        
        Task {
            // Load learned preferences
            let preferences = habitManager.getLearnedPreferences()
            
            // Load habit insights
            let insights = habitManager.getHabitInsights()
            
            // Load habit history (mock data for now)
            let history = generateMockHabitHistory()
            
            await MainActor.run {
                self.learnedPreferences = preferences
                self.habitInsights = insights
                self.habitHistory = history
                self.isLoading = false
            }
        }
    }
    
    private func generateMockHabitHistory() -> [UserHabitData] {
        return [
            UserHabitData(
                type: "翻译习惯",
                action: "英译中",
                frequency: 156,
                lastUsed: Date().addingTimeInterval(-3600),
                confidence: 0.92
            ),
            UserHabitData(
                type: "文本检测",
                action: "URL检测",
                frequency: 89,
                lastUsed: Date().addingTimeInterval(-7200),
                confidence: 0.87
            ),
            UserHabitData(
                type: "快捷键使用",
                action: "三下空格",
                frequency: 234,
                lastUsed: Date().addingTimeInterval(-1800),
                confidence: 0.95
            ),
            UserHabitData(
                type: "时间模式",
                action: "上午翻译",
                frequency: 78,
                lastUsed: Date().addingTimeInterval(-86400),
                confidence: 0.76
            )
        ]
    }
    
    private func clearAllHabits() {
        let alert = NSAlert()
        alert.messageText = "清除所有习惯数据"
        alert.informativeText = "确定要清除所有用户习惯数据吗？此操作无法撤销。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "取消")
        alert.addButton(withTitle: "清除")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            habitManager.clearAllHabits()
            loadData()
        }
    }
    
    private func exportHabitData() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "flowkey_habits_\(Date().formatted(.iso8601)).json"
        
        if savePanel.runModal() == .OK {
            guard let url = savePanel.url else { return }
            
            // Export habit data to JSON
            let exportData = [
                "export_date": Date().formatted(.iso8601),
                "preferences": learnedPreferences,
                "insights": habitInsights.map { insight in
                    [
                        "type": insight.type,
                        "title": insight.title,
                        "description": insight.description,
                        "priority": insight.priority.rawValue,
                        "timestamp": insight.timestamp.formatted(.iso8601)
                    ]
                }
            ]
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
                try jsonData.write(to: url)
                
                let successAlert = NSAlert()
                successAlert.messageText = "导出成功"
                successAlert.informativeText = "习惯数据已导出到：\(url.path)"
                successAlert.alertStyle = .informational
                successAlert.addButton(withTitle: "确定")
                successAlert.runModal()
            } catch {
                let errorAlert = NSAlert()
                errorAlert.messageText = "导出失败"
                errorAlert.informativeText = error.localizedDescription
                errorAlert.alertStyle = .critical
                errorAlert.addButton(withTitle: "确定")
                errorAlert.runModal()
            }
        }
    }
}

// MARK: - Learning Settings Section

struct LearningSettingsSection: View {
    @Binding var enableLearning: Bool
    @Binding var dataRetentionDays: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习设置")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                Toggle("启用习惯学习", isOn: $enableLearning)
                    .toggleStyle(.switch)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("数据保留期: \(dataRetentionDays) 天")
                        .font(.subheadline)
                    
                    Slider(value: Binding(
                        get: { Double(dataRetentionDays) },
                        set: { dataRetentionDays = Int($0) }
                    ), in: 30...365, step: 30)
                    .accentColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("学习功能将:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• 记录您的翻译偏好")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• 分析文本检测模式")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• 优化快捷键建议")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• 个性化操作建议")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

// MARK: - Learned Preferences Section

struct LearnedPreferencesSection: View {
    let preferences: UserPreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习到的偏好")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                if !preferences.preferredLanguages.isEmpty {
                    PreferenceRow(
                        title: "常用语言对",
                        value: preferences.preferredLanguages.joined(separator: ", "),
                        icon: "globe"
                    )
                }
                
                if !preferences.activeHours.isEmpty {
                    PreferenceRow(
                        title: "活跃时段",
                        value: formatActiveHours(preferences.activeHours),
                        icon: "clock"
                    )
                }
                
                if let translationPatterns = preferences.translationPatterns["most_used"] as? String {
                    PreferenceRow(
                        title: "常用翻译模式",
                        value: translationPatterns,
                        icon: "arrow.triangle.2.circlepath"
                    )
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    private func formatActiveHours(_ hours: [Int]) -> String {
        guard !hours.isEmpty else { return "无数据" }
        
        let hourNames = [
            0: "午夜", 1: "凌晨1点", 2: "凌晨2点", 3: "凌晨3点", 4: "凌晨4点", 5: "凌晨5点",
            6: "早上6点", 7: "早上7点", 8: "早上8点", 9: "早上9点", 10: "上午10点", 11: "上午11点",
            12: "中午", 13: "下午1点", 14: "下午2点", 15: "下午3点", 16: "下午4点", 17: "下午5点",
            18: "傍晚6点", 19: "晚上7点", 20: "晚上8点", 21: "晚上9点", 22: "晚上10点", 23: "晚上11点"
        ]
        
        return hours.compactMap { hourNames[$0] }.joined(separator: ", ")
    }
}

// MARK: - Habit Insights Section

struct HabitInsightsSection: View {
    let insights: [HabitInsight]
    let onInsightSelected: (HabitInsight) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("习惯洞察")
                    .font(.headline)
                Spacer()
                Text("\(insights.count) 项洞察")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(insights.prefix(6), id: \.timestamp) { insight in
                    HabitInsightCard(insight: insight) {
                        onInsightSelected(insight)
                    }
                }
            }
        }
    }
}

// MARK: - Habit Insight Card

struct HabitInsightCard: View {
    let insight: HabitInsight
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    PriorityBadge(priority: insight.priority)
                }
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Text(formatDate(insight.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .hoverEffect(.lift)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Habit History Section

struct HabitHistorySection: View {
    let history: [UserHabitData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("习惯历史")
                    .font(.headline)
                Spacer()
                Text("\(history.count) 项记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            ForEach(history, id: \.type) { habit in
                HabitHistoryRow(habit: habit)
            }
        }
    }
}

// MARK: - Habit History Row

struct HabitHistoryRow: View {
    let habit: UserHabitData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.type)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(habit.action)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(habit.frequency) 次")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("置信度: \(Int(habit.confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Action Section

struct ActionSection: View {
    let onClearHabits: () -> Void
    let onExportData: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("数据管理")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                Button(action: onExportData) {
                    Label("导出数据", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(action: onClearHabits) {
                    Label("清除数据", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

// MARK: - Supporting Views

struct PreferenceRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
}

struct PriorityBadge: View {
    let priority: HabitPriority
    
    var body: some View {
        Text(priority.displayName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    private func priorityColor() -> Color {
        switch priority {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Habit Insight Detail View

struct HabitInsightDetailView: View {
    let insight: HabitInsight
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("习惯洞察详情")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    PriorityBadge(priority: insight.priority)
                    Spacer()
                    Text(formatDate(insight.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(insight.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(insight.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("相关数据")
                        .font(.headline)
                    
                    ForEach(Array(insight.data.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(insight.data[key] ?? "")")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .padding()
            
            HStack {
                Button("关闭") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 400, height: 500)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Data Structures

struct UserHabitData {
    let type: String
    let action: String
    let frequency: Int
    let lastUsed: Date
    let confidence: Double
}

// MARK: - View Extensions

extension View {
    func hoverEffect(_ effect: HoverEffect) -> some View {
        self.onHover { isHovered in
            switch effect {
            case .lift:
                withAnimation(.easeInOut(duration: 0.2)) {
                    // Scale effect would be implemented here
                }
            }
        }
    }
}

enum HoverEffect {
    case lift
    case highlight
    case none
}