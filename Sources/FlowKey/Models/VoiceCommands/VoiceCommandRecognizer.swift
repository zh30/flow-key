import Foundation
import SwiftUI
import Combine
import MLX

// MARK: - Voice Command Types

public enum VoiceCommandType: String, CaseIterable {
    case translate = "translate"
    case insert = "insert"
    case search = "search"
    case settings = "settings"
    case help = "help"
    case clear = "clear"
    case copy = "copy"
    case paste = "paste"
    case undo = "undo"
    case redo = "redo"
    case newLine = "new_line"
    case tab = "tab"
    case space = "space"
    case delete = "delete"
    case enter = "enter"
    case escape = "escape"
    
    var displayName: String {
        switch self {
        case .translate: return "翻译"
        case .insert: return "插入"
        case .search: return "搜索"
        case .settings: return "设置"
        case .help: return "帮助"
        case .clear: return "清除"
        case .copy: return "复制"
        case .paste: return "粘贴"
        case .undo: return "撤销"
        case .redo: return "重做"
        case .newLine: return "换行"
        case .tab: return "制表符"
        case .space: return "空格"
        case .delete: return "删除"
        case .enter: return "回车"
        case .escape: return "退出"
        }
    }
    
    var icon: String {
        switch self {
        case .translate: return "translate"
        case .insert: return "text.insert"
        case .search: return "magnifyingglass"
        case .settings: return "gear"
        case .help: return "questionmark.circle"
        case .clear: return "trash"
        case .copy: return "doc.on.doc"
        case .paste: return "doc.on.clipboard"
        case .undo: return "arrow.uturn.backward"
        case .redo: return "arrow.uturn.forward"
        case .newLine: return "arrow.down.to.line"
        case .tab: return "arrow.right.to.line"
        case .space: return "space"
        case .delete: return "delete.backward"
        case .enter: return "return"
        case .escape: return "escape"
        }
    }
}

// MARK: - Voice Command Structure

public struct VoiceCommand: Identifiable, Codable {
    public let id: String
    public let type: VoiceCommandType
    public let text: String
    public let parameters: [String: String]
    public let confidence: Double
    public let timestamp: Date
    
    public init(
        id: String = UUID().uuidString,
        type: VoiceCommandType,
        text: String,
        parameters: [String: String] = [:],
        confidence: Double
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.parameters = parameters
        self.confidence = confidence
        self.timestamp = Date()
    }
}

// MARK: - Voice Command Settings

public struct VoiceCommandSettings: Codable {
    public var isEnabled: Bool = true
    public var activationHotkey: String = "Command+Shift+V"
    public var activationPhrase: String = "小流"
    public var confidenceThreshold: Double = 0.7
    public var autoExecute: Bool = true
    public var showConfirmation: Bool = true
    public var supportedLanguages: [String] = ["zh-CN", "en-US"]
    public var customCommands: [CustomVoiceCommand] = []
    public var voiceFeedback: Bool = true
    public var visualFeedback: Bool = true
    public var commandHistory: [VoiceCommand] = []
    public var maxHistoryItems: Int = 100
    
    public init() {}
}

public struct CustomVoiceCommand: Codable, Identifiable {
    public let id: String
    public let name: String
    public let phrase: String
    public let action: String
    public let parameters: [String: String]
    public let isEnabled: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        phrase: String,
        action: String,
        parameters: [String: String] = [:],
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.phrase = phrase
        self.action = action
        self.parameters = parameters
        self.isEnabled = isEnabled
    }
}

// MARK: - Voice Command Recognizer

@MainActor
public class VoiceCommandRecognizer: ObservableObject {
    @Published public private(set) var isListening: Bool = false
    @Published public private(set) var isProcessing: Bool = false
    @Published public private(set) var currentCommand: VoiceCommand?
    @Published public private(set) var lastError: Error?
    @Published public var settings: VoiceCommandSettings
    
    private let speechRecognizer = SpeechRecognizer.shared
    
    // MARK: - Initialization
    
    public func initialize() async {
        // Initialize voice command recognizer
        await loadSettings()
        print("Voice command recognizer initialized")
    }
    private let commandParser = VoiceCommandParser()
    private let commandExecutor = VoiceCommandExecutor()
    private var cancellables = Set<AnyCancellable>()
    
    public static let shared = VoiceCommandRecognizer()
    
    private init() {
        self.settings = VoiceCommandSettings()
        setupBindings()
    }
    
    private func setupBindings() {
        speechRecognizer.$isTranscribing
            .sink { [weak self] isTranscribing in
                self?.isProcessing = isTranscribing
            }
            .store(in: &cancellables)
        
        speechRecognizer.$transcriptionResult
            .compactMap { $0 }
            .sink { [weak self] result in
                Task { @MainActor in
                    self?.handleTranscriptionResult(result)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    public func startListening() async {
        guard !isListening else { return }
        
        do {
            isListening = true
            lastError = nil
            
            // Initialize speech recognizer if needed
            if !speechRecognizer.isModelLoaded {
                try await speechRecognizer.loadModel()
            }
            
            // Start audio session
            try await speechRecognizer.startListening()
            
        } catch {
            await MainActor.run {
                self.isListening = false
                self.lastError = error
            }
        }
    }
    
    public func stopListening() async {
        guard isListening else { return }
        
        await speechRecognizer.stopListening()
        isListening = false
        currentCommand = nil
    }
    
    public func toggleListening() async {
        if isListening {
            await stopListening()
        } else {
            await startListening()
        }
    }
    
    public func executeCommand(_ command: VoiceCommand) async {
        isProcessing = true
        
        do {
            try await commandExecutor.execute(command)
            
            // Add to history
            settings.commandHistory.append(command)
            if settings.commandHistory.count > settings.maxHistoryItems {
                settings.commandHistory.removeFirst()
            }
            
            // Clear current command
            currentCommand = nil
            
        } catch {
            lastError = error
        }
        
        isProcessing = false
    }
    
    public func addCustomCommand(_ command: CustomVoiceCommand) {
        settings.customCommands.append(command)
        commandParser.updateCustomCommands(settings.customCommands)
    }
    
    public func removeCustomCommand(_ commandId: String) {
        settings.customCommands.removeAll { $0.id == commandId }
        commandParser.updateCustomCommands(settings.customCommands)
    }
    
    // MARK: - Private Methods
    
    private func handleTranscriptionResult(_ result: String) {
        guard !result.isEmpty else { return }
        
        // Parse the transcribed text into a voice command
        let command = commandParser.parse(result, confidence: 0.8)
        
        if let command = command, command.confidence >= settings.confidenceThreshold {
            currentCommand = command
            
            if settings.autoExecute {
                Task {
                    await executeCommand(command)
                }
            }
        }
    }
    
    // MARK: - Settings Methods
    
    public func updateSettings(_ newSettings: VoiceCommandSettings) {
        settings = newSettings
        commandParser.updateCustomCommands(settings.customCommands)
        
        // Update speech recognizer settings
        speechRecognizer.confidenceThreshold = settings.confidenceThreshold
    }
    
    public func clearHistory() {
        settings.commandHistory.removeAll()
    }
    
    public func exportHistory() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(settings.commandHistory)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return "Failed to export history: \(error.localizedDescription)"
        }
    }
    
    public func initialize() async {
        // Load saved settings
        await loadSettings()
        
        // Initialize custom commands
        commandParser.updateCustomCommands(settings.customCommands)
        
        // Set up speech recognizer
        speechRecognizer.confidenceThreshold = settings.confidenceThreshold
        
        // Request audio permissions
        do {
            try await requestAudioPermissions()
        } catch {
            print("Failed to request audio permissions: \(error)")
        }
    }
    
    private func loadSettings() async {
        // Load settings from UserDefaults or Core Data
        // This is a placeholder implementation
        // In a real app, you would load from persistent storage
        
        if let savedSettings = UserDefaults.standard.data(forKey: "VoiceCommandSettings") {
            let decoder = JSONDecoder()
            do {
                let loaded = try decoder.decode(VoiceCommandSettings.self, from: savedSettings)
                await MainActor.run {
                    self.settings = loaded
                }
            } catch {
                print("Failed to load voice command settings: \(error)")
            }
        }
    }
    
    private func requestAudioPermissions() async throws {
        // Request microphone permissions
        // This would use AVFoundation or similar framework
        print("Requesting audio permissions...")
        
        // In a real implementation, this would use:
        // let session = AVAudioSession.sharedInstance()
        // try await session.requestRecordPermission()
    }
}

// MARK: - Voice Command Parser

private class VoiceCommandParser {
    private var customCommands: [CustomVoiceCommand] = []
    private let commandKeywords: [VoiceCommandType: [String]] = [
        .translate: ["翻译", "translate", "翻译成", "translate to"],
        .insert: ["插入", "insert", "输入", "type", "写", "write"],
        .search: ["搜索", "search", "查找", "find", "search for"],
        .settings: ["设置", "settings", "配置", "configure"],
        .help: ["帮助", "help", "辅助", "assist"],
        .clear: ["清除", "clear", "清空", "empty"],
        .copy: ["复制", "copy", "拷贝", "duplicate"],
        .paste: ["粘贴", "paste", "贴上", "stick"],
        .undo: ["撤销", "undo", "取消", "cancel"],
        .redo: ["重做", "redo", "恢复", "restore"],
        .newLine: ["换行", "new line", "下一行", "next line"],
        .tab: ["制表符", "tab", "tab键", "tab key"],
        .space: ["空格", "space", "空格键", "space key"],
        .delete: ["删除", "delete", "删除键", "delete key"],
        .enter: ["回车", "enter", "回车键", "enter key"],
        .escape: ["退出", "escape", "取消键", "escape key"]
    ]
    
    func parse(_ text: String, confidence: Double) -> VoiceCommand? {
        let normalizedText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check custom commands first
        for customCommand in customCommands where customCommand.isEnabled {
            if normalizedText.contains(customCommand.phrase.lowercased()) {
                return VoiceCommand(
                    type: .insert, // Custom commands are treated as insert actions
                    text: text,
                    parameters: customCommand.parameters,
                    confidence: confidence
                )
            }
        }
        
        // Check built-in commands
        for (commandType, keywords) in commandKeywords {
            for keyword in keywords {
                if normalizedText.contains(keyword) {
                    return parseCommandWithParameters(text, type: commandType, keyword: keyword, confidence: confidence)
                }
            }
        }
        
        // If no specific command found, treat as general text insertion
        return VoiceCommand(
            type: .insert,
            text: text,
            parameters: ["text": text],
            confidence: confidence * 0.7 // Lower confidence for general text
        )
    }
    
    private func parseCommandWithParameters(
        _ text: String,
        type: VoiceCommandType,
        keyword: String,
        confidence: Double
    ) -> VoiceCommand {
        var parameters: [String: String] = [:]
        
        switch type {
        case .translate:
            // Extract target language and text
            let components = text.components(separatedBy: keyword)
            if components.count > 1 {
                let remainingText = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Try to extract language
                let languages = ["中文", "英语", "日语", "韩语", "法语", "德语", "西班牙语"]
                for language in languages {
                    if remainingText.contains(language) {
                        parameters["targetLanguage"] = language
                        parameters["text"] = remainingText.replacingOccurrences(of: language, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                        break
                    }
                }
                
                if parameters["text"] == nil {
                    parameters["text"] = remainingText
                }
            }
            
        case .insert:
            parameters["text"] = text.replacingOccurrences(of: keyword, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            
        case .search:
            parameters["query"] = text.replacingOccurrences(of: keyword, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            
        default:
            break
        }
        
        return VoiceCommand(
            type: type,
            text: text,
            parameters: parameters,
            confidence: confidence
        )
    }
    
    func updateCustomCommands(_ commands: [CustomVoiceCommand]) {
        self.customCommands = commands
    }
}

// MARK: - Voice Command Executor

private class VoiceCommandExecutor {
    private let translationService = TranslationService.shared
    private let knowledgeManager = KnowledgeBaseManager.shared
    private let userHabitManager = UserHabitManager.shared
    
    func execute(_ command: VoiceCommand) async throws {
        switch command.type {
        case .translate:
            try await executeTranslateCommand(command)
            
        case .insert:
            try await executeInsertCommand(command)
            
        case .search:
            try await executeSearchCommand(command)
            
        case .settings:
            try await executeSettingsCommand(command)
            
        case .help:
            try await executeHelpCommand(command)
            
        case .clear:
            try await executeClearCommand(command)
            
        case .copy:
            try await executeCopyCommand(command)
            
        case .paste:
            try await executePasteCommand(command)
            
        case .undo:
            try await executeUndoCommand(command)
            
        case .redo:
            try await executeRedoCommand(command)
            
        case .newLine:
            try await executeNewLineCommand(command)
            
        case .tab:
            try await executeTabCommand(command)
            
        case .space:
            try await executeSpaceCommand(command)
            
        case .delete:
            try await executeDeleteCommand(command)
            
        case .enter:
            try await executeEnterCommand(command)
            
        case .escape:
            try await executeEscapeCommand(command)
        }
    }
    
    private func executeTranslateCommand(_ command: VoiceCommand) async throws {
        guard let text = command.parameters["text"], !text.isEmpty else {
            throw VoiceCommandError.missingParameter("text")
        }
        
        let targetLanguage = command.parameters["targetLanguage"] ?? "中文"
        
        // Use translation service
        let translation = await translationService.translate(text: text)
        
        // Insert the translation
        try await insertText(translation)
        
        // Log to user habits
        await userHabitManager.logVoiceCommandUsage(command.type, success: true)
    }
    
    private func executeInsertCommand(_ command: VoiceCommand) async throws {
        guard let text = command.parameters["text"], !text.isEmpty else {
            throw VoiceCommandError.missingParameter("text")
        }
        
        try await insertText(text)
        await userHabitManager.logVoiceCommandUsage(command.type, success: true)
    }
    
    private func executeSearchCommand(_ command: VoiceCommand) async throws {
        guard let query = command.parameters["query"], !query.isEmpty else {
            throw VoiceCommandError.missingParameter("query")
        }
        
        // Search in knowledge base
        let results = try await knowledgeManager.searchKnowledge(query: query)
        
        // Show search results (could be implemented as a popup)
        print("Search results for '\(query)': \(results.count) items found")
        
        await userHabitManager.logVoiceCommandUsage(command.type, success: true)
    }
    
    private func executeSettingsCommand(_ command: VoiceCommand) async throws {
        // Open settings app or show settings
        // This would need to be implemented with AppKit or SwiftUI
        print("Opening settings...")
        
        await userHabitManager.logVoiceCommandUsage(command.type, success: true)
    }
    
    private func executeHelpCommand(_ command: VoiceCommand) async throws {
        // Show help dialog
        let helpText = """
        Voice Commands:
        - 翻译 [text]: Translate text
        - 插入 [text]: Insert text
        - 搜索 [query]: Search knowledge base
        - 设置: Open settings
        - 帮助: Show this help
        - 清除: Clear current text
        - 复制: Copy to clipboard
        - 粘贴: Paste from clipboard
        - 撤销: Undo last action
        - 重做: Redo last action
        """
        
        print(helpText)
        await userHabitManager.logVoiceCommandUsage(command.type, success: true)
    }
    
    // MARK: - System Commands
    
    private func executeClearCommand(_ command: VoiceCommand) async throws {
        // Clear current text selection
        try await sendKeyEvent(key: .delete, modifiers: [.command])
        await userHabitManager.logVoiceCommandUsage(command.type, success: true)
    }
    
    private func executeCopyCommand(_ command: VoiceCommand) async throws {
        try await sendKeyEvent(key: .c, modifiers: [.command])
        await userHabitManager.logVoiceCommandUsage(command.type, success: true)
    }
    
    private func executePasteCommand(_ command: VoiceCommand) async throws {
        try await sendKeyEvent(key: .v, modifiers: [.command])
        await userHabitManager.logVoiceCommandUsage(command.type, success: true)
    }
    
    private func executeUndoCommand(_ command: VoiceCommand) async throws {
        try await sendKeyEvent(key: .z, modifiers: [.command])
        await userHabitManager.logVoiceCommandUsage(command.type, success: true)
    }
    
    private func executeRedoCommand(_ command: VoiceCommand) async throws {
        try await sendKeyEvent(key: .z, modifiers: [.command, .shift])
        await userHabitManager.logVoiceCommandUsage(command.type, success: true)
    }
    
    private func executeNewLineCommand(_ command: VoiceCommand) async throws {
        try await sendKeyEvent(key: .return)
        await userHabitManager.logVoiceCommandUsage(command.type, success: true)
    }
    
    private func executeTabCommand(_ command: VoiceCommand) async throws {
        try await sendKeyEvent(key: .tab)
        await userHabitManager.logVoiceCommandUsage(command.type, success: true)
    }
    
    private func executeSpaceCommand(_ command: VoiceCommand) async throws {
        try await sendKeyEvent(key: .space)
        await userHabitManager.logVoiceCommandUsage(command.type, success: true)
    }
    
    private func executeDeleteCommand(_ command: VoiceCommand) async throws {
        try await sendKeyEvent(key: .delete)
        await userHabitManager.logVoiceCommandUsage(command.type, success: true)
    }
    
    private func executeEnterCommand(_ command: VoiceCommand) async throws {
        try await sendKeyEvent(key: .return)
        await userHabitManager.logVoiceCommandUsage(command.type, success: true)
    }
    
    private func executeEscapeCommand(_ command: VoiceCommand) async throws {
        try await sendKeyEvent(key: .escape)
        await userHabitManager.logVoiceCommandUsage(command.type, success: true)
    }
    
    // MARK: - Helper Methods
    
    private func insertText(_ text: String) async throws {
        // This would need to be implemented with AppKit or input method
        // For now, we'll just print the text
        print("Inserting text: \(text)")
        
        // TODO: Implement actual text insertion via input method
        // This would integrate with FlowInputController
    }
    
    private func sendKeyEvent(key: String, modifiers: [String] = []) async throws {
        // This would need to be implemented with AppKit
        // For now, we'll just print the key event
        print("Sending key event: \(modifiers.joined(separator: "+"))+\(key)")
        
        // TODO: Implement actual key event sending
        // This would integrate with the input method system
    }
}

// MARK: - Voice Command Errors

enum VoiceCommandError: Error, LocalizedError {
    case missingParameter(String)
    case invalidCommand(String)
    case executionFailed(String)
    case recognitionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .missingParameter(let parameter):
            return "Missing required parameter: \(parameter)"
        case .invalidCommand(let command):
            return "Invalid command: \(command)"
        case .executionFailed(let reason):
            return "Command execution failed: \(reason)"
        case .recognitionFailed(let reason):
            return "Speech recognition failed: \(reason)"
        }
    }
}