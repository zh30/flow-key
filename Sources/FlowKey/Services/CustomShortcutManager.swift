import Cocoa
import Carbon
import Foundation
import Combine

// MARK: - Custom Shortcut Manager

@MainActor
public class CustomShortcutManager: ObservableObject {
    static let shared = CustomShortcutManager()
    
    // MARK: - Initialization
    
    public func initialize() {
        // Initialize custom shortcut manager
        loadShortcuts()
        print("Custom shortcut manager initialized")
    }
    
    // MARK: - Properties
    
    @Published var shortcuts: [CustomShortcut] = []
    @Published var isRecording = false
    @Published var currentRecording: ShortcutRecording?
    @Published var conflicts: [ShortcutConflict] = []
    
    private var hotkeyRefs: [UUID: EventHotKeyRef] = [:]
    private var eventHandler: EventHandlerRef?
    private let shortcutQueue = DispatchQueue(label: "com.flowkey.shortcuts", qos: .userInitiated)
    
    // MARK: - Shortcut Types
    
    public enum ShortcutAction: String, CaseIterable {
        case toggleVoiceCommand = "toggle_voice_command"
        case showTranslationOverlay = "show_translation_overlay"
        case showKnowledgeOverlay = "show_knowledge_overlay"
        case showRecommendationOverlay = "show_recommendation_overlay"
        case quickTranslate = "quick_translate"
        case insertPhrase = "insert_phrase"
        case showSettings = "show_settings"
        case toggleInputMethod = "toggle_input_method"
        case recordSpeech = "record_speech"
        case searchKnowledge = "search_knowledge"
        case quickAccess = "quick_access"
        
        var displayName: String {
            switch self {
            case .toggleVoiceCommand: return "语音命令"
            case .showTranslationOverlay: return "翻译悬浮窗"
            case .showKnowledgeOverlay: return "知识库悬浮窗"
            case .showRecommendationOverlay: return "智能推荐悬浮窗"
            case .quickTranslate: return "快速翻译"
            case .insertPhrase: return "插入常用语"
            case .showSettings: return "显示设置"
            case .toggleInputMethod: return "切换输入法"
            case .recordSpeech: return "录制语音"
            case .searchKnowledge: return "搜索知识库"
            case .quickAccess: return "快速访问"
            }
        }
        
        var icon: String {
            switch self {
            case .toggleVoiceCommand: return "waveform"
            case .showTranslationOverlay: return "translate"
            case .showKnowledgeOverlay: return "brain"
            case .showRecommendationOverlay: return "sparkles"
            case .quickTranslate: return "textformat"
            case .insertPhrase: return "text.bubble"
            case .showSettings: return "gear"
            case .toggleInputMethod: return "keyboard"
            case .recordSpeech: return "mic"
            case .searchKnowledge: return "magnifyingglass"
            case .quickAccess: return "bolt"
            }
        }
        
        var defaultShortcut: String {
            switch self {
            case .toggleVoiceCommand: return "Command+Shift+V"
            case .showTranslationOverlay: return "Command+Shift+T"
            case .showKnowledgeOverlay: return "Command+Shift+K"
            case .showRecommendationOverlay: return "Command+Shift+R"
            case .quickTranslate: return "Command+Shift+E"
            case .insertPhrase: return "Command+Shift+P"
            case .showSettings: return "Command+Shift+S"
            case .toggleInputMethod: return "Command+Shift+I"
            case .recordSpeech: return "Command+Shift+M"
            case .searchKnowledge: return "Command+Shift+F"
            case .quickAccess: return "Command+Shift+A"
            }
        }
    }
    
    // MARK: - Data Structures
    
    public struct CustomShortcut: Identifiable, Codable, Equatable {
        public let id: UUID
        public let action: ShortcutAction
        public var keyCombination: KeyCombination
        public var isEnabled: Bool
        public var createdAt: Date
        public var updatedAt: Date
        
        public init(
            id: UUID = UUID(),
            action: ShortcutAction,
            keyCombination: KeyCombination,
            isEnabled: Bool = true
        ) {
            self.id = id
            self.action = action
            self.keyCombination = keyCombination
            self.isEnabled = isEnabled
            self.createdAt = Date()
            self.updatedAt = Date()
        }
    }
    
    public struct KeyCombination: Codable, Equatable, Hashable {
        public let key: String
        public let modifiers: [Modifier]
        
        public init(key: String, modifiers: [Modifier] = []) {
            self.key = key
            self.modifiers = modifiers
        }
        
        public var displayString: String {
            let modifierString = modifiers.map { $0.displayName }.joined(separator: "+")
            return modifierString.isEmpty ? key : "\(modifierString)+\(key)"
        }
        
        public var carbonKeyCode: UInt32 {
            return KeyCombination.keyCodeMap[key.lowercased()] ?? 0
        }
        
        public var carbonModifiers: UInt32 {
            return modifiers.reduce(0) { $0 | $1.carbonValue }
        }
    }
    
    public enum Modifier: String, CaseIterable, Codable {
        case command = "command"
        case shift = "shift"
        case option = "option"
        case control = "control"
        case function = "function"
        
        var displayName: String {
            switch self {
            case .command: return "⌘"
            case .shift: return "⇧"
            case .option: return "⌥"
            case .control: return "⌃"
            case .function: return "fn"
            }
        }
        
        var carbonValue: UInt32 {
            switch self {
            case .command: return UInt32(cmdKey)
            case .shift: return UInt32(shiftKey)
            case .option: return UInt32(optionKey)
            case .control: return UInt32(controlKey)
            case .function: return UInt32(controlKey) // fn key often maps to control
            }
        }
    }
    
    public struct ShortcutRecording {
        public let action: ShortcutAction
        public var keyCombination: KeyCombination?
        public var isConflicting: Bool = false
        public var conflictMessage: String?
    }
    
    public struct ShortcutConflict {
        public let shortcut1: CustomShortcut
        public let shortcut2: CustomShortcut
        public let message: String
    }
    
    // MARK: - Initialization
    
    private init() {
        setupDefaultShortcuts()
        setupEventHandler()
        loadShortcuts()
    }
    
    public func initialize() {
        // Initialize shortcut manager
        print("Custom shortcut manager initialized")
    }
    
    deinit {
        unregisterAllShortcuts()
    }
    
    // MARK: - Public Methods
    
    public func setupDefaultShortcuts() {
        let defaultShortcuts = ShortcutAction.allCases.map { action in
            let keyCombo = parseKeyCombination(action.defaultShortcut) ?? 
                           KeyCombination(key: "V", modifiers: [.command, .shift])
            
            return CustomShortcut(
                action: action,
                keyCombination: keyCombo,
                isEnabled: true
            )
        }
        
        shortcuts = defaultShortcuts
    }
    
    public func addShortcut(_ shortcut: CustomShortcut) throws {
        // Check for conflicts
        if let conflict = checkConflict(for: shortcut) {
            throw ShortcutError.conflict(conflict.message)
        }
        
        shortcuts.append(shortcut)
        saveShortcuts()
        
        if shortcut.isEnabled {
            try registerShortcut(shortcut)
        }
    }
    
    public func updateShortcut(_ shortcut: CustomShortcut) throws {
        guard let index = shortcuts.firstIndex(where: { $0.id == shortcut.id }) else {
            throw ShortcutError.notFound
        }
        
        // Check for conflicts (excluding the shortcut itself)
        if let conflict = checkConflict(for: shortcut, excluding: shortcut.id) {
            throw ShortcutError.conflict(conflict.message)
        }
        
        // Unregister old shortcut
        let oldShortcut = shortcuts[index]
        if oldShortcut.isEnabled {
            unregisterShortcut(oldShortcut.id)
        }
        
        // Update shortcut
        shortcuts[index] = shortcut
        saveShortcuts()
        
        // Register new shortcut if enabled
        if shortcut.isEnabled {
            try registerShortcut(shortcut)
        }
    }
    
    public func removeShortcut(_ id: UUID) {
        shortcuts.removeAll { $0.id == id }
        unregisterShortcut(id)
        saveShortcuts()
    }
    
    public func toggleShortcut(_ id: UUID) throws {
        guard let index = shortcuts.firstIndex(where: { $0.id == id }) else {
            throw ShortcutError.notFound
        }
        
        var shortcut = shortcuts[index]
        shortcut.isEnabled.toggle()
        shortcuts[index] = shortcut
        
        if shortcut.isEnabled {
            try registerShortcut(shortcut)
        } else {
            unregisterShortcut(id)
        }
        
        saveShortcuts()
    }
    
    public func startRecording(for action: ShortcutAction) {
        isRecording = true
        currentRecording = ShortcutRecording(action: action)
    }
    
    public func stopRecording() {
        isRecording = false
        currentRecording = nil
    }
    
    public func recordKeyCombination(_ keyCombination: KeyCombination) {
        guard let recording = currentRecording else { return }
        
        // Check for conflicts
        let tempShortcut = CustomShortcut(
            action: recording.action,
            keyCombination: keyCombination
        )
        
        let conflict = checkConflict(for: tempShortcut)
        currentRecording = ShortcutRecording(
            action: recording.action,
            keyCombination: keyCombination,
            isConflicting: conflict != nil,
            conflictMessage: conflict?.message
        )
    }
    
    public func saveRecording() throws {
        guard let recording = currentRecording,
              let keyCombination = recording.keyCombination else {
            throw ShortcutError.noRecording
        }
        
        if recording.isConflicting {
            throw ShortcutError.conflict(recording.conflictMessage ?? "快捷键冲突")
        }
        
        // Update existing shortcut or create new one
        if let index = shortcuts.firstIndex(where: { $0.action == recording.action }) {
            var shortcut = shortcuts[index]
            shortcut.keyCombination = keyCombination
            shortcut.updatedAt = Date()
            shortcuts[index] = shortcut
            
            if shortcut.isEnabled {
                unregisterShortcut(shortcut.id)
                try registerShortcut(shortcut)
            }
        } else {
            let newShortcut = CustomShortcut(
                action: recording.action,
                keyCombination: keyCombination
            )
            try addShortcut(newShortcut)
        }
        
        saveShortcuts()
        stopRecording()
    }
    
    public func checkConflicts() -> [ShortcutConflict] {
        var conflicts: [ShortcutConflict] = []
        
        for i in 0..<shortcuts.count {
            for j in (i + 1)..<shortcuts.count {
                let shortcut1 = shortcuts[i]
                let shortcut2 = shortcuts[j]
                
                if shortcut1.keyCombination == shortcut2.keyCombination {
                    let conflict = ShortcutConflict(
                        shortcut1: shortcut1,
                        shortcut2: shortcut2,
                        message: "快捷键 '\(shortcut1.keyCombination.displayString)' 被多个操作使用"
                    )
                    conflicts.append(conflict)
                }
            }
        }
        
        return conflicts
    }
    
    // MARK: - Private Methods
    
    private func registerShortcut(_ shortcut: CustomShortcut) throws {
        let hotkeyID = EventHotKeyID(signature: OSType("FlowK"), id: UInt32(shortcut.id.hashValue))
        
        let status = RegisterEventHotKey(
            shortcut.keyCombination.carbonKeyCode,
            shortcut.keyCombination.carbonModifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRefs[shortcut.id]
        )
        
        if status != noErr {
            throw ShortcutError.registrationFailed("Failed to register shortcut: \(status)")
        }
    }
    
    private func unregisterShortcut(_ id: UUID) {
        if let hotkeyRef = hotkeyRefs[id] {
            UnregisterEventHotKey(hotkeyRef)
            hotkeyRefs.removeValue(forKey: id)
        }
    }
    
    private func unregisterAllShortcuts() {
        for id in hotkeyRefs.keys {
            unregisterShortcut(id)
        }
    }
    
    private func setupEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            shortcutHandler,
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandler
        )
    }
    
    private func checkConflict(for shortcut: CustomShortcut, excluding: UUID? = nil) -> ShortcutConflict? {
        for existing in shortcuts {
            if existing.id == excluding { continue }
            
            if existing.keyCombination == shortcut.keyCombination {
                return ShortcutConflict(
                    shortcut1: existing,
                    shortcut2: shortcut,
                    message: "快捷键 '\(shortcut.keyCombination.displayString)' 已被 '\(existing.action.displayName)' 使用"
                )
            }
        }
        
        return nil
    }
    
    private func executeShortcut(_ shortcut: CustomShortcut) {
        switch shortcut.action {
        case .toggleVoiceCommand:
            VoiceCommandManager.shared.toggleVoiceCommand()
        case .showTranslationOverlay:
            // Show translation overlay
            break
        case .showKnowledgeOverlay:
            // Show knowledge overlay
            break
        case .showRecommendationOverlay:
            IntelligentRecommendationOverlayManager.shared.toggleRecommendationOverlay()
        case .quickTranslate:
            // Quick translate
            break
        case .insertPhrase:
            // Insert phrase
            break
        case .showSettings:
            // Show settings
            break
        case .toggleInputMethod:
            // Toggle input method
            break
        case .recordSpeech:
            // Record speech
            break
        case .searchKnowledge:
            // Search knowledge
            break
        case .quickAccess:
            // Quick access
            break
        }
    }
    
    private func parseKeyCombination(_ string: String) -> KeyCombination? {
        let components = string.split(separator: "+").map { $0.trimmingCharacters(in: .whitespaces) }
        guard !components.isEmpty else { return nil }
        
        let key = components.last?.uppercased() ?? "V"
        let modifierStrings = components.dropLast()
        
        let modifiers = modifierStrings.compactMap { modifierString -> Modifier? in
            switch modifierString.lowercased() {
            case "command", "cmd": return .command
            case "shift": return .shift
            case "option", "alt": return .option
            case "control", "ctrl": return .control
            case "function", "fn": return .function
            default: return nil
            }
        }
        
        return KeyCombination(key: key, modifiers: modifiers)
    }
    
    private func saveShortcuts() {
        // Save to UserDefaults or Core Data
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(shortcuts) {
            UserDefaults.standard.set(data, forKey: "CustomShortcuts")
        }
    }
    
    private func loadShortcuts() {
        // Load from UserDefaults or Core Data
        if let data = UserDefaults.standard.data(forKey: "CustomShortcuts") {
            let decoder = JSONDecoder()
            if let loadedShortcuts = try? decoder.decode([CustomShortcut].self, from: data) {
                shortcuts = loadedShortcuts
                
                // Register enabled shortcuts
                for shortcut in shortcuts where shortcut.isEnabled {
                    try? registerShortcut(shortcut)
                }
            }
        }
    }
    
    // MARK: - Key Code Mapping
    
    private static let keyCodeMap: [String: UInt32] = [
        "A": 0x00, "S": 0x01, "D": 0x02, "F": 0x03, "H": 0x04, "G": 0x05, "Z": 0x06, "X": 0x07,
        "C": 0x08, "V": 0x09, "B": 0x0B, "Q": 0x0C, "W": 0x0D, "E": 0x0E, "R": 0x0F, "Y": 0x10,
        "T": 0x11, "1": 0x12, "2": 0x13, "3": 0x14, "4": 0x15, "6": 0x16, "5": 0x17, "=": 0x18,
        "9": 0x19, "7": 0x1A, "-": 0x1B, "8": 0x1C, "0": 0x1D, "]": 0x1E, "O": 0x1F, "U": 0x20,
        "[": 0x21, "I": 0x22, "P": 0x23, "L": 0x25, "J": 0x26, "'": 0x27, "K": 0x28, ";": 0x29,
        "\\": 0x2A, ",": 0x2B, "/": 0x2C, "N": 0x2D, "M": 0x2E, ".": 0x2F, "`": 0x32,
        "SPACE": 0x31, "RETURN": 0x24, "TAB": 0x30, "DELETE": 0x33, "ESCAPE": 0x35,
        "F1": 0x7A, "F2": 0x78, "F3": 0x63, "F4": 0x76, "F5": 0x60, "F6": 0x61,
        "F7": 0x62, "F8": 0x64, "F9": 0x65, "F10": 0x6D, "F11": 0x67, "F12": 0x6F,
        "HOME": 0x73, "PAGEUP": 0x74, "END": 0x77, "PAGEDOWN": 0x79,
        "LEFT": 0x7B, "RIGHT": 0x7C, "DOWN": 0x7D, "UP": 0x7E
    ]
}

// MARK: - Error Types

public enum ShortcutError: Error, LocalizedError {
    case conflict(String)
    case notFound
    case registrationFailed(String)
    case noRecording
    
    public var errorDescription: String? {
        switch self {
        case .conflict(let message):
            return message
        case .notFound:
            return "快捷键未找到"
        case .registrationFailed(let message):
            return message
        case .noRecording:
            return "没有正在录制的快捷键"
        }
    }
}

// MARK: - Shortcut Handler

private let shortcutHandler: EventHandlerCallPtr = { (nextHandler, anEvent, userData) -> OSStatus in
    guard let userData = userData else { return noErr }
    
    // Get back our CustomShortcutManager instance
    let manager = Unmanaged<CustomShortcutManager>.fromOpaque(userData).takeUnretainedValue()
    
    // Get hotkey ID from event
    var hotkeyID = EventHotKeyID()
    GetEventParameter(
        anEvent,
        EventParamName(kEventParamDirectObject),
        EventHotKeyID.self,
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotkeyID
    )
    
    // Find the shortcut by ID
    let shortcutID = UUID(uuidString: String(hotkeyID.id)) ?? UUID()
    if let shortcut = manager.shortcuts.first(where: { $0.id.hashValue == hotkeyID.id }) {
        DispatchQueue.main.async {
            manager.executeShortcut(shortcut)
        }
    }
    
    return noErr
}