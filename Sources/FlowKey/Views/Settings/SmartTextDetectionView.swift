import SwiftUI

struct SmartTextDetectionView: View {
    @State private var inputText = ""
    @State private var detectionResult: SmartTextDetector.TextDetectionResult?
    @State private var isDetecting = false
    @State private var showAppContext = false
    @State private var selectedAction: SmartTextDetector.SuggestedAction?
    @State private var detectionHistory: [DetectionHistoryItem] = []
    
    private let textDetector = SmartTextDetector.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("智能文本检测")
                    .font(.headline)
                Spacer()
                
                Button(action: {
                    showAppContext.toggle()
                }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            Divider()
            
            // Input Section
            VStack(spacing: 16) {
                TextEditor(text: $inputText)
                    .frame(height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .padding(.horizontal)
                
                HStack {
                    Button("检测文本") {
                        detectText()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(inputText.isEmpty || isDetecting)
                    
                    Spacer()
                    
                    Button("清空") {
                        inputText = ""
                        detectionResult = nil
                    }
                    .buttonStyle(.bordered)
                    .disabled(inputText.isEmpty)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            
            if isDetecting {
                ProgressView("正在检测...")
                    .padding()
            }
            
            // Results Section
            if let result = detectionResult {
                DetectionResultView(result: result, onActionSelected: { action in
                    selectedAction = action
                    handleAction(action)
                })
                .transition(.slide)
            }
            
            // Detection History
            if !detectionHistory.isEmpty {
                DetectionHistoryView(history: detectionHistory)
            }
            
            Spacer()
        }
        .sheet(isPresented: $showAppContext) {
            AppContextSettingsView()
        }
        .alert("执行操作", isPresented: .constant(selectedAction != nil)) {
            Button("取消", role: .cancel) {
                selectedAction = nil
            }
            Button("确定") {
                if let action = selectedAction {
                    executeAction(action)
                }
                selectedAction = nil
            }
        } message: {
            if let action = selectedAction {
                Text("确定要执行\"\(action.title)\"操作吗？\n\(action.description)")
            }
        }
    }
    
    private func detectText() {
        guard !inputText.isEmpty else { return }
        
        isDetecting = true
        
        Task {
            let result = await textDetector.detectTextType(in: inputText)
            
            await MainActor.run {
                self.detectionResult = result
                self.isDetecting = false
                
                // Add to history
                let historyItem = DetectionHistoryItem(
                    text: inputText,
                    result: result,
                    timestamp: Date()
                )
                self.detectionHistory.insert(historyItem, at: 0)
                
                // Keep only last 10 items
                if self.detectionHistory.count > 10 {
                    self.detectionHistory.removeLast()
                }
                
                // Record user habit for learning
                let habitService = UserHabitIntegrationService.shared
                habitService.recordTextDetectionInteraction(
                    detectedText: inputText,
                    result: result,
                    selectedAction: nil, // No action selected yet
                    context: "Smart Text Detection View"
                )
            }
        }
    }
    
    private func handleAction(_ action: SmartTextDetector.SuggestedAction) {
        // Handle action selection
        print("Selected action: \(action.title)")
    }
    
    private func executeAction(_ action: SmartTextDetector.SuggestedAction) {
        guard let result = detectionResult else { return }
        
        // Record user action selection for habit learning
        let habitService = UserHabitIntegrationService.shared
        
        switch action.type {
        case .translate:
            // Trigger translation
            NotificationCenter.default.post(
                name: .translateText,
                object: inputText
            )
            
        case .search:
            // Open web search
            if let url = URL(string: "https://www.google.com/search?q=\(inputText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                NSWorkspace.shared.open(url)
            }
            
        case .openUrl:
            // Find and open URL
            if let urlEntity = result.entities.first(where: { $0.type == .url }),
               let url = URL(string: urlEntity.value) {
                NSWorkspace.shared.open(url)
            }
            
        case .composeEmail:
            // Find email and compose
            if let emailEntity = result.entities.first(where: { $0.type == .email }) {
                let email = emailEntity.value
                if let url = URL(string: "mailto:\(email)") {
                    NSWorkspace.shared.open(url)
                }
            }
            
        case .makeCall:
            // Find phone number and make call
            if let phoneEntity = result.entities.first(where: { $0.type == .phoneNumber }) {
                let phoneNumber = phoneEntity.value
                if let url = URL(string: "tel:\(phoneNumber)") {
                    NSWorkspace.shared.open(url)
                }
            }
            
        case .addToCalendar:
            // Find date and add to calendar
            if let dateEntity = result.entities.first(where: { $0.type == .date }) {
                // This would require Calendar access
                print("Would add to calendar: \(dateEntity.value)")
            }
            
        case .copyToClipboard:
            // Copy text to clipboard
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(inputText, forType: .string)
            
        case .lookupDefinition:
            // Look up definition
            if let url = URL(string: "https://www.google.com/search?q=define:\(inputText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                NSWorkspace.shared.open(url)
            }
            
        case .formatText:
            // Format text (for code)
            // This would integrate with code formatting service
            print("Would format text: \(inputText)")
            
        case .extractData:
            // Extract structured data
            print("Would extract data from: \(inputText)")
        }
        
        // Record the action selection for habit learning
        habitService.recordTextDetectionInteraction(
            detectedText: inputText,
            result: result,
            selectedAction: action,
            context: "Smart Text Detection View - Action Executed"
        )
    }
}

// MARK: - Detection Result View

struct DetectionResultView: View {
    let result: SmartTextDetector.TextDetectionResult
    let onActionSelected: (SmartTextDetector.SuggestedAction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Text Type Badge
            HStack {
                Text("检测类型")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(textTypeDisplayName(result.type))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(textTypeColor(result.type))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                
                Spacer()
                
                Text("置信度: \(Int(result.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Language Detection
            if let language = result.language {
                HStack {
                    Text("检测语言")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(language.uppercased())
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            // Detected Entities
            if !result.entities.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("检测到的实体")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(result.entities, id: \.value) { entity in
                                EntityChip(entity: entity)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            // Suggested Actions
            if !result.suggestedActions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("建议操作")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(result.suggestedActions.prefix(6), id: \.title) { action in
                            ActionButton(action: action, onTap: {
                                onActionSelected(action)
                            })
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private func textTypeDisplayName(_ type: SmartTextDetector.TextType) -> String {
        switch type {
        case .plain: return "纯文本"
        case .url: return "网址"
        case .email: return "邮箱"
        case .phoneNumber: return "电话"
        case .address: return "地址"
        case .date: return "日期"
        case .time: return "时间"
        case .currency: return "货币"
        case .code: return "代码"
        case .markdown: return "Markdown"
        case .mixed: return "混合"
        }
    }
    
    private func textTypeColor(_ type: SmartTextDetector.TextType) -> Color {
        switch type {
        case .url: return .blue
        case .email: return .green
        case .phoneNumber: return .orange
        case .address: return .purple
        case .date, .time: return .red
        case .currency: return .yellow
        case .code: return .indigo
        case .markdown: return .pink
        default: return .gray
        }
    }
}

// MARK: - Entity Chip

struct EntityChip: View {
    let entity: SmartTextDetector.TextEntity
    
    var body: some View {
        HStack(spacing: 4) {
            Text(entityTypeName(entity.type))
                .font(.caption2)
                .fontWeight(.medium)
            
            Text(entity.value)
                .font(.caption2)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(entityTypeColor(entity.type))
        .foregroundColor(.white)
        .cornerRadius(12)
    }
    
    private func entityTypeName(_ type: SmartTextDetector.EntityType) -> String {
        switch type {
        case .url: return "URL"
        case .email: return "邮箱"
        case .phoneNumber: return "电话"
        case .streetAddress: return "地址"
        case .city: return "城市"
        case .state: return "州/省"
        case .postalCode: return "邮编"
        case .country: return "国家"
        case .date: return "日期"
        case .time: return "时间"
        case .currency: return "货币"
        case .percentage: return "百分比"
        case .measurement: return "计量"
        case .personName: return "姓名"
        case .organizationName: return "组织"
        case .keyword: return "关键词"
        case .codeSnippet: return "代码"
        }
    }
    
    private func entityTypeColor(_ type: SmartTextDetector.EntityType) -> Color {
        switch type {
        case .url: return .blue
        case .email: return .green
        case .phoneNumber: return .orange
        case .streetAddress, .city, .state, .postalCode, .country: return .purple
        case .date, .time: return .red
        case .currency: return .yellow
        case .percentage: return .cyan
        case .measurement: return .brown
        case .personName: return .pink
        case .organizationName: return .indigo
        case .keyword: return .mint
        case .codeSnippet: return .gray
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let action: SmartTextDetector.SuggestedAction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: actionIcon(action.type))
                    .font(.system(size: 16))
                
                Text(action.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .help(action.description)
    }
    
    private func actionIcon(_ type: SmartTextDetector.ActionType) -> String {
        switch type {
        case .translate: return "translate"
        case .search: return "magnifyingglass"
        case .openUrl: return "safari"
        case .composeEmail: return "envelope"
        case .makeCall: return "phone"
        case .addToCalendar: return "calendar"
        case .copyToClipboard: return "doc.on.doc"
        case .lookupDefinition: return "book"
        case .formatText: return "textformat"
        case .extractData: return "doc.text"
        }
    }
}

// MARK: - Detection History View

struct DetectionHistoryView: View {
    let history: [DetectionHistoryItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("检测历史")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(history, id: \.timestamp) { item in
                        HistoryItemView(item: item)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

struct HistoryItemView: View {
    let item: DetectionHistoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.text)
                    .font(.body)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(formatDate(item.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(textTypeDisplayName(item.result.type))
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(textTypeColor(item.result.type))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                
                Text("置信度: \(Int(item.result.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("实体: \(item.result.entities.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func textTypeDisplayName(_ type: SmartTextDetector.TextType) -> String {
        switch type {
        case .plain: return "纯文本"
        case .url: return "网址"
        case .email: return "邮箱"
        case .phoneNumber: return "电话"
        case .address: return "地址"
        case .date: return "日期"
        case .time: return "时间"
        case .currency: return "货币"
        case .code: return "代码"
        case .markdown: return "Markdown"
        case .mixed: return "混合"
        }
    }
    
    private func textTypeColor(_ type: SmartTextDetector.TextType) -> Color {
        switch type {
        case .url: return .blue
        case .email: return .green
        case .phoneNumber: return .orange
        case .address: return .purple
        case .date, .time: return .red
        case .currency: return .yellow
        case .code: return .indigo
        case .markdown: return .pink
        default: return .gray
        }
    }
}

// MARK: - App Context Settings View

struct AppContextSettingsView: View {
    @State private var enableAppContext = true
    @State private var autoDetect = true
    @State private var cacheResults = true
    @State private var showConfidence = true
    
    var body: some View {
        VStack(spacing: 20) {
            Text("检测设置")
                .font(.headline)
            
            Form {
                Section(header: Text("智能检测")) {
                    Toggle("启用应用上下文检测", isOn: $enableAppContext)
                    Toggle("自动检测文本类型", isOn: $autoDetect)
                    Toggle("缓存检测结果", isOn: $cacheResults)
                    Toggle("显示置信度", isOn: $showConfidence)
                }
                
                Section(header: Text("检测选项")) {
                    VStack(alignment: .leading) {
                        Text("支持的实体类型")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            EntityToggle(title: "网址", icon: "safari", enabled: true)
                            EntityToggle(title: "邮箱", icon: "envelope", enabled: true)
                            EntityToggle(title: "电话", icon: "phone", enabled: true)
                            EntityToggle(title: "地址", icon: "location", enabled: true)
                            EntityToggle(title: "日期", icon: "calendar", enabled: true)
                            EntityToggle(title: "货币", icon: "dollarsign", enabled: true)
                            EntityToggle(title: "代码", icon: "chevron.left.forwardslash.chevron.right", enabled: true)
                            EntityToggle(title: "关键词", icon: "tag", enabled: true)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button("重置设置") {
                    // Reset to defaults
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("完成") {
                    // Save settings
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 500)
    }
}

struct EntityToggle: View {
    let title: String
    let icon: String
    @State var enabled: Bool
    
    var body: some View {
        Toggle(isOn: $enabled) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
        }
        .toggleStyle(.checkbox)
    }
}

// MARK: - Supporting Structures

struct DetectionHistoryItem {
    let text: String
    let result: SmartTextDetector.TextDetectionResult
    let timestamp: Date
}

// MARK: - Notification Extension

extension Notification.Name {
    static let translateText = Notification.Name("translateText")
    static let searchText = Notification.Name("searchText")
    static let openUrl = Notification.Name("openUrl")
}