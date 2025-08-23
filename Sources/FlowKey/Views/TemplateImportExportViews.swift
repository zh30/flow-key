import SwiftUI

// MARK: - Import Templates View

struct ImportTemplatesView: View {
    let onComplete: (Data) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedFile: URL?
    @State private var isImporting = false
    @State private var errorMessage = ""
    @State private var importCount = 0
    @State private var showPreview = false
    @State private var previewTemplates: [TemplateManager.Template] = []
    @State private var replaceExisting = false
    @State private var conflicts: [TemplateManager.Template] = []
    
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
                            Text("成功导入 \(importCount) 个模板")
                                .foregroundColor(.green)
                                .font(.headline)
                        }
                        
                        if !conflicts.isEmpty {
                            VStack(spacing: 12) {
                                Text("发现 \(conflicts.count) 个冲突")
                                    .foregroundColor(.orange)
                                    .font(.headline)
                                
                                Text("以下模板名称已存在:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(conflicts, id: \.id) { template in
                                            Text("• \(template.name)")
                                                .font(.caption)
                                        }
                                    }
                                }
                                .frame(maxHeight: 100)
                                
                                Toggle("替换现有模板", isOn: $replaceExisting)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        if showPreview && !previewTemplates.isEmpty {
                            VStack(spacing: 12) {
                                Text("预览导入的模板:")
                                    .font(.headline)
                                
                                ScrollView {
                                    LazyVStack(spacing: 8) {
                                        ForEach(previewTemplates, id: \.id) { template in
                                            TemplatePreviewCard(template: template)
                                        }
                                    }
                                }
                                .frame(maxHeight: 200)
                            }
                        }
                        
                        HStack {
                            Button("重新选择") {
                                selectedFile = nil
                                errorMessage = ""
                                importCount = 0
                                conflicts = []
                                showPreview = false
                                previewTemplates = []
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                            
                            if showPreview {
                                Button("导入") {
                                    importTemplates()
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(isImporting)
                            } else {
                                Button("预览") {
                                    previewImport()
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(isImporting)
                            }
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
                        
                        Text("选择要导入的模板文件")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("支持 JSON 格式的模板文件")
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
            .navigationTitle("导入模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
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
    
    private func previewImport() {
        guard let fileURL = selectedFile else { return }
        
        isImporting = true
        errorMessage = ""
        
        Task {
            do {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                let templates = try decoder.decode([TemplateManager.Template].self, from: data)
                
                // Check for conflicts
                let existingNames = Set(TemplateManager.shared.templates.map { $0.name })
                conflicts = templates.filter { existingNames.contains($0.name) }
                
                await MainActor.run {
                    self.previewTemplates = templates
                    self.showPreview = true
                    self.isImporting = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "预览失败: \(error.localizedDescription)"
                    self.isImporting = false
                }
            }
        }
    }
    
    private func importTemplates() {
        guard let fileURL = selectedFile else { return }
        
        isImporting = true
        errorMessage = ""
        
        Task {
            do {
                let data = try Data(contentsOf: fileURL)
                onComplete(data)
                
                await MainActor.run {
                    self.importCount = self.previewTemplates.count
                    self.isImporting = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "导入失败: \(error.localizedDescription)"
                    self.isImporting = false
                }
            }
        }
    }
}

// MARK: - Export Templates View

struct ExportTemplatesView: View {
    let templates: [TemplateManager.Template]
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTemplates: Set<UUID> = []
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var errorMessage = ""
    @State private var includeVariables = true
    @State private var includeMetadata = true
    
    private var filteredTemplates: [TemplateManager.Template] {
        if selectedTemplates.isEmpty {
            return templates
        } else {
            return templates.filter { selectedTemplates.contains($0.id) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Template Selection
                templateSelectionView
                
                // Export Options
                exportOptionsView
                
                // Export Button
                exportButtonView
                
                // Result
                if let exportURL = exportURL {
                    resultView
                }
            }
            .navigationTitle("导出模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 700, height: 600)
    }
    
    private var templateSelectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("选择要导出的模板")
                    .font(.headline)
                
                Spacer()
                
                Button(selectedTemplates.isEmpty ? "全选" : "取消全选") {
                    if selectedTemplates.isEmpty {
                        selectedTemplates = Set(templates.map { $0.id })
                    } else {
                        selectedTemplates = []
                    }
                }
                .buttonStyle(.bordered)
            }
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(templates, id: \.id) { template in
                        TemplateSelectionCard(
                            template: template,
                            isSelected: selectedTemplates.contains(template.id),
                            onToggle: {
                                if selectedTemplates.contains(template.id) {
                                    selectedTemplates.remove(template.id)
                                } else {
                                    selectedTemplates.insert(template.id)
                                }
                            }
                        )
                    }
                }
                .padding()
            }
            .frame(maxHeight: 300)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var exportOptionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("导出选项")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("包含变量", isOn: $includeVariables)
                Toggle("包含元数据", isOn: $includeMetadata)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var exportButtonView: some View {
        HStack {
            Text("将导出 \(filteredTemplates.count) 个模板")
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("导出") {
                exportTemplates()
            }
            .buttonStyle(.borderedProminent)
            .disabled(filteredTemplates.isEmpty || isExporting)
            
            if isExporting {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding()
    }
    
    private var resultView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("导出成功")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("模板已导出到:")
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
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func exportTemplates() {
        isExporting = true
        errorMessage = ""
        
        Task {
            do {
                // Prepare templates for export
                var exportTemplates = filteredTemplates
                
                if !includeVariables {
                    exportTemplates = exportTemplates.map { template in
                        var modifiedTemplate = template
                        modifiedTemplate.variables = []
                        return modifiedTemplate
                    }
                }
                
                if !includeMetadata {
                    exportTemplates = exportTemplates.map { template in
                        var modifiedTemplate = template
                        modifiedTemplate.usageCount = 0
                        modifiedTemplate.lastUsed = nil
                        modifiedTemplate.isFavorite = false
                        return modifiedTemplate
                    }
                }
                
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(exportTemplates)
                
                let savePanel = NSSavePanel()
                savePanel.allowedFileTypes = ["json"]
                savePanel.nameFieldStringValue = "templates_\(Date().timeIntervalSince1970).json"
                
                if savePanel.runModal() == .OK {
                    guard let url = savePanel.url else { return }
                    
                    try data.write(to: url)
                    
                    await MainActor.run {
                        self.exportURL = url
                        self.isExporting = false
                    }
                } else {
                    await MainActor.run {
                        self.isExporting = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "导出失败: \(error.localizedDescription)"
                    self.isExporting = false
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct TemplateSelectionCard: View {
    let template: TemplateManager.Template
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: template.type.icon)
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text(template.name)
                        .font(.headline)
                    
                    CategoryBadge(category: template.category)
                    
                    Spacer()
                    
                    if template.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                
                Text(template.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if !template.tags.isEmpty {
                    TagsView(tags: template.tags)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}

struct TemplatePreviewCard: View {
    let template: TemplateManager.Template
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: template.type.icon)
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text(template.name)
                    .font(.headline)
                
                Spacer()
            }
            
            Text(template.type.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !template.variables.isEmpty {
                Text("包含 \(template.variables.count) 个变量")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}

// MARK: - Reusable Components

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

#Preview {
    ImportTemplatesView { _ in }
}