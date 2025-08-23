import SwiftUI

struct PhraseManagementView: View {
    @StateObject private var phraseManager = PhraseManager.shared
    @State private var searchText = ""
    @State private var selectedCategory: PhraseManager.PhraseCategory? = nil
    @State private var showAddPhraseSheet = false
    @State private var showImportSheet = false
    @State private var showExportSheet = false
    @State private var selectedPhrase: PhraseManager.Phrase?
    @State private var showEditPhraseSheet = false
    
    private var filteredPhrases: [PhraseManager.Phrase] {
        var phrases = phraseManager.phrases
        
        // Apply category filter
        if let category = selectedCategory {
            phrases = phrases.filter { $0.category == category }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            phrases = phrases.filter { phrase in
                phrase.content.localizedCaseInsensitiveContains(searchText) ||
                phrase.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return phrases
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // Category Filter
                CategoryFilter(
                    selectedCategory: $selectedCategory,
                    categories: phraseManager.categories
                )
                .padding(.horizontal)
                
                // Phrases List
                if phraseManager.isProcessing {
                    ProgressView("处理中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredPhrases.isEmpty {
                    EmptyStateView(
                        title: "暂无常用语",
                        subtitle: "添加您的第一个常用语以提高输入效率",
                        action: { showAddPhraseSheet = true }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    PhrasesList(
                        phrases: filteredPhrases,
                        onUse: { phrase in
                            Task {
                                try? await phraseManager.usePhrase(phrase.id)
                            }
                        },
                        onEdit: { phrase in
                            selectedPhrase = phrase
                            showEditPhraseSheet = true
                        },
                        onDelete: { phrase in
                            Task {
                                try? await phraseManager.deletePhrase(phrase.id)
                            }
                        }
                    )
                }
            }
            .navigationTitle("常用语管理")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("添加常用语") {
                            showAddPhraseSheet = true
                        }
                        Button("导入常用语") {
                            showImportSheet = true
                        }
                        Button("导出常用语") {
                            showExportSheet = true
                        }
                        Divider()
                        Button("刷新") {
                            phraseManager.loadPhrases()
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .frame(width: 800, height: 600)
        .sheet(isPresented: $showAddPhraseSheet) {
            AddPhraseView { phrase in
                Task {
                    try? await phraseManager.addPhrase(
                        content: phrase.content,
                        category: phrase.category,
                        tags: phrase.tags,
                        shortcut: phrase.shortcut,
                        priority: phrase.priority,
                        isFavorite: phrase.isFavorite
                    )
                }
            }
        }
        .sheet(isPresented: $showEditPhraseSheet) {
            if let phrase = selectedPhrase {
                EditPhraseView(phrase: phrase) { updatedPhrase in
                    Task {
                        try? await phraseManager.updatePhrase(updatedPhrase)
                    }
                }
            }
        }
        .sheet(isPresented: $showImportSheet) {
            ImportPhrasesView { phrases in
                Task {
                    try? await phraseManager.importPhrases(phrases)
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ExportPhrasesView(phrases: phraseManager.phrases)
        }
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索常用语...", text: $text)
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

// MARK: - Category Filter

struct CategoryFilter: View {
    @Binding var selectedCategory: PhraseManager.PhraseCategory?
    let categories: [PhraseManager.PhraseCategory]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    FilterChip(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: selectedCategory == category,
                        onTap: {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Filter Chip

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

// MARK: - Phrases List

struct PhrasesList: View {
    let phrases: [PhraseManager.Phrase]
    let onUse: (PhraseManager.Phrase) -> Void
    let onEdit: (PhraseManager.Phrase) -> Void
    let onDelete: (PhraseManager.Phrase) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(phrases, id: \.id) { phrase in
                    PhraseCard(
                        phrase: phrase,
                        onUse: { onUse(phrase) },
                        onEdit: { onEdit(phrase) },
                        onDelete: { onDelete(phrase) }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Phrase Card

struct PhraseCard: View {
    let phrase: PhraseManager.Phrase
    let onUse: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(phrase.content)
                        .font(.body)
                        .lineLimit(3)
                    
                    HStack {
                        CategoryBadge(category: phrase.category)
                        
                        if phrase.isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                        
                        if let shortcut = phrase.shortcut {
                            Text("快捷键: \(shortcut)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("使用 \(phrase.usageCount) 次")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Button(action: onUse) {
                        Image(systemName: "text.insert")
                            .font(.title3)
                    }
                    .buttonStyle(.bordered)
                    .help("插入常用语")
                    
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.title3)
                    }
                    .buttonStyle(.bordered)
                    .help("编辑常用语")
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.title3)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    .help("删除常用语")
                }
            }
            
            if !phrase.tags.isEmpty {
                TagsView(tags: phrase.tags)
            }
            
            if let lastUsed = phrase.lastUsed {
                HStack {
                    Text("上次使用: \(lastUsed.formatted())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Category Badge

struct CategoryBadge: View {
    let category: PhraseManager.PhraseCategory
    
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

// MARK: - Tags View

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

// MARK: - Empty State View

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("添加常用语") {
                action()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    PhraseManagementView()
}