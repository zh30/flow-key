import SwiftUI

struct TemplateManagementView: View {
    @StateObject private var templateManager = TemplateManager.shared
    @State private var searchText = ""
    @State private var selectedCategory: TemplateManager.TemplateCategory? = nil
    @State private var selectedType: TemplateManager.TemplateType? = nil
    @State private var showAddTemplateSheet = false
    @State private var showImportSheet = false
    @State private var showExportSheet = false
    @State private var selectedTemplate: TemplateManager.Template?
    @State private var showEditTemplateSheet = false
    @State private var showUseTemplateSheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    private var filteredTemplates: [TemplateManager.Template] {
        var templates = templateManager.templates
        
        // Apply category filter
        if let category = selectedCategory {
            templates = templates.filter { $0.category == category }
        }
        
        // Apply type filter
        if let type = selectedType {
            templates = templates.filter { $0.type == type }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            templates = templates.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.content.localizedCaseInsensitiveContains(searchText) ||
                template.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return templates
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search and Filter Bar
                searchAndFilterBar
                
                // Templates List
                if templateManager.isProcessing {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredTemplates.isEmpty {
                    EmptyStateView(
                        title: "暂无模板",
                        subtitle: "创建您的第一个模板以提高工作效率",
                        action: { showAddTemplateSheet = true }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    TemplatesList(
                        templates: filteredTemplates,
                        onUse: { template in
                            useTemplate(template)
                        },
                        onEdit: { template in
                            selectedTemplate = template
                            showEditTemplateSheet = true
                        },
                        onDelete: { template in
                            deleteTemplate(template)
                        },
                        onDuplicate: { template in
                            duplicateTemplate(template)
                        },
                        onExport: { template in
                            exportTemplate(template)
                        }
                    )
                }
            }
            .navigationTitle("模板管理")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("添加模板") {
                            showAddTemplateSheet = true
                        }
                        Button("导入模板") {
                            showImportSheet = true
                        }
                        Button("导出模板") {
                            showExportSheet = true
                        }
                        Divider()
                        Button("刷新") {
                            templateManager.loadTemplates()
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .frame(width: 1000, height: 700)
        .sheet(isPresented: $showAddTemplateSheet) {
            AddTemplateView { template in
                Task {
                    try? await templateManager.addTemplate(template)
                }
            }
        }
        .sheet(isPresented: $showEditTemplateSheet) {
            if let template = selectedTemplate {
                EditTemplateView(template: template) { updatedTemplate in
                    Task {
                        try? await templateManager.updateTemplate(updatedTemplate)
                    }
                }
            }
        }
        .sheet(isPresented: $showUseTemplateSheet) {
            if let template = selectedTemplate {
                UseTemplateView(template: template) { renderedContent in
                    // Handle rendered content (copy to clipboard, insert, etc.)
                    copyToClipboard(renderedContent)
                }
            }
        }
        .sheet(isPresented: $showImportSheet) {
            ImportTemplatesView { templates in
                Task {
                    do {
                        try await templateManager.importTemplates(from: templates)
                    } catch {
                        showAlert(title: "导入失败", message: error.localizedDescription)
                    }
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ExportTemplatesView(templates: templateManager.templates)
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("确定"))
            )
        }
    }
    
    // MARK: - Search and Filter Bar
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            // Search Bar
            SearchBar(text: $searchText)
                .padding(.horizontal)
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Category Filter
                    ForEach(templateManager.categories, id: \.self) { category in
                        FilterChip(
                            title: category.displayName,
                            icon: category.icon,
                            isSelected: selectedCategory == category,
                            onTap: {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        )
                    }
                    
                    Divider()
                        .frame(height: 20)
                    
                    // Type Filter
                    ForEach(TemplateManager.TemplateType.allCases, id: \.self) { type in
                        FilterChip(
                            title: type.displayName,
                            icon: type.icon,
                            isSelected: selectedType == type,
                            onTap: {
                                selectedType = selectedType == type ? nil : type
                            }
                        )
                    }
                    
                    // Special Filters
                    FilterChip(
                        title: "收藏",
                        icon: "star",
                        isSelected: templateManager.getFavoriteTemplates().count > 0 && filteredTemplates.count == templateManager.getFavoriteTemplates().count,
                        onTap: {
                            // Toggle favorite filter
                        }
                    )
                    
                    FilterChip(
                        title: "最近使用",
                        icon: "clock",
                        isSelected: templateManager.getRecentTemplates().count > 0 && filteredTemplates.count == templateManager.getRecentTemplates().count,
                        onTap: {
                            // Toggle recent filter
                        }
                    )
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Methods
    
    private func useTemplate(_ template: TemplateManager.Template) {
        selectedTemplate = template
        showUseTemplateSheet = true
    }
    
    private func deleteTemplate(_ template: TemplateManager.Template) {
        let alert = NSAlert()
        alert.messageText = "删除模板"
        alert.informativeText = "确定要删除 '\(template.name)' 模板吗？此操作不可撤销。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            Task {
                try? await templateManager.deleteTemplate(template.id)
            }
        }
    }
    
    private func duplicateTemplate(_ template: TemplateManager.Template) {
        var duplicatedTemplate = template
        duplicatedTemplate.id = UUID()
        duplicatedTemplate.name = "\(template.name) (副本)"
        duplicatedTemplate.usageCount = 0
        duplicatedTemplate.lastUsed = nil
        duplicatedTemplate.createdAt = Date()
        duplicatedTemplate.updatedAt = Date()
        
        Task {
            try? await templateManager.addTemplate(duplicatedTemplate)
        }
    }
    
    private func exportTemplate(_ template: TemplateManager.Template) {
        Task {
            do {
                let data = try templateManager.exportTemplates([template.id])
                
                let savePanel = NSSavePanel()
                savePanel.allowedFileTypes = ["json"]
                savePanel.nameFieldStringValue = "\(template.name)_\(Date().timeIntervalSince1970).json"
                
                if savePanel.runModal() == .OK {
                    guard let url = savePanel.url else { return }
                    try data.write(to: url)
                    
                    await MainActor.run {
                        showAlert(title: "导出成功", message: "模板已成功导出到 \(url.path)")
                    }
                }
            } catch {
                await MainActor.run {
                    showAlert(title: "导出失败", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        showAlert(title: "已复制到剪贴板", message: "渲染后的内容已复制到剪贴板")
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - Templates List

struct TemplatesList: View {
    let templates: [TemplateManager.Template]
    let onUse: (TemplateManager.Template) -> Void
    let onEdit: (TemplateManager.Template) -> Void
    let onDelete: (TemplateManager.Template) -> Void
    let onDuplicate: (TemplateManager.Template) -> Void
    let onExport: (TemplateManager.Template) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(templates, id: \.id) { template in
                    TemplateCard(
                        template: template,
                        onUse: { onUse(template) },
                        onEdit: { onEdit(template) },
                        onDelete: { onDelete(template) },
                        onDuplicate: { onDuplicate(template) },
                        onExport: { onExport(template) }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: TemplateManager.Template
    let onUse: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    let onExport: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack {
                    Image(systemName: template.type.icon)
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text(template.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    CategoryBadge(category: template.category)
                    
                    if template.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                Text("使用 \(template.usageCount) 次")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Name
            Text(template.name)
                .font(.headline)
                .lineLimit(1)
            
            // Content Preview
            Text(template.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Tags
            if !template.tags.isEmpty {
                TagsView(tags: template.tags)
            }
            
            // Variables
            if !template.variables.isEmpty {
                HStack {
                    Text("变量:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(template.variables, id: \.id) { variable in
                                Text("{{\(variable.name)}}")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            
            // Last Used
            if let lastUsed = template.lastUsed {
                HStack {
                    Text("上次使用: \(lastUsed.formatted())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            // Actions
            HStack {
                Button("使用") {
                    onUse()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button("编辑") {
                    onEdit()
                }
                .buttonStyle(.bordered)
                
                Button("复制") {
                    onDuplicate()
                }
                .buttonStyle(.bordered)
                
                Button("导出") {
                    onExport()
                }
                .buttonStyle(.bordered)
                
                Button("删除") {
                    onDelete()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Supporting Views

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索模板...", text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryBadge: View {
    let category: TemplateManager.TemplateCategory
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .font(.caption)
            Text(category.displayName)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(category.color).opacity(0.2))
        .cornerRadius(6)
    }
}

struct TagsView: View {
    let tags: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(6)
                }
            }
        }
    }
}

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("添加模板") {
                action()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    TemplateManagementView()
}