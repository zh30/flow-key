import SwiftUI

// MARK: - Add Knowledge Item View

struct AddKnowledgeItemView: View {
    let onComplete: (KnowledgeBaseManager.KnowledgeItem) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var content = ""
    @State private var selectedCategory: KnowledgeBaseManager.KnowledgeCategory = .notes
    @State private var selectedType: KnowledgeBaseManager.KnowledgeType = .note
    @State private var tags: String = ""
    @State private var isStarred = false
    @State private var isAdding = false
    
    private var tagArray: [String] {
        tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("标题", text: $title)
                    
                    Picker("类别", selection: $selectedCategory) {
                        ForEach(KnowledgeBaseManager.KnowledgeCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.displayName)
                            }
                        }
                    }
                    
                    Picker("类型", selection: $selectedType) {
                        ForEach(KnowledgeBaseManager.KnowledgeType.allCases, id: \.self) { type in
                            Text(type.displayName)
                        }
                    }
                }
                
                Section(header: Text("内容")) {
                    TextEditor(text: $content)
                        .frame(height: 200)
                }
                
                Section(header: Text("标签")) {
                    TextField("标签 (用逗号分隔)", text: $tags)
                    
                    if !tagArray.isEmpty {
                        TagsView(tags: tagArray)
                    }
                }
                
                Section(header: Text("设置")) {
                    Toggle("收藏", isOn: $isStarred)
                }
                
                Section {
                    Button("添加") {
                        addItem()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.isEmpty || content.isEmpty || isAdding)
                    
                    if isAdding {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .navigationTitle("添加知识条目")
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
    
    private func addItem() {
        isAdding = true
        
        let item = KnowledgeBaseManager.KnowledgeItem(
            id: UUID().uuidString,
            title: title,
            content: content,
            type: selectedType,
            category: selectedCategory,
            tags: tagArray,
            isStarred: isStarred
        )
        
        onComplete(item)
        dismiss()
    }
}

// MARK: - Add Knowledge Collection View

struct AddKnowledgeCollectionView: View {
    let onComplete: (KnowledgeBaseManager.KnowledgeCollection) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedCategory: KnowledgeBaseManager.KnowledgeCategory? = nil
    @State private var tags: String = ""
    @State private var isPublic = false
    @State private var isAdding = false
    
    private var tagArray: [String] {
        tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("集合名称", text: $name)
                    
                    TextField("描述", text: $description, axis: .vertical)
                        .lineLimit(3)
                    
                    Picker("类别", selection: $selectedCategory) {
                        Text("无").map { Optional<KnowledgeBaseManager.KnowledgeCategory>.none }
                        ForEach(KnowledgeBaseManager.KnowledgeCategory.allCases, id: \.self) { category in
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
                
                Section(header: Text("设置")) {
                    Toggle("公开", isOn: $isPublic)
                }
                
                Section {
                    Button("创建") {
                        addCollection()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.isEmpty || isAdding)
                    
                    if isAdding {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .navigationTitle("创建知识集合")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 500)
    }
    
    private func addCollection() {
        isAdding = true
        
        let collection = KnowledgeBaseManager.KnowledgeCollection(
            id: UUID().uuidString,
            name: name,
            description: description.isEmpty ? nil : description,
            category: selectedCategory,
            tags: tagArray,
            isPublic: isPublic
        )
        
        onComplete(collection)
        dismiss()
    }
}

// MARK: - Import File View

struct ImportFileView: View {
    let onComplete: (URL) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedFile: URL?
    @State private var isImporting = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if let selectedFile = selectedFile {
                    VStack(spacing: 20) {
                        Image(systemName: "doc")
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
                        
                        HStack {
                            Button("重新选择") {
                                selectedFile = nil
                                errorMessage = ""
                            }
                            .buttonStyle(.bordered)
                            
                            Button("导入") {
                                importFile()
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
                        
                        Text("支持文本文件、Markdown文件、代码文件等")
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
            .navigationTitle("导入文件")
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
        
        let supportedExtensions = KnowledgeBaseManager.KnowledgeType.allCases
            .flatMap { $0.fileExtensions }
            .map { "*.\($0)" }
        
        openPanel.allowedFileTypes = supportedExtensions
        
        if openPanel.runModal() == .OK {
            selectedFile = openPanel.url
        }
    }
    
    private func importFile() {
        guard let fileURL = selectedFile else { return }
        
        isImporting = true
        errorMessage = ""
        
        Task {
            do {
                onComplete(fileURL)
                await MainActor.run {
                    dismiss()
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

// MARK: - Edit Knowledge Item View

struct EditKnowledgeItemView: View {
    let item: KnowledgeBaseManager.KnowledgeItem
    let onComplete: (KnowledgeBaseManager.KnowledgeItem) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String
    @State private var content: String
    @State private var selectedCategory: KnowledgeBaseManager.KnowledgeCategory
    @State private var selectedType: KnowledgeBaseManager.KnowledgeType
    @State private var tags: String
    @State private var isStarred: Bool
    @State private var isArchived: Bool
    @State private var isUpdating = false
    
    private var tagArray: [String] {
        tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    init(item: KnowledgeBaseManager.KnowledgeItem, onComplete: @escaping (KnowledgeBaseManager.KnowledgeItem) -> Void) {
        self.item = item
        self.onComplete = onComplete
        
        _title = State(initialValue: item.title)
        _content = State(initialValue: item.content)
        _selectedCategory = State(initialValue: item.category)
        _selectedType = State(initialValue: item.type)
        _tags = State(initialValue: item.tags.joined(separator: ", "))
        _isStarred = State(initialValue: item.isStarred)
        _isArchived = State(initialValue: item.isArchived)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("标题", text: $title)
                    
                    Picker("类别", selection: $selectedCategory) {
                        ForEach(KnowledgeBaseManager.KnowledgeCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.displayName)
                            }
                        }
                    }
                    
                    Picker("类型", selection: $selectedType) {
                        ForEach(KnowledgeBaseManager.KnowledgeType.allCases, id: \.self) { type in
                            Text(type.displayName)
                        }
                    }
                }
                
                Section(header: Text("内容")) {
                    TextEditor(text: $content)
                        .frame(height: 200)
                }
                
                Section(header: Text("标签")) {
                    TextField("标签 (用逗号分隔)", text: $tags)
                    
                    if !tagArray.isEmpty {
                        TagsView(tags: tagArray)
                    }
                }
                
                Section(header: Text("设置")) {
                    Toggle("收藏", isOn: $isStarred)
                    Toggle("归档", isOn: $isArchived)
                }
                
                Section {
                    Button("更新") {
                        updateItem()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.isEmpty || content.isEmpty || isUpdating)
                    
                    if isUpdating {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .navigationTitle("编辑知识条目")
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
    
    private func updateItem() {
        isUpdating = true
        
        let updatedItem = KnowledgeBaseManager.KnowledgeItem(
            id: item.id,
            title: title,
            content: content,
            type: selectedType,
            category: selectedCategory,
            tags: tagArray,
            metadata: item.metadata,
            createdAt: item.createdAt,
            updatedAt: Date(),
            fileSize: item.fileSize,
            url: item.url,
            embedding: item.embedding,
            isStarred: isStarred,
            isArchived: isArchived
        )
        
        onComplete(updatedItem)
        dismiss()
    }
}

#Preview {
    AddKnowledgeItemView { _ in }
}