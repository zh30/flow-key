import SwiftUI

struct AddPhraseView: View {
    let onComplete: (PhraseManager.Phrase) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var content = ""
    @State private var selectedCategory: PhraseManager.PhraseCategory = .greeting
    @State private var tags: String = ""
    @State private var shortcut = ""
    @State private var priority = 0
    @State private var isFavorite = false
    @State private var isAdding = false
    
    private var tagArray: [String] {
        tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("常用语内容", text: $content, axis: .vertical)
                        .lineLimit(4)
                    
                    Picker("分类", selection: $selectedCategory) {
                        ForEach(PhraseManager.PhraseCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.displayName)
                            }
                        }
                    }
                }
                
                Section(header: Text("标签")) {
                    TextField("标签 (用逗号分隔)", text: $tags)
                    
                    if !tagArray.isEmpty {
                        TagsView(tags: tagArray)
                    }
                }
                
                Section(header: Text("快捷键")) {
                    TextField("快捷键 (可选)", text: $shortcut)
                    Text("设置快捷键后可以通过快捷键快速插入此常用语")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("设置")) {
                    Stepper("优先级: \(priority)", value: $priority, in: 0...10)
                    
                    Toggle("收藏", isOn: $isFavorite)
                }
                
                Section {
                    Button("添加") {
                        addPhrase()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(content.isEmpty || isAdding)
                    
                    if isAdding {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .navigationTitle("添加常用语")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 600)
    }
    
    private func addPhrase() {
        isAdding = true
        
        let phrase = PhraseManager.Phrase(
            content: content,
            category: selectedCategory,
            tags: tagArray,
            shortcut: shortcut.isEmpty ? nil : shortcut,
            priority: priority,
            isFavorite: isFavorite
        )
        
        onComplete(phrase)
        dismiss()
    }
}

// MARK: - Edit Phrase View

struct EditPhraseView: View {
    let phrase: PhraseManager.Phrase
    let onComplete: (PhraseManager.Phrase) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var content: String
    @State private var selectedCategory: PhraseManager.PhraseCategory
    @State private var tags: String
    @State private var shortcut: String
    @State private var priority: Int
    @State private var isFavorite: Bool
    @State private var isUpdating = false
    
    private var tagArray: [String] {
        tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    init(phrase: PhraseManager.Phrase, onComplete: @escaping (PhraseManager.Phrase) -> Void) {
        self.phrase = phrase
        self.onComplete = onComplete
        
        _content = State(initialValue: phrase.content)
        _selectedCategory = State(initialValue: phrase.category)
        _tags = State(initialValue: phrase.tags.joined(separator: ", "))
        _shortcut = State(initialValue: phrase.shortcut ?? "")
        _priority = State(initialValue: phrase.priority)
        _isFavorite = State(initialValue: phrase.isFavorite)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("常用语内容", text: $content, axis: .vertical)
                        .lineLimit(4)
                    
                    Picker("分类", selection: $selectedCategory) {
                        ForEach(PhraseManager.PhraseCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.displayName)
                            }
                        }
                    }
                }
                
                Section(header: Text("标签")) {
                    TextField("标签 (用逗号分隔)", text: $tags)
                    
                    if !tagArray.isEmpty {
                        TagsView(tags: tagArray)
                    }
                }
                
                Section(header: Text("快捷键")) {
                    TextField("快捷键 (可选)", text: $shortcut)
                    Text("设置快捷键后可以通过快捷键快速插入此常用语")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("设置")) {
                    Stepper("优先级: \(priority)", value: $priority, in: 0...10)
                    
                    Toggle("收藏", isOn: $isFavorite)
                }
                
                Section {
                    Button("更新") {
                        updatePhrase()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(content.isEmpty || isUpdating)
                    
                    if isUpdating {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .navigationTitle("编辑常用语")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 600)
    }
    
    private func updatePhrase() {
        isUpdating = true
        
        let updatedPhrase = PhraseManager.Phrase(
            id: phrase.id,
            content: content,
            category: selectedCategory,
            tags: tagArray,
            shortcut: shortcut.isEmpty ? nil : shortcut,
            priority: priority,
            usageCount: phrase.usageCount,
            lastUsed: phrase.lastUsed,
            isFavorite: isFavorite,
            createdAt: phrase.createdAt,
            updatedAt: Date()
        )
        
        onComplete(updatedPhrase)
        dismiss()
    }
}

// MARK: - Import Phrases View

struct ImportPhrasesView: View {
    let onComplete: ([PhraseManager.Phrase]) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedFile: URL?
    @State private var isImporting = false
    @State private var errorMessage = ""
    @State private var importCount = 0
    
    var body: some View {
        NavigationView {
            VStack {
                if let selectedFile = selectedFile {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text(selectedFile.lastPathComponent)
                            .font(.headline)
                        
                        Text(selectedFile.path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        if importCount > 0 {
                            Text("成功导入 \(importCount) 个常用语")
                                .foregroundColor(.green)
                                .font(.headline)
                        }
                        
                        HStack {
                            Button("重新选择") {
                                selectedFile = nil
                                errorMessage = ""
                                importCount = 0
                            }
                            .buttonStyle(.bordered)
                            
                            Button("导入") {
                                importPhrases()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isImporting)
                        }
                        
                        if isImporting {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding()
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("选择要导入的文件")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("支持 JSON 格式的常用语文件")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("选择文件") {
                            selectFile()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
            .navigationTitle("导入常用语")
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
    
    private func selectFile() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["json"]
        
        if openPanel.runModal() == .OK {
            selectedFile = openPanel.url
        }
    }
    
    private func importPhrases() {
        guard let fileURL = selectedFile else { return }
        
        isImporting = true
        errorMessage = ""
        
        Task {
            do {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                let phrases = try decoder.decode([PhraseManager.Phrase].self, from: data)
                
                await MainActor.run {
                    importCount = phrases.count
                    onComplete(phrases)
                    
                    if importCount > 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            dismiss()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "导入失败: \(error.localizedDescription)"
                    isImporting = false
                }
            }
        }
    }
}

// MARK: - Export Phrases View

struct ExportPhrasesView: View {
    let phrases: [PhraseManager.Phrase]
    @Environment(\.dismiss) var dismiss
    
    @State private var isExporting = false
    @State private var errorMessage = ""
    @State private var exportURL: URL?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let exportURL = exportURL {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("导出成功")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("常用语已导出到:")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text(exportURL.path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                        
                        Button("完成") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("导出常用语")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("将 \(phrases.count) 个常用语导出为 JSON 文件")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        Button("导出") {
                            exportPhrases()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isExporting)
                        
                        if isExporting {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
            .navigationTitle("导出常用语")
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
    
    private func exportPhrases() {
        isExporting = true
        errorMessage = ""
        
        Task {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(phrases)
                
                let savePanel = NSSavePanel()
                savePanel.allowedFileTypes = ["json"]
                savePanel.nameFieldStringValue = "phrases_\(Date().timeIntervalSince1970).json"
                
                if savePanel.runModal() == .OK {
                    guard let url = savePanel.url else { return }
                    
                    try data.write(to: url)
                    
                    await MainActor.run {
                        exportURL = url
                        isExporting = false
                    }
                } else {
                    await MainActor.run {
                        isExporting = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "导出失败: \(error.localizedDescription)"
                    isExporting = false
                }
            }
        }
    }
}

#Preview {
    AddPhraseView { _ in }
}