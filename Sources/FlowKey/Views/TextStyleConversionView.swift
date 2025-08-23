import SwiftUI
import UserNotifications

struct TextStyleConversionView: View {
    @StateObject private var conversionService = TextStyleConversionService.shared
    @State private var inputText = ""
    @State private var convertedText = ""
    @State private var selectedStyle: TextStyleConversionService.TextStyle = .formal
    @State private var isConverting = false
    @State private var showStyleAnalysis = false
    @State private var showRecommendations = false
    @State private var styleAnalysis: TextStyleConversionService.StyleAnalysis?
    @State private var recommendations: [StyleRecommendation] = []
    @State private var conversionResult: TextStyleConversionService.ConversionResult?
    @State private var showAdvancedOptions = false
    @State private var preserveMeaning = true
    @State private var adaptToContext = true
    @State private var maintainTone = false
    @State private var applyGrammar = true
    @State private var useAdvancedVocab = false
    @State private var customInstructions = ""
    @State private var showingHistory = false
    @State private var conversionHistory: [ConversionHistoryItem] = []
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView
            
            // Main Content
            if showingHistory {
                historyView
            } else {
                mainConversionView
            }
        }
        .padding()
        .frame(width: 900, height: 700)
        .sheet(isPresented: $showRecommendations) {
            StyleRecommendationsSheet(recommendations: recommendations) { style in
                selectedStyle = style
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("文本风格转换")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("智能转换文本风格，提升表达效果")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    showingHistory.toggle()
                }) {
                    Label("历史记录", systemImage: "clock.arrow.circlepath")
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    showRecommendationsSheet()
                }) {
                    Label("风格推荐", systemImage: "lightbulb")
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    clearAll()
                }) {
                    Label("清空", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
        }
    }
    
    private var mainConversionView: some View {
        VStack(spacing: 20) {
            // Input Section
            inputSection
            
            // Style Selection
            styleSelectionSection
            
            // Advanced Options
            if showAdvancedOptions {
                advancedOptionsSection
            }
            
            // Convert Button
            convertButton
            
            // Results Section
            if let result = conversionResult {
                resultsSection(result: result)
            }
            
            // Style Analysis
            if let analysis = styleAnalysis, showStyleAnalysis {
                styleAnalysisSection(analysis: analysis)
            }
        }
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("输入文本")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    analyzeStyle()
                }) {
                    Label("分析风格", systemImage: "magnifyingglass")
                }
                .buttonStyle(.bordered)
                .disabled(inputText.isEmpty || isConverting)
            }
            
            TextEditor(text: $inputText)
                .font(.body)
                .scrollContentBackground(.hidden)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .frame(height: 150)
            
            HStack {
                Text("\(inputText.count) 字符")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let analysis = styleAnalysis {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(analysis.detectedStyle.color))
                            .frame(width: 8, height: 8)
                        Text("检测到: \(analysis.detectedStyle.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var styleSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("目标风格")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showAdvancedOptions.toggle()
                }) {
                    Label(showAdvancedOptions ? "收起选项" : "高级选项", systemImage: "gear")
                }
                .buttonStyle(.bordered)
            }
            
            // Style Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(TextStyleConversionService.TextStyle.allCases, id: \.self) { style in
                    StyleSelectionCard(
                        style: style,
                        isSelected: selectedStyle == style,
                        onTap: {
                            selectedStyle = style
                        }
                    )
                }
            }
        }
    }
    
    private var advancedOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("高级选项")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("保持原意", isOn: $preserveMeaning)
                Toggle("适应上下文", isOn: $adaptToContext)
                Toggle("保持语调", isOn: $maintainTone)
                Toggle("应用语法规则", isOn: $applyGrammar)
                Toggle("使用高级词汇", isOn: $useAdvancedVocab)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("自定义指令")
                    .font(.subheadline)
                
                TextEditor(text: $customInstructions)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .frame(height: 60)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var convertButton: some View {
        Button(action: {
            convertText()
        }) {
            HStack {
                if isConverting {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                Text(isConverting ? "转换中..." : "开始转换")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(inputText.isEmpty || isConverting)
    }
    
    private func resultsSection(result: TextStyleConversionService.ConversionResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("转换结果")
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text("置信度: \(Int(result.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(result.confidence > 0.7 ? .green : .orange)
                    
                    Text("耗时: \(String(format: "%.2f", result.processingTime))s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Converted Text
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("转换后文本")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("复制") {
                        copyToClipboard(result.convertedText)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                ScrollView {
                    Text(result.convertedText)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 120)
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            // Changes Summary
            if !result.changes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("修改摘要")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(result.changes.prefix(10), id: \.original) { change in
                                HStack {
                                    Text(change.original)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .strikethrough()
                                    
                                    Text("→")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(change.replacement)
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    
                                    Spacer()
                                    
                                    Text(change.reason)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(4)
                            }
                        }
                    }
                    .frame(height: 80)
                }
            }
            
            // Suggestions
            if !result.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("改进建议")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(result.suggestions, id: \.self) { suggestion in
                        HStack {
                            Image(systemName: "lightbulb")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            
                            Text(suggestion)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
            }
            
            // Action Buttons
            HStack {
                Button("保存到历史") {
                    saveToHistory(result: result)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("应用修改") {
                    inputText = result.convertedText
                    conversionResult = nil
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func styleAnalysisSection(analysis: TextStyleConversionService.StyleAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("风格分析")
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(analysis.detectedStyle.color))
                        .frame(width: 8, height: 8)
                    Text("\(analysis.detectedStyle.displayName) (置信度: \(Int(analysis.confidence * 100))%)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Scores
            HStack(spacing: 16) {
                ScoreCard(title: "可读性", score: analysis.readabilityScore, color: .blue)
                ScoreCard(title: "复杂度", score: analysis.complexityScore, color: .orange)
                ScoreCard(title: "正式度", score: analysis.formalityScore, color: .green)
            }
            
            // Characteristics
            VStack(alignment: .leading, spacing: 8) {
                Text("文本特征")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(analysis.characteristics, id: \.name) { characteristic in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(characteristic.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(String(format: "%.2f", characteristic.value))
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                            
                            ProgressView(value: characteristic.value, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            
                            Text(characteristic.description)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var historyView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("转换历史")
                    .font(.headline)
                
                Spacer()
                
                Button("返回") {
                    showingHistory = false
                }
                .buttonStyle(.bordered)
            }
            
            if conversionHistory.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "clock")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("暂无转换历史")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("完成文本转换后，历史记录将显示在这里")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(conversionHistory, id: \.id) { item in
                            HistoryItemCard(item: item) {
                                inputText = item.originalText
                                selectedStyle = item.targetStyle
                                showingHistory = false
                                conversionResult = nil
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func analyzeStyle() {
        guard !inputText.isEmpty else { return }
        
        Task {
            let analysis = await conversionService.analyzeTextStyle(inputText)
            
            await MainActor.run {
                self.styleAnalysis = analysis
                self.showStyleAnalysis = true
            }
        }
    }
    
    private func convertText() {
        guard !inputText.isEmpty else { return }
        
        isConverting = true
        
        let options = TextStyleConversionService.ConversionOptions(
            targetStyle: selectedStyle,
            preserveOriginalMeaning: preserveMeaning,
            adaptToContext: adaptToContext,
            maintainTone: maintainTone,
            applyGrammarRules: applyGrammar,
            useAdvancedVocabulary: useAdvancedVocab,
            customInstructions: customInstructions.isEmpty ? nil : customInstructions
        )
        
        Task {
            do {
                let result = try await conversionService.convertText(inputText, to: selectedStyle, options: options)
                
                await MainActor.run {
                    self.conversionResult = result
                    self.isConverting = false
                }
                
                // Auto-analyze the converted text
                if showStyleAnalysis {
                    let newAnalysis = await conversionService.analyzeTextStyle(result.convertedText)
                    await MainActor.run {
                        self.styleAnalysis = newAnalysis
                    }
                }
            } catch {
                await MainActor.run {
                    self.isConverting = false
                    // Show error alert
                    let alert = NSAlert()
                    alert.messageText = "转换失败"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "确定")
                    alert.runModal()
                }
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Show notification using modern UserNotifications framework
        let notification = UNMutableNotificationContent()
        notification.title = "已复制到剪贴板"
        notification.body = "文本已成功复制到剪贴板"
        notification.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to show notification: \(error)")
            }
        }
    }
    
    private func saveToHistory(result: TextStyleConversionService.ConversionResult) {
        let historyItem = ConversionHistoryItem(
            id: UUID(),
            originalText: result.originalText,
            convertedText: result.convertedText,
            targetStyle: result.targetStyle,
            timestamp: Date(),
            confidence: result.confidence
        )
        
        conversionHistory.insert(historyItem, at: 0)
        
        // Keep only last 50 items
        if conversionHistory.count > 50 {
            conversionHistory.removeLast()
        }
        
        // Show notification using modern UserNotifications framework
        let notification = UNMutableNotificationContent()
        notification.title = "已保存到历史记录"
        notification.body = "转换结果已保存到历史记录"
        notification.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to show notification: \(error)")
            }
        }
    }
    
    private func clearAll() {
        inputText = ""
        convertedText = ""
        conversionResult = nil
        styleAnalysis = nil
        showStyleAnalysis = false
        customInstructions = ""
    }
}

// MARK: - Supporting Views

struct StyleSelectionCard: View {
    let style: TextStyleConversionService.TextStyle
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: style.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : Color(style.color))
                
                Text(style.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(style.description)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(isSelected ? Color(style.color) : Color(NSColor.controlBackgroundColor))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ScoreCard: View {
    let title: String
    let score: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(String(format: "%.1f", score * 100))
                .font(.headline)
                .foregroundColor(color)
            
            ProgressView(value: score, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(width: 60)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}

struct HistoryItemCard: View {
    let item: ConversionHistoryItem
    let onRestore: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack {
                    Circle()
                        .fill(Color(item.targetStyle.color))
                        .frame(width: 8, height: 8)
                    
                    Text(item.targetStyle.displayName)
                        .font(.headline)
                }
                
                Spacer()
                
                Text(item.timestamp.formatted())
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(item.confidence > 0.7 ? .green : .orange)
                    
                    Text("\(Int(item.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("原文:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(item.originalText)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("转换后:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(item.convertedText)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundColor(.primary)
            }
            
            HStack {
                Button("恢复") {
                    onRestore()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                Button("复制结果") {
                    copyToClipboard(item.convertedText)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Show notification using modern UserNotifications framework
        let notification = UNMutableNotificationContent()
        notification.title = "已复制到剪贴板"
        notification.body = "文本已成功复制到剪贴板"
        notification.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to show notification: \(error)")
            }
        }
    }
}

// MARK: - Data Models

struct ConversionHistoryItem {
    let id: UUID
    let originalText: String
    let convertedText: String
    let targetStyle: TextStyleConversionService.TextStyle
    let timestamp: Date
    let confidence: Double
}

// MARK: - Recommendations Sheet

struct StyleRecommendationsSheet: View {
    let recommendations: [StyleRecommendation]
    let onStyleSelected: (TextStyleConversionService.TextStyle) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if recommendations.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "lightbulb.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("暂无推荐")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("分析文本后，推荐的风格将显示在这里")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(recommendations, id: \.style.displayName) { recommendation in
                                StyleRecommendationCard(recommendation: recommendation) {
                                    onStyleSelected(recommendation.style)
                                    dismiss()
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("风格推荐")
                        .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
    }
}

struct StyleRecommendationCard: View {
    let recommendation: StyleRecommendation
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack {
                    Circle()
                        .fill(Color(recommendation.style.color))
                        .frame(width: 12, height: 12)
                    
                    Text(recommendation.style.displayName)
                        .font(.headline)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Text("\(Int(recommendation.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(recommendation.reason)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            Button("应用此风格") {
                onSelect()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Extensions

extension TextStyleConversionView {
    private func showRecommendationsSheet() {
        Task {
            let recommendations = await conversionService.getStyleRecommendations(for: inputText)
            
            await MainActor.run {
                self.recommendations = recommendations
                self.showRecommendations = true
            }
        }
    }
}

// #Preview {
//     TextStyleConversionView()
// }