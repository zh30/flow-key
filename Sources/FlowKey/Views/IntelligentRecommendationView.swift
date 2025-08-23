import SwiftUI
import Combine

struct IntelligentRecommendationView: View {
    @StateObject private var recommendationManager = IntelligentRecommendationManager.shared
    @StateObject private var phraseManager = PhraseManager.shared
    @State private var recommendations: [IntelligentRecommendationManager.Recommendation] = []
    @State private var isLoading = false
    @State private var currentContext: IntelligentRecommendationManager.RecommendationContext?
    @State private var selectedRecommendation: IntelligentRecommendationManager.Recommendation?
    @State private var showDetailSheet = false
    @State private var refreshTimer: Timer?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Content
            if isLoading {
                loadingView
            } else if recommendations.isEmpty {
                emptyStateView
            } else {
                recommendationsList
            }
        }
        .onAppear {
            initializeRecommendations()
        }
        .onDisappear {
            stopAutoRefresh()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("智能推荐")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("基于您的使用习惯智能推荐")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: refreshRecommendations) {
                Image(systemName: "arrow.clockwise")
                    .font(.title3)
            }
            .buttonStyle(.bordered)
            .disabled(isLoading)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("正在分析您的使用习惯...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("暂无推荐")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("继续使用应用，我们将根据您的习惯提供智能推荐")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Recommendations List
    
    private var recommendationsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(recommendations, id: \.id) { recommendation in
                    RecommendationCard(
                        recommendation: recommendation,
                        onTap: {
                            selectedRecommendation = recommendation
                            showDetailSheet = true
                        },
                        onAccept: {
                            acceptRecommendation(recommendation)
                        },
                        onDismiss: {
                            dismissRecommendation(recommendation)
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Methods
    
    private func initializeRecommendations() {
        isLoading = true
        
        Task {
            await loadRecommendations()
            startAutoRefresh()
        }
    }
    
    private func loadRecommendations() async {
        guard let context = getCurrentContext() else { return }
        
        let newRecommendations = await recommendationManager.getRecommendations(for: context)
        
        await MainActor.run {
            self.recommendations = newRecommendations
            self.currentContext = context
            self.isLoading = false
        }
    }
    
    private func refreshRecommendations() {
        isLoading = true
        
        Task {
            await loadRecommendations()
        }
    }
    
    private func getCurrentContext() -> IntelligentRecommendationManager.RecommendationContext? {
        // Get current application context
        let currentApp = getCurrentApplication()
        let selectedText = getSelectedText()
        
        return IntelligentRecommendationManager.RecommendationContext(
            currentApp: currentApp,
            selectedText: selectedText
        )
    }
    
    private func getCurrentApplication() -> String {
        // Get current application name
        // This would use NSWorkspace to get the frontmost application
        return "FlowKey" // Placeholder
    }
    
    private func getSelectedText() -> String? {
        // Get currently selected text from system
        // This would use accessibility APIs
        return nil // Placeholder
    }
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            refreshRecommendations()
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func acceptRecommendation(_ recommendation: IntelligentRecommendationManager.Recommendation) {
        // Handle recommendation acceptance
        recommendationManager.recordRecommendationInteraction(
            recommendationId: recommendation.id,
            action: "accepted"
        )
        
        // Execute the recommendation based on type
        executeRecommendation(recommendation)
        
        // Remove from list
        recommendations.removeAll { $0.id == recommendation.id }
    }
    
    private func dismissRecommendation(_ recommendation: IntelligentRecommendationManager.Recommendation) {
        // Handle recommendation dismissal
        recommendationManager.recordRecommendationInteraction(
            recommendationId: recommendation.id,
            action: "dismissed"
        )
        
        // Remove from list
        recommendations.removeAll { $0.id == recommendation.id }
    }
    
    private func executeRecommendation(_ recommendation: IntelligentRecommendationManager.Recommendation) {
        switch recommendation.type {
        case .phrase:
            executePhraseRecommendation(recommendation)
        case .translation:
            executeTranslationRecommendation(recommendation)
        case .knowledge:
            executeKnowledgeRecommendation(recommendation)
        case .action:
            executeActionRecommendation(recommendation)
        case .completion:
            executeCompletionRecommendation(recommendation)
        case .formatting:
            executeFormattingRecommendation(recommendation)
        default:
            break
        }
    }
    
    private func executePhraseRecommendation(_ recommendation: IntelligentRecommendationManager.Recommendation) {
        // Insert phrase into current text field
        if let phraseId = recommendation.metadata["phrase_id"] as? UUID {
            Task {
                try? await phraseManager.usePhrase(phraseId)
            }
        }
    }
    
    private func executeTranslationRecommendation(_ recommendation: IntelligentRecommendationManager.Recommendation) {
        // Perform translation
        let text = recommendation.content
        Task {
            let _ = await TranslationService.shared.translate(text: text)
        }
    }
    
    private func executeKnowledgeRecommendation(_ recommendation: IntelligentRecommendationManager.Recommendation) {
        // Open knowledge document
        if let documentId = recommendation.metadata["document_id"] as? String {
            // Open document in knowledge viewer
        }
    }
    
    private func executeActionRecommendation(_ recommendation: IntelligentRecommendationManager.Recommendation) {
        // Execute recommended action
        if let actionType = recommendation.metadata["action_type"] as? String {
            // Execute action based on type
        }
    }
    
    private func executeCompletionRecommendation(_ recommendation: IntelligentRecommendationManager.Recommendation) {
        // Insert completion
        let completionText = recommendation.content
        // Insert into current text field
    }
    
    private func executeFormattingRecommendation(_ recommendation: IntelligentRecommendationManager.Recommendation) {
        // Apply formatting
        let suggestion = recommendation.content
        // Apply formatting to selected text
    }
}

// MARK: - Recommendation Card

struct RecommendationCard: View {
    let recommendation: IntelligentRecommendationManager.Recommendation
    let onTap: () -> Void
    let onAccept: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                HStack {
                    Image(systemName: recommendation.type.icon)
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text(recommendation.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                PriorityBadge(priority: recommendation.priority)
                
                ConfidenceBadge(confidence: recommendation.confidence)
            }
            
            // Title
            Text(recommendation.title)
                .font(.headline)
                .lineLimit(1)
            
            // Description
            Text(recommendation.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Content Preview
            if !recommendation.content.isEmpty {
                Text(recommendation.content)
                    .font(.body)
                    .lineLimit(2)
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
            }
            
            // Actions
            HStack {
                Button("查看详情") {
                    onTap()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("接受") {
                    onAccept()
                }
                .buttonStyle(.borderedProminent)
                
                Button("忽略") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Priority Badge

struct PriorityBadge: View {
    let priority: IntelligentRecommendationManager.RecommendationPriority
    
    var body: some View {
        Text(priority.displayName)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(priority.color).opacity(0.2))
            .foregroundColor(Color(priority.color))
            .cornerRadius(4)
    }
}

// MARK: - Confidence Badge

struct ConfidenceBadge: View {
    let confidence: Double
    
    var body: some View {
        Text(String(format: "%.0f%%", confidence * 100))
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(confidenceColor.opacity(0.2))
            .foregroundColor(confidenceColor)
            .cornerRadius(4)
    }
    
    private var confidenceColor: Color {
        switch confidence {
        case 0.8...1.0: return .green
        case 0.6...0.8: return .blue
        case 0.4...0.6: return .orange
        default: return .red
        }
    }
}

// MARK: - Recommendation Detail View

struct RecommendationDetailView: View {
    let recommendation: IntelligentRecommendationManager.Recommendation
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    headerSection
                    
                    // Content
                    contentSection
                    
                    // Context
                    contextSection
                    
                    // Metadata
                    metadataSection
                }
                .padding()
            }
            .navigationTitle("推荐详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 600)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: recommendation.type.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text(recommendation.type.displayName)
                        .font(.headline)
                    
                    Text(recommendation.title)
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack {
                    PriorityBadge(priority: recommendation.priority)
                    ConfidenceBadge(confidence: recommendation.confidence)
                }
            }
            
            Text(recommendation.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("推荐内容")
                .font(.headline)
            
            Text(recommendation.content)
                .font(.body)
                .padding()
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
        }
    }
    
    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("上下文信息")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("应用: \(recommendation.context.currentApp)")
                if let window = recommendation.context.currentWindow {
                    Text("窗口: \(window)")
                }
                if let selectedText = recommendation.context.selectedText {
                    Text("选中文本: \(selectedText.prefix(50))...")
                }
                Text("时间: \(recommendation.timestamp.formatted())")
            }
            .font(.body)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("元数据")
                .font(.headline)
            
            ForEach(Array(recommendation.metadata.keys.sorted()), id: \.self) { key in
                if let value = recommendation.metadata[key] {
                    HStack {
                        Text(key)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(value)")
                            .font(.body)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    IntelligentRecommendationView()
}