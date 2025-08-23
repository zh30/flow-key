import SwiftUI

struct VoiceCommandSettingsView: View {
    @StateObject private var voiceCommandRecognizer = VoiceCommandRecognizer.shared
    @State private var showCustomCommandSheet = false
    @State private var showHistorySheet = false
    @State private var isTesting = false
    @State private var testResult = ""
    @State private var selectedCustomCommand: CustomVoiceCommand?
    @State private var showEditCustomCommandSheet = false
    @State private var hotkeyManager = GlobalHotkeyManager.shared
    
    var body: some View {
        Form {
            Section(header: Text("语音命令设置")) {
                Toggle("启用语音命令", isOn: $voiceCommandRecognizer.settings.isEnabled)
                
                if voiceCommandRecognizer.settings.isEnabled {
                    HStack {
                        Text("激活热键")
                        Spacer()
                        TextField("热键", text: $voiceCommandRecognizer.settings.activationHotkey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                            .onSubmit {
                                hotkeyManager.setHotkey(voiceCommandRecognizer.settings.activationHotkey)
                            }
                    }
                    
                    TextField("激活短语", text: $voiceCommandRecognizer.settings.activationPhrase)
                    
                    VStack(alignment: .leading) {
                        Text("置信度阈值: \(Int(voiceCommandRecognizer.settings.confidenceThreshold * 100))%")
                        Slider(value: $voiceCommandRecognizer.settings.confidenceThreshold, in: 0.1...1.0, step: 0.1)
                    }
                    
                    Toggle("自动执行", isOn: $voiceCommandRecognizer.settings.autoExecute)
                    Toggle("显示确认", isOn: $voiceCommandRecognizer.settings.showConfirmation)
                    Toggle("语音反馈", isOn: $voiceCommandRecognizer.settings.voiceFeedback)
                    Toggle("视觉反馈", isOn: $voiceCommandRecognizer.settings.visualFeedback)
                }
            }
            
            if voiceCommandRecognizer.settings.isEnabled {
                Section(header: Text("语言支持")) {
                    ForEach(availableLanguages, id: \.code) { language in
                        Toggle(language.name, isOn: binding(for: language.code))
                    }
                }
                
                Section(header: Text("当前状态")) {
                    HStack {
                        Text("监听状态")
                        Spacer()
                        Text(voiceCommandRecognizer.isListening ? "正在监听" : "未监听")
                            .foregroundColor(voiceCommandRecognizer.isListening ? .green : .red)
                    }
                    
                    HStack {
                        Text("处理状态")
                        Spacer()
                        Text(voiceCommandRecognizer.isProcessing ? "处理中" : "空闲")
                            .foregroundColor(voiceCommandRecognizer.isProcessing ? .orange : .green)
                    }
                    
                    if let currentCommand = voiceCommandRecognizer.currentCommand {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("当前命令")
                                .font(.headline)
                            
                            HStack {
                                Text(currentCommand.type.displayName)
                                    .font(.body)
                                Spacer()
                                Text("\(Int(currentCommand.confidence * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if !currentCommand.text.isEmpty {
                                Text(currentCommand.text)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    HStack {
                        Button(voiceCommandRecognizer.isListening ? "停止监听" : "开始监听") {
                            Task {
                                await voiceCommandRecognizer.toggleListening()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Spacer()
                        
                        Button("测试命令") {
                            testVoiceCommand()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if !testResult.isEmpty {
                        Text(testResult)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("自定义命令")) {
                    if voiceCommandRecognizer.settings.customCommands.isEmpty {
                        Text("暂无自定义命令")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(voiceCommandRecognizer.settings.customCommands) { command in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(command.name)
                                        .font(.headline)
                                    Text(command.phrase)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                
                                Toggle("", isOn: binding(for: command))
                                    .labelsHidden()
                                
                                Button("编辑") {
                                    selectedCustomCommand = command
                                    showEditCustomCommandSheet = true
                                }
                                .buttonStyle(.bordered)
                                
                                Button("删除") {
                                    voiceCommandRecognizer.removeCustomCommand(command.id)
                                }
                                .buttonStyle(.bordered)
                                .foregroundColor(.red)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Button("添加自定义命令") {
                        showCustomCommandSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Section(header: Text("命令历史")) {
                    HStack {
                        Text("历史记录数量")
                        Spacer()
                        Text("\(voiceCommandRecognizer.settings.commandHistory.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    Stepper("最大历史记录: \(voiceCommandRecognizer.settings.maxHistoryItems)",
                           value: $voiceCommandRecognizer.settings.maxHistoryItems,
                           in: 10...1000
                    )
                    
                    HStack {
                        Button("查看历史") {
                            showHistorySheet = true
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button("清除历史") {
                            voiceCommandRecognizer.clearHistory()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("支持命令")) {
                    ForEach(VoiceCommandType.allCases, id: \.self) { commandType in
                        HStack {
                            HStack {
                                Image(systemName: commandType.icon)
                                    .foregroundColor(.blue)
                                Text(commandType.displayName)
                            }
                            Spacer()
                            Text(getCommandExample(for: commandType))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .sheet(isPresented: $showCustomCommandSheet) {
            AddCustomVoiceCommandView { command in
                voiceCommandRecognizer.addCustomCommand(command)
            }
        }
        .sheet(isPresented: $showEditCustomCommandSheet) {
            if let command = selectedCustomCommand {
                EditCustomVoiceCommandView(command: command) { updatedCommand in
                    voiceCommandRecognizer.removeCustomCommand(command.id)
                    voiceCommandRecognizer.addCustomCommand(updatedCommand)
                }
            }
        }
        .sheet(isPresented: $showHistorySheet) {
            VoiceCommandHistoryView(commands: voiceCommandRecognizer.settings.commandHistory)
        }
        .onDisappear {
            // Save settings when view disappears
            voiceCommandRecognizer.updateSettings(voiceCommandRecognizer.settings)
        }
    }
    
    // MARK: - Helper Properties
    
    private var availableLanguages: [(code: String, name: String)] {
        [
            ("zh-CN", "简体中文"),
            ("en-US", "English"),
            ("ja-JP", "日本語"),
            ("ko-KR", "한국어"),
            ("fr-FR", "Français"),
            ("de-DE", "Deutsch"),
            ("es-ES", "Español")
        ]
    }
    
    // MARK: - Helper Methods
    
    private func binding(for languageCode: String) -> Binding<Bool> {
        return Binding(
            get: { voiceCommandRecognizer.settings.supportedLanguages.contains(languageCode) },
            set: { newValue in
                if newValue {
                    if !voiceCommandRecognizer.settings.supportedLanguages.contains(languageCode) {
                        voiceCommandRecognizer.settings.supportedLanguages.append(languageCode)
                    }
                } else {
                    voiceCommandRecognizer.settings.supportedLanguages.removeAll { $0 == languageCode }
                }
            }
        )
    }
    
    private func binding(for command: CustomVoiceCommand) -> Binding<Bool> {
        return Binding(
            get: { command.isEnabled },
            set: { newValue in
                if let index = voiceCommandRecognizer.settings.customCommands.firstIndex(where: { $0.id == command.id }) {
                    var updatedCommand = command
                    updatedCommand = CustomVoiceCommand(
                        id: command.id,
                        name: command.name,
                        phrase: command.phrase,
                        action: command.action,
                        parameters: command.parameters,
                        isEnabled: newValue
                    )
                    voiceCommandRecognizer.settings.customCommands[index] = updatedCommand
                }
            }
        )
    }
    
    private func getCommandExample(for commandType: VoiceCommandType) -> String {
        switch commandType {
        case .translate: return "翻译 Hello World"
        case .insert: return "插入 你好世界"
        case .search: return "搜索 Swift 教程"
        case .settings: return "打开设置"
        case .help: return "显示帮助"
        case .clear: return "清除文本"
        case .copy: return "复制选中"
        case .paste: return "粘贴内容"
        case .undo: return "撤销操作"
        case .redo: return "重做操作"
        case .newLine: return "换行"
        case .tab: return "制表符"
        case .space: return "空格"
        case .delete: return "删除"
        case .enter: return "回车"
        case .escape: return "退出"
        }
    }
    
    private func testVoiceCommand() {
        isTesting = true
        testResult = "测试中..."
        
        Task {
            await voiceCommandRecognizer.startListening()
            
            // Simulate a test command after 2 seconds
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            await MainActor.run {
                testResult = "请说出命令，例如：'翻译 Hello World'"
                isTesting = false
            }
        }
    }
}

// MARK: - Add Custom Voice Command View

struct AddCustomVoiceCommandView: View {
    let onComplete: (CustomVoiceCommand) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var phrase = ""
    @State private var action = "insert"
    @State private var parameters: String = ""
    @State private var isEnabled = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("命令名称", text: $name)
                    TextField("激活短语", text: $phrase)
                    
                    Picker("动作类型", selection: $action) {
                        Text("插入文本").tag("insert")
                        Text("执行命令").tag("execute")
                        Text("打开应用").tag("open")
                        Text("搜索").tag("search")
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("参数")) {
                    TextField("参数 (JSON格式)", text: $parameters, axis: .vertical)
                        .lineLimit(3)
                }
                
                Section(header: Text("设置")) {
                    Toggle("启用", isOn: $isEnabled)
                }
                
                Section {
                    Button("创建") {
                        createCommand()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.isEmpty || phrase.isEmpty)
                }
            }
            .navigationTitle("添加自定义命令")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
    
    private func createCommand() {
        let command = CustomVoiceCommand(
            name: name,
            phrase: phrase,
            action: action,
            parameters: parseParameters(parameters),
            isEnabled: isEnabled
        )
        
        onComplete(command)
        dismiss()
    }
    
    private func parseParameters(_ jsonString: String) -> [String: String] {
        guard let data = jsonString.data(using: .utf8) else { return [:] }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
            return json ?? [:]
        } catch {
            return [:]
        }
    }
}

// MARK: - Edit Custom Voice Command View

struct EditCustomVoiceCommandView: View {
    let command: CustomVoiceCommand
    let onComplete: (CustomVoiceCommand) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var phrase: String
    @State private var action: String
    @State private var parameters: String
    @State private var isEnabled: Bool
    
    init(command: CustomVoiceCommand, onComplete: @escaping (CustomVoiceCommand) -> Void) {
        self.command = command
        self.onComplete = onComplete
        
        _name = State(initialValue: command.name)
        _phrase = State(initialValue: command.phrase)
        _action = State(initialValue: command.action)
        _parameters = State(initialValue: serializeParameters(command.parameters))
        _isEnabled = State(initialValue: command.isEnabled)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("命令名称", text: $name)
                    TextField("激活短语", text: $phrase)
                    
                    Picker("动作类型", selection: $action) {
                        Text("插入文本").tag("insert")
                        Text("执行命令").tag("execute")
                        Text("打开应用").tag("open")
                        Text("搜索").tag("search")
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("参数")) {
                    TextField("参数 (JSON格式)", text: $parameters, axis: .vertical)
                        .lineLimit(3)
                }
                
                Section(header: Text("设置")) {
                    Toggle("启用", isOn: $isEnabled)
                }
                
                Section {
                    Button("更新") {
                        updateCommand()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.isEmpty || phrase.isEmpty)
                }
            }
            .navigationTitle("编辑自定义命令")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
    
    private func updateCommand() {
        let command = CustomVoiceCommand(
            id: command.id,
            name: name,
            phrase: phrase,
            action: action,
            parameters: parseParameters(parameters),
            isEnabled: isEnabled
        )
        
        onComplete(command)
        dismiss()
    }
    
    private func parseParameters(_ jsonString: String) -> [String: String] {
        guard let data = jsonString.data(using: .utf8) else { return [:] }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
            return json ?? [:]
        } catch {
            return [:]
        }
    }
    
    private func serializeParameters(_ parameters: [String: String]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }
}

// MARK: - Voice Command History View

struct VoiceCommandHistoryView: View {
    let commands: [VoiceCommand]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(commands.reversed()) { command in
                        VoiceCommandHistoryItem(command: command)
                    }
                }
                .padding()
            }
            .navigationTitle("命令历史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
    }
}

struct VoiceCommandHistoryItem: View {
    let command: VoiceCommand
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack {
                    Image(systemName: command.type.icon)
                        .foregroundColor(.blue)
                    Text(command.type.displayName)
                        .font(.headline)
                }
                
                Spacer()
                
                Text("\(Int(command.confidence * 100))%")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(confidenceColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            Text(command.text)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            if !command.parameters.isEmpty {
                Text("参数: \(command.parameters.map { "\($0.key): \($0.value)" }.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(command.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(command.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var confidenceColor: Color {
        switch command.confidence {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .yellow
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

#Preview {
    VoiceCommandSettingsView()
}