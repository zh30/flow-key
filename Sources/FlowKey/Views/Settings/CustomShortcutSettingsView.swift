import SwiftUI
import Combine

struct CustomShortcutSettingsView: View {
    @StateObject private var shortcutManager = CustomShortcutManager.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var selectedShortcut: CustomShortcutManager.CustomShortcut?
    @State private var showingEditSheet = false
    @State private var conflicts: [CustomShortcutManager.ShortcutConflict] = []
    @State private var isCheckingConflicts = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Content
            if isCheckingConflicts {
                conflictCheckingView
            } else if !conflicts.isEmpty {
                conflictWarningView
            } else {
                shortcutsList
            }
        }
        .onAppear {
            checkForConflicts()
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("确定"))
            )
        }
        .sheet(isPresented: $showingEditSheet) {
            if let shortcut = selectedShortcut {
                ShortcutEditView(
                    shortcut: shortcut,
                    onSave: { updatedShortcut in
                        updateShortcut(updatedShortcut)
                    },
                    onCancel: {
                        showingEditSheet = false
                    }
                )
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("快捷键设置")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("自定义和管理快捷键")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Button("检查冲突") {
                    checkForConflicts()
                }
                .buttonStyle(.bordered)
                .disabled(isCheckingConflicts)
                
                Button("恢复默认") {
                    restoreDefaults()
                }
                .buttonStyle(.bordered)
                
                Button("添加快捷键") {
                    addNewShortcut()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Conflict Checking View
    
    private var conflictCheckingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("正在检查快捷键冲突...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Conflict Warning View
    
    private var conflictWarningView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("发现快捷键冲突")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("以下快捷键存在冲突，请修改后重新检查")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(conflicts, id: \.message) { conflict in
                        ConflictCard(conflict: conflict) {
                            selectedShortcut = conflict.shortcut1
                            showingEditSheet = true
                        }
                    }
                }
                .padding()
            }
            
            HStack {
                Button("忽略") {
                    conflicts = []
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("重新检查") {
                    checkForConflicts()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Shortcuts List
    
    private var shortcutsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(shortcutManager.shortcuts) { shortcut in
                    ShortcutCard(
                        shortcut: shortcut,
                        onToggle: {
                            toggleShortcut(shortcut)
                        },
                        onEdit: {
                            selectedShortcut = shortcut
                            showingEditSheet = true
                        },
                        onDelete: {
                            deleteShortcut(shortcut)
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Methods
    
    private func checkForConflicts() {
        isCheckingConflicts = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            conflicts = shortcutManager.checkConflicts()
            isCheckingConflicts = false
        }
    }
    
    private func addNewShortcut() {
        // Create a new shortcut for an unused action
        let usedActions = Set(shortcutManager.shortcuts.map { $0.action })
        let availableActions = CustomShortcutManager.ShortcutAction.allCases.filter { !usedActions.contains($0) }
        
        guard let firstAvailable = availableActions.first else {
            showAlert(title: "无法添加", message: "所有操作都已配置快捷键")
            return
        }
        
        let newShortcut = CustomShortcutManager.CustomShortcut(
            action: firstAvailable,
            keyCombination: CustomShortcutManager.KeyCombination(key: "A", modifiers: [.command])
        )
        
        selectedShortcut = newShortcut
        showingEditSheet = true
    }
    
    private func updateShortcut(_ shortcut: CustomShortcutManager.CustomShortcut) {
        do {
            try shortcutManager.updateShortcut(shortcut)
            showingEditSheet = false
            checkForConflicts()
        } catch {
            showAlert(title: "更新失败", message: error.localizedDescription)
        }
    }
    
    private func toggleShortcut(_ shortcut: CustomShortcutManager.CustomShortcut) {
        do {
            try shortcutManager.toggleShortcut(shortcut.id)
            checkForConflicts()
        } catch {
            showAlert(title: "切换失败", message: error.localizedDescription)
        }
    }
    
    private func deleteShortcut(_ shortcut: CustomShortcutManager.CustomShortcut) {
        let alert = NSAlert()
        alert.messageText = "删除快捷键"
        alert.informativeText = "确定要删除 '\(shortcut.action.displayName)' 的快捷键吗？"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            shortcutManager.removeShortcut(shortcut.id)
            checkForConflicts()
        }
    }
    
    private func restoreDefaults() {
        let alert = NSAlert()
        alert.messageText = "恢复默认设置"
        alert.informativeText = "确定要恢复所有快捷键为默认设置吗？这将覆盖您的自定义设置。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            shortcutManager.setupDefaultShortcuts()
            checkForConflicts()
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - Shortcut Card

struct ShortcutCard: View {
    let shortcut: CustomShortcutManager.CustomShortcut
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack {
                    Image(systemName: shortcut.action.icon)
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text(shortcut.action.displayName)
                        .font(.headline)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { shortcut.isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
            }
            
            HStack {
                Text(shortcut.keyCombination.displayString)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(4)
                
                Spacer()
                
                HStack {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Conflict Card

struct ConflictCard: View {
    let conflict: CustomShortcutManager.ShortcutConflict
    let onResolve: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                    .font(.caption)
                
                Text("快捷键冲突")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            
            Text(conflict.message)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(conflict.shortcut1.action.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(conflict.shortcut1.keyCombination.displayString)
                        .font(.system(.caption, design: .monospaced))
                }
                
                Spacer()
                
                Text("vs")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(conflict.shortcut2.action.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(conflict.shortcut2.keyCombination.displayString)
                        .font(.system(.caption, design: .monospaced))
                }
            }
            
            Button("解决冲突") {
                onResolve()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Shortcut Edit View

struct ShortcutEditView: View {
    let shortcut: CustomShortcutManager.CustomShortcut
    let onSave: (CustomShortcutManager.CustomShortcut) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var shortcutManager = CustomShortcutManager.shared
    @State private var keyCombination: CustomShortcutManager.KeyCombination
    @State private var isRecording = false
    @State private var recordingText = "按下快捷键组合"
    @State private var conflictMessage: String?
    @State private var isTesting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Action Info
                actionInfoView
                
                // Key Recording
                keyRecordingView
                
                // Test Button
                if !conflictMessage.isNilOrEmpty {
                    testButton
                }
                
                // Save/Cancel Buttons
                actionButtons
            }
            .padding()
            .navigationTitle("编辑快捷键")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onCancel()
                    }
                }
            }
        }
        .frame(width: 400, height: 350)
        .onAppear {
            keyCombination = shortcut.keyCombination
        }
    }
    
    private var actionInfoView: some View {
        HStack {
            Image(systemName: shortcut.action.icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(shortcut.action.displayName)
                    .font(.headline)
                
                Text("为这个操作设置快捷键")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var keyRecordingView: some View {
        VStack(spacing: 12) {
            Text("快捷键组合")
                .font(.headline)
            
            Button(action: {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                HStack {
                    if isRecording {
                        Image(systemName: "record.circle")
                            .foregroundColor(.red)
                    }
                    
                    Text(recordingText)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(isRecording ? .red : .primary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isRecording ? Color.red : Color.gray, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
            
            if let conflictMessage = conflictMessage {
                Text(conflictMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var testButton: some View {
        Button("测试快捷键") {
            testShortcut()
        }
        .buttonStyle(.bordered)
        .disabled(isTesting)
    }
    
    private var actionButtons: some View {
        HStack {
            Button("取消") {
                onCancel()
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("保存") {
                saveShortcut()
            }
            .buttonStyle(.borderedProminent)
            .disabled(conflictMessage != nil)
        }
    }
    
    private func startRecording() {
        isRecording = true
        recordingText = "按下快捷键组合..."
        conflictMessage = nil
        shortcutManager.startRecording(for: shortcut.action)
        
        // Start monitoring key events
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if isRecording {
                handleKeyEvent(event)
                return nil // Consume the event
            }
            return event
        }
    }
    
    private func stopRecording() {
        isRecording = false
        shortcutManager.stopRecording()
        
        if let recording = shortcutManager.currentRecording,
           let keyCombo = recording.keyCombination {
            keyCombination = keyCombo
            recordingText = keyCombo.displayString
            
            if recording.isConflicting {
                conflictMessage = recording.conflictMessage
            }
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        guard !event.modifierFlags.isEmpty else { return }
        
        var modifiers: [CustomShortcutManager.Modifier] = []
        
        if event.modifierFlags.contains(.command) {
            modifiers.append(.command)
        }
        if event.modifierFlags.contains(.shift) {
            modifiers.append(.shift)
        }
        if event.modifierFlags.contains(.option) {
            modifiers.append(.option)
        }
        if event.modifierFlags.contains(.control) {
            modifiers.append(.control)
        }
        
        let key = event.charactersIgnoringModifiers?.uppercased() ?? "?"
        
        let keyCombo = CustomShortcutManager.KeyCombination(key: key, modifiers: modifiers)
        shortcutManager.recordKeyCombination(keyCombo)
        
        recordingText = keyCombo.displayString
    }
    
    private func testShortcut() {
        isTesting = true
        
        // Simulate shortcut test
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isTesting = false
        }
    }
    
    private func saveShortcut() {
        var updatedShortcut = shortcut
        updatedShortcut.keyCombination = keyCombination
        updatedShortcut.updatedAt = Date()
        
        onSave(updatedShortcut)
    }
}

// MARK: - Extensions

extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}

#Preview {
    CustomShortcutSettingsView()
}