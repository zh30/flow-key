import SwiftUI
import MLX

@main
struct FlowKeyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 400, height: 600)
        
        Settings {
            SettingsView()
        }
    }
    
    init() {
        initializeServices()
    }
    
    private func initializeServices() {
        // Initialize Core Data
        CoreDataManager.shared.initialize()
        
        // Initialize privacy and encryption
        try? PrivacyManager.shared.initialize()
        
        // Initialize translation history manager
        TranslationHistoryManager.shared.initialize()
        
        // Initialize backup manager
        BackupManager.shared.initialize()
        
        // Initialize user habit manager
        UserHabitManager.shared.initialize()
        
        // Initialize AI services
        Task {
            try? await AIService.shared.initialize()
        }
    }
}

struct ContentView: View {
    @State private var showSettings = false
    @State private var showTranslation = false
    @State private var isInputMethodEnabled = false
    @State private var selectedText = ""
    @State private var translatedText = ""
    @State private var isTranslating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("FlowKey")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Image(systemName: "keyboard")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("智能输入法")
                .font(.title2)
                .foregroundColor(.secondary)
            
            if isInputMethodEnabled {
                Text("输入法已启用")
                    .foregroundColor(.green)
            } else {
                Text("请在系统设置中启用输入法")
                    .foregroundColor(.orange)
            }
            
            Button(action: {
                checkInputMethodStatus()
            }) {
                Label("检查状态", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            
            Button(action: {
                translateSelectedText()
            }) {
                Label("翻译选中文本", systemImage: "translate")
            }
            .buttonStyle(.borderedProminent)
            .disabled(isTranslating)
            
            if isTranslating {
                ProgressView()
                    .scaleEffect(0.8)
            }
            
            if !translatedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("翻译结果:")
                        .font(.headline)
                    Text(translatedText)
                        .font(.body)
                        .lineLimit(3)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            Spacer()
            
            Button("设置") {
                showSettings = true
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(width: 300, height: 400)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
    
    private func checkInputMethodStatus() {
        // Mock implementation
        isInputMethodEnabled = true
    }
    
    private func translateSelectedText() {
        isTranslating = true
        
        Task {
            let text = "Hello World" // Mock selected text
            let translation = await TranslationService.shared.translate(text: text)
            
            await MainActor.run {
                self.translatedText = translation
                self.isTranslating = false
            }
        }
    }
}

struct SettingsView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Label("通用", systemImage: "gear")
                }
                .tag(0)
            
            TranslationSettingsView()
                .tabItem {
                    Label("翻译", systemImage: "translate")
                }
                .tag(1)
            
            TranslationQualitySettingsView()
                .tabItem {
                    Label("质量优化", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(8)
            
            ModelUpdateSettingsView()
                .tabItem {
                    Label("模型更新", systemImage: "arrow.down.circle.dotted")
                }
                .tag(9)
            
            KnowledgeSettingsView()
                .tabItem {
                    Label("知识库", systemImage: "book.fill")
                }
                .tag(2)
            
            TranslationHistoryView()
                .tabItem {
                    Label("历史", systemImage: "clock.arrow.circlepath")
                }
                .tag(3)
            
            BackupSettingsView()
                .tabItem {
                    Label("备份", systemImage: "externaldrive")
                }
                .tag(4)
            
            SmartTextDetectionView()
                .tabItem {
                    Label("智能检测", systemImage: "text.magnifyingglass")
                }
                .tag(5)
            
            UserHabitLearningView()
                .tabItem {
                    Label("习惯学习", systemImage: "brain.head.profile")
                }
                .tag(6)
            
            SyncSettingsView()
                .tabItem {
                    Label("同步", systemImage: "cloud")
                }
                .tag(7)
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    @State private var launchAtLogin = false
    @State private var showInMenuBar = true
    @State private var autoCheckUpdates = true
    @State private var selectedLanguage = "zh-CN"
    
    var body: some View {
        Form {
            Section(header: Text("启动选项")) {
                Toggle("开机自启动", isOn: $launchAtLogin)
                Toggle("显示在菜单栏", isOn: $showInMenuBar)
            }
            
            Section(header: Text("更新")) {
                Toggle("自动检查更新", isOn: $autoCheckUpdates)
            }
            
            Section(header: Text("语言")) {
                Picker("界面语言", selection: $selectedLanguage) {
                    Text("简体中文").tag("zh-CN")
                    Text("English").tag("en-US")
                    Text("日本語").tag("ja-JP")
                    Text("한국어").tag("ko-KR")
                }
                .pickerStyle(.menu)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct TranslationSettingsView: View {
    @State private var sourceLanguage = "auto"
    @State private var targetLanguage = "zh"
    @State private var translationMode: TranslationService.TranslationMode = .hybrid
    @State private var autoDetectLanguage = true
    @State private var showTranslationPopup = true
    @State private var popupDuration = 5.0
    @State private var mlxModelSize = "small"
    @State private var isModelLoaded = false
    @State private var isProcessing = false
    
    var body: some View {
        Form {
            Section(header: Text("翻译模式")) {
                Picker("翻译模式", selection: $translationMode) {
                    Text("在线翻译").tag(TranslationService.TranslationMode.online)
                    Text("本地翻译").tag(TranslationService.TranslationMode.local)
                    Text("混合模式").tag(TranslationService.TranslationMode.hybrid)
                }
                .pickerStyle(.menu)
                
                Toggle("自动检测语言", isOn: $autoDetectLanguage)
                Toggle("显示翻译弹窗", isOn: $showTranslationPopup)
            }
            
            Section(header: Text("语言选择")) {
                Picker("源语言", selection: $sourceLanguage) {
                    Text("自动检测").tag("auto")
                    Text("英语").tag("en")
                    Text("中文").tag("zh")
                    Text("日语").tag("ja")
                    Text("韩语").tag("ko")
                    Text("法语").tag("fr")
                    Text("德语").tag("de")
                    Text("西班牙语").tag("es")
                }
                .pickerStyle(.menu)
                
                Picker("目标语言", selection: $targetLanguage) {
                    Text("中文").tag("zh")
                    Text("英语").tag("en")
                    Text("日语").tag("ja")
                    Text("韩语").tag("ko")
                    Text("法语").tag("fr")
                    Text("德语").tag("de")
                    Text("西班牙语").tag("es")
                }
                .pickerStyle(.menu)
            }
            
            Section(header: Text("MLX 本地翻译")) {
                Picker("模型大小", selection: $mlxModelSize) {
                    Text("小型 (50M)").tag("small")
                    Text("中型 (150M)").tag("medium")
                    Text("大型 (300M)").tag("large")
                }
                .pickerStyle(.menu)
                
                HStack {
                    Text("模型状态")
                    Spacer()
                    Text(isModelLoaded ? "已加载" : "未加载")
                        .foregroundColor(isModelLoaded ? .green : .orange)
                }
                
                Button("加载模型") {
                    loadMLXModel()
                }
                .buttonStyle(.bordered)
                .disabled(isProcessing)
                
                Button("卸载模型") {
                    unloadMLXModel()
                }
                .buttonStyle(.bordered)
                .disabled(!isModelLoaded || isProcessing)
                
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            Section(header: Text("弹窗设置")) {
                VStack(alignment: .leading) {
                    Text("显示时长: \(Int(popupDuration)) 秒")
                    Slider(value: $popupDuration, in: 1...10, step: 1)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            checkModelStatus()
        }
    }
    
    private func loadMLXModel() {
        isProcessing = true
        
        Task {
            do {
                let modelSize = convertToMLXModelSize(mlxModelSize)
                try await TranslationService.shared.loadMLXModel()
                
                await MainActor.run {
                    isModelLoaded = true
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                }
                print("Failed to load MLX model: \(error)")
            }
        }
    }
    
    private func unloadMLXModel() {
        TranslationService.shared.unloadMLXModel()
        isModelLoaded = false
    }
    
    private func checkModelStatus() {
        let modelInfo = TranslationService.shared.getMLXModelInfo()
        isModelLoaded = modelInfo.isLoaded
    }
    
    private func convertToMLXModelSize(_ size: String) -> MLXService.TranslationModel {
        switch size {
        case "small": return .small
        case "medium": return .medium
        case "large": return .large
        default: return .small
        }
    }
}

struct KnowledgeSettingsView: View {
    @State private var knowledgeBaseEnabled = false
    @State private var autoIndexDocuments = true
    @State private var searchLimit = 10
    @State private var vectorModel = "text-embedding-ada-002"
    @State private var documentCount = 0
    @State private var isProcessing = false
    
    var body: some View {
        Form {
            Section(header: Text("知识库")) {
                Toggle("启用知识库", isOn: $knowledgeBaseEnabled)
                Toggle("自动索引文档", isOn: $autoIndexDocuments)
                
                HStack {
                    Text("文档数量")
                    Spacer()
                    Text("\(documentCount)")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("搜索设置")) {
                Stepper("搜索结果数量: \(searchLimit)", 
                       value: $searchLimit,
                       in: 1...50
                )
                
                Picker("向量模型", selection: $vectorModel) {
                    Text("text-embedding-ada-002").tag("text-embedding-ada-002")
                    Text("text-embedding-3-small").tag("text-embedding-3-small")
                    Text("text-embedding-3-large").tag("text-embedding-3-large")
                }
                .pickerStyle(.menu)
            }
            
            Section(header: Text("文档管理")) {
                Button("添加文档") {
                    // Open file picker
                }
                .buttonStyle(.bordered)
                
                Button("测试搜索") {
                    isProcessing = true
                    Task {
                        // Test search functionality
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        await MainActor.run {
                            isProcessing = false
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing)
                
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            loadDocumentCount()
        }
    }
    
    private func loadDocumentCount() {
        Task {
            let count = KnowledgeManager.shared.getDocumentCount()
            await MainActor.run {
                documentCount = count
            }
        }
    }
}

struct SyncSettingsView: View {
    @State private var iCloudSyncEnabled = false
    @State private var autoSync = true
    @State private var lastSyncDate: Date?
    @State private var syncInterval = 3600 // 1 hour
    
    var body: some View {
        Form {
            Section(header: Text("iCloud 同步")) {
                Toggle("启用 iCloud 同步", isOn: $iCloudSyncEnabled)
                Toggle("自动同步", isOn: $autoSync)
                
                if let lastSync = lastSyncDate {
                    Text("上次同步: \(lastSync.formatted())")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("同步设置")) {
                Picker("同步间隔", selection: $syncInterval) {
                    Text("5分钟").tag(300)
                    Text("15分钟").tag(900)
                    Text("30分钟").tag(1800)
                    Text("1小时").tag(3600)
                    Text("6小时").tag(21600)
                    Text("24小时").tag(86400)
                }
                .pickerStyle(.menu)
                
                Button("立即同步") {
                    performSync()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    private func performSync() {
        lastSyncDate = Date()
    }
}