import SwiftUI

struct IntelligentRecommendationOverlayView: View {
    @StateObject private var recommendationManager = IntelligentRecommendationManager.shared
    @State private var recommendations: [IntelligentRecommendationManager.Recommendation] = []
    @State private var isVisible = false
    @State private var isLoading = false
    @State private var autoHideTimer: Timer?
    @State private var selectedRecommendation: IntelligentRecommendationManager.Recommendation?
    
    let onDismiss: () -> Void
    let onRecommendationAccepted: (IntelligentRecommendationManager.Recommendation) -> Void
    
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
        .frame(width: 350, height: 450)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 10)
        .onAppear {
            loadRecommendations()
            startAutoHideTimer()
        }
        .onDisappear {
            stopAutoHideTimer()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text("智能推荐")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            Button(action: {
                loadRecommendations()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .disabled(isLoading)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12, corners: [.topLeft, .topRight])
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.0)
            
            Text("正在分析...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("暂无推荐")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Recommendations List
    
    private var recommendationsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(recommendations.prefix(5), id: \.id) { recommendation in
                    CompactRecommendationCard(
                        recommendation: recommendation,
                        onTap: {
                            selectedRecommendation = recommendation
                        },
                        onAccept: {
                            acceptRecommendation(recommendation)
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Methods
    
    private func loadRecommendations() {
        isLoading = true
        
        Task {
            let context = getCurrentContext()
            let newRecommendations = await recommendationManager.getRecommendations(for: context)
            
            await MainActor.run {
                self.recommendations = newRecommendations
                self.isLoading = false
                self.resetAutoHideTimer()
            }
        }
    }
    
    private func getCurrentContext() -> IntelligentRecommendationManager.RecommendationContext {
        return IntelligentRecommendationManager.RecommendationContext(
            currentApp: getCurrentApplication(),
            selectedText: getSelectedText()
        )
    }
    
    private func getCurrentApplication() -> String {
        // Get current application name
        return "FlowKey" // Placeholder
    }
    
    private func getSelectedText() -> String? {
        // Get currently selected text
        return nil // Placeholder
    }
    
    private func acceptRecommendation(_ recommendation: IntelligentRecommendationManager.Recommendation) {
        recommendationManager.recordRecommendationInteraction(
            recommendationId: recommendation.id,
            action: "accepted"
        )
        
        onRecommendationAccepted(recommendation)
        recommendations.removeAll { $0.id == recommendation.id }
    }
    
    private func startAutoHideTimer() {
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
            onDismiss()
        }
    }
    
    private func resetAutoHideTimer() {
        stopAutoHideTimer()
        startAutoHideTimer()
    }
    
    private func stopAutoHideTimer() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
    }
}

// MARK: - Compact Recommendation Card

struct CompactRecommendationCard: View {
    let recommendation: IntelligentRecommendationManager.Recommendation
    let onTap: () -> Void
    let onAccept: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: recommendation.type.icon)
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text(recommendation.type.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                ConfidenceBadge(confidence: recommendation.confidence)
            }
            
            Text(recommendation.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Text(recommendation.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Button("详情") {
                    onTap()
                }
                .buttonStyle(.borderless)
                .font(.caption)
                
                Spacer()
                
                Button("接受") {
                    onAccept()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}

// MARK: - Recommendation Overlay Manager

class IntelligentRecommendationOverlayManager: ObservableObject {
    @Published var isOverlayVisible = false
    @Published var currentRecommendations: [IntelligentRecommendationManager.Recommendation] = []
    
    static let shared = IntelligentRecommendationOverlayManager()
    
    private var overlayWindow: NSWindow?
    
    private init() {}
    
    func showRecommendationOverlay() {
        if overlayWindow != nil {
            hideRecommendationOverlay()
        }
        
        let contentView = IntelligentRecommendationOverlayView(
            onDismiss: { [weak self] in
                self?.hideRecommendationOverlay()
            },
            onRecommendationAccepted: { [weak self] recommendation in
                self?.handleRecommendationAccepted(recommendation)
            }
        )
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 450),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.title = "智能推荐"
        window.contentView = NSHostingView(rootView: contentView)
        window.level = .floating
        window.center()
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor.clear
        
        overlayWindow = window
        overlayWindow?.makeKeyAndOrderFront(nil)
        
        DispatchQueue.main.async {
            self.isOverlayVisible = true
        }
    }
    
    func hideRecommendationOverlay() {
        overlayWindow?.close()
        overlayWindow = nil
        
        DispatchQueue.main.async {
            self.isOverlayVisible = false
        }
    }
    
    func toggleRecommendationOverlay() {
        if isOverlayVisible {
            hideRecommendationOverlay()
        } else {
            showRecommendationOverlay()
        }
    }
    
    private func handleRecommendationAccepted(_ recommendation: IntelligentRecommendationManager.Recommendation) {
        // Handle recommendation acceptance
        switch recommendation.type {
        case .phrase:
            handlePhraseRecommendation(recommendation)
        case .translation:
            handleTranslationRecommendation(recommendation)
        case .knowledge:
            handleKnowledgeRecommendation(recommendation)
        case .action:
            handleActionRecommendation(recommendation)
        case .completion:
            handleCompletionRecommendation(recommendation)
        case .formatting:
            handleFormattingRecommendation(recommendation)
        default:
            break
        }
    }
    
    private func handlePhraseRecommendation(_ recommendation: IntelligentRecommendationManager.Recommendation) {
        // Insert phrase
        if let phraseId = recommendation.metadata["phrase_id"] as? UUID {
            Task {
                try? await PhraseManager.shared.usePhrase(phraseId)
            }
        }
    }
    
    private func handleTranslationRecommendation(_ recommendation: IntelligentRecommendationManager.Recommendation) {
        // Perform translation
        let text = recommendation.content
        Task {
            let _ = await TranslationService.shared.translate(text: text)
        }
    }
    
    private func handleKnowledgeRecommendation(_ recommendation: IntelligentRecommendationManager.Recommendation) {
        // Open knowledge document
        // Implementation would open knowledge viewer
    }
    
    private func handleActionRecommendation(_ recommendation: IntelligentRecommendationManager.Recommendation) {
        // Execute action
        // Implementation would execute the recommended action
    }
    
    private func handleCompletionRecommendation(_ recommendation: IntelligentRecommendationManager.Recommendation) {
        // Insert completion
        let completionText = recommendation.content
        // Implementation would insert text into current field
    }
    
    private func handleFormattingRecommendation(_ recommendation: IntelligentRecommendationManager.Recommendation) {
        // Apply formatting
        // Implementation would apply formatting to selected text
    }
}

// MARK: - Window Corner Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}