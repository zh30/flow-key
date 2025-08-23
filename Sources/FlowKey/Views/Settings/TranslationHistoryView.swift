import SwiftUI

struct TranslationHistoryView: View {
    @State private var historyRecords: [TranslationHistoryManager.TranslationRecord] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var showStatistics = false
    @State private var selectedRecord: TranslationHistoryManager.TranslationRecord?
    
    private let historyManager = TranslationHistoryManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("翻译历史")
                    .font(.headline)
                Spacer()
                
                Button(action: {
                    showStatistics = true
                }) {
                    Label("统计", systemImage: "chart.bar")
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    clearHistory()
                }) {
                    Label("清空", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding()
            
            Divider()
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索翻译记录...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // History List
            if isLoading {
                ProgressView("加载中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredRecords.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("没有找到翻译记录")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("开始使用翻译功能后，您的翻译记录将显示在这里")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredRecords) { record in
                    HistoryRecordRow(record: record)
                        .onTapGesture {
                            selectedRecord = record
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteRecord(record)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
                .listStyle(.plain)
            }
        }
        .onAppear {
            loadHistory()
        }
        .onChange(of: searchText) { _ in
            filterHistory()
        }
        .sheet(isPresented: $showStatistics) {
            TranslationStatisticsView()
        }
        .sheet(item: $selectedRecord) { record in
            TranslationRecordDetailView(record: record)
        }
    }
    
    private var filteredRecords: [TranslationHistoryManager.TranslationRecord] {
        if searchText.isEmpty {
            return historyRecords
        } else {
            return historyManager.searchHistory(query: searchText, limit: 100)
        }
    }
    
    private func loadHistory() {
        isLoading = true
        
        Task {
            let records = historyManager.getTranslationHistory(limit: 100)
            await MainActor.run {
                self.historyRecords = records
                self.isLoading = false
            }
        }
    }
    
    private func filterHistory() {
        isLoading = true
        
        Task {
            let records = filteredRecords
            await MainActor.run {
                self.historyRecords = records
                self.isLoading = false
            }
        }
    }
    
    private func deleteRecord(_ record: TranslationHistoryManager.TranslationRecord) {
        historyManager.deleteTranslationRecord(withId: record.id)
        loadHistory()
    }
    
    private func clearHistory() {
        let alert = NSAlert()
        alert.messageText = "清空翻译历史"
        alert.informativeText = "确定要清空所有翻译历史记录吗？此操作无法撤销。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "取消")
        alert.addButton(withTitle: "清空")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            historyManager.clearAllHistory()
            loadHistory()
        }
    }
}

// MARK: - History Record Row

struct HistoryRecordRow: View {
    let record: TranslationHistoryManager.TranslationRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(languagePairString)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(4)
                
                Spacer()
                
                Text(formatDate(record.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.originalText)
                    .font(.body)
                    .lineLimit(2)
                
                if !record.translatedText.isEmpty {
                    HStack {
                        Image(systemName: "arrow.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(record.translatedText)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            
            if let mode = translationModeString {
                HStack {
                    Text(mode)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let confidence = record.confidence {
                        Text("置信度: \(Int(confidence * 100))%")
                            .font(.caption)
                            .foregroundColor(confidence > 0.7 ? .green : .orange)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var languagePairString: String {
        let sourceFlag = flag(for: record.sourceLanguage)
        let targetFlag = flag(for: record.targetLanguage)
        return "\(sourceFlag) \(record.sourceLanguage.uppercased()) → \(targetFlag) \(record.targetLanguage.uppercased())"
    }
    
    private var translationModeString: String? {
        switch record.translationMode {
        case "online": return "在线翻译"
        case "local": return "本地翻译"
        case "hybrid": return "混合翻译"
        default: return nil
        }
    }
    
    private func flag(for language: String) -> String {
        switch language {
        case "en": return "🇺🇸"
        case "zh": return "🇨🇳"
        case "ja": return "🇯🇵"
        case "ko": return "🇰🇷"
        case "fr": return "🇫🇷"
        case "de": return "🇩🇪"
        case "es": return "🇪🇸"
        case "ru": return "🇷🇺"
        case "pt": return "🇵🇹"
        case "it": return "🇮🇹"
        default: return "🌐"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Translation Record Detail View

struct TranslationRecordDetailView: View {
    let record: TranslationHistoryManager.TranslationRecord
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("翻译详情")
                .font(.headline)
            
            VStack(spacing: 16) {
                // Original Text
                VStack(alignment: .leading, spacing: 8) {
                    Text("原文")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(record.originalText)
                        .font(.body)
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                }
                
                // Translated Text
                VStack(alignment: .leading, spacing: 8) {
                    Text("译文")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(record.translatedText)
                        .font(.body)
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                }
                
                // Metadata
                VStack(alignment: .leading, spacing: 8) {
                    Text("详细信息")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                        GridRow {
                            Text("源语言:")
                                .foregroundColor(.secondary)
                            Text(record.sourceLanguage.uppercased())
                        }
                        
                        GridRow {
                            Text("目标语言:")
                                .foregroundColor(.secondary)
                            Text(record.targetLanguage.uppercased())
                        }
                        
                        GridRow {
                            Text("翻译模式:")
                                .foregroundColor(.secondary)
                            Text(translationModeString)
                        }
                        
                        GridRow {
                            Text("时间:")
                                .foregroundColor(.secondary)
                            Text(formatDate(record.timestamp))
                        }
                        
                        if let confidence = record.confidence {
                            GridRow {
                                Text("置信度:")
                                    .foregroundColor(.secondary)
                                Text("\(Int(confidence * 100))%")
                                    .foregroundColor(confidence > 0.7 ? .green : .orange)
                            }
                        }
                    }
                }
            }
            
            HStack {
                Button("复制原文") {
                    copyToClipboard(record.originalText)
                }
                .buttonStyle(.bordered)
                
                Button("复制译文") {
                    copyToClipboard(record.translatedText)
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button("关闭") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 500, height: 600)
    }
    
    private var translationModeString: String {
        switch record.translationMode {
        case "online": return "在线翻译"
        case "local": return "本地翻译"
        case "hybrid": return "混合翻译"
        default: return "未知"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

// MARK: - Translation Statistics View

struct TranslationStatisticsView: View {
    @State private var statistics: HistoryStatistics?
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    private let historyManager = TranslationHistoryManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("翻译统计")
                .font(.headline)
            
            if isLoading {
                ProgressView("加载中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let stats = statistics {
                VStack(spacing: 16) {
                    // Overview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("概览")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            StatCard(title: "总翻译数", value: "\(stats.totalTranslations)", icon: "doc.text")
                            StatCard(title: "语言对", value: "\(stats.uniqueLanguagePairs)", icon: "globe")
                            StatCard(title: "平均置信度", value: "\(Int(stats.averageConfidence * 100))%", icon: "chart.line.uptrend.xyaxis")
                        }
                    }
                    
                    // Language Pairs
                    if let mostUsed = stats.mostUsedLanguagePair {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("最常用语言对")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(mostUsed)
                                    .font(.body)
                                    .padding()
                                    .background(Color.accentColor.opacity(0.2))
                                    .cornerRadius(8)
                                
                                Spacer()
                            }
                        }
                    }
                    
                    // Translation Modes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("翻译模式分布")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        ForEach(Array(stats.translationsByMode.keys.sorted()), id: \.self) { mode in
                            HStack {
                                Text(modeString(for: mode))
                                    .font(.body)
                                
                                Spacer()
                                
                                Text("\(stats.translationsByMode[mode] ?? 0)")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            HStack {
                Spacer()
                
                Button("关闭") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 400, height: 500)
        .onAppear {
            loadStatistics()
        }
    }
    
    private func loadStatistics() {
        isLoading = true
        
        Task {
            let stats = historyManager.getHistoryStatistics()
            await MainActor.run {
                self.statistics = stats
                self.isLoading = false
            }
        }
    }
    
    private func modeString(for mode: String) -> String {
        switch mode {
        case "online": return "在线翻译"
        case "local": return "本地翻译"
        case "hybrid": return "混合翻译"
        default: return mode
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}