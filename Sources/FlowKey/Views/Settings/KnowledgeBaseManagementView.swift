import SwiftUI

struct KnowledgeBaseManagementView: View {
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var selectedCategory: KnowledgeBaseManager.KnowledgeCategory? = nil
    @State private var selectedType: KnowledgeBaseManager.KnowledgeType? = nil
    @State private var showAddItemSheet = false
    @State private var showAddCollectionSheet = false
    @State private var showImportSheet = false
    @State private var knowledgeItems: [KnowledgeBaseManager.KnowledgeItem] = []
    @State private var collections: [KnowledgeBaseManager.KnowledgeCollection] = []
    @State private var searchResults: [KnowledgeBaseManager.SearchResult] = []
    @State private var isSearching = false
    @State private var isLoading = false
    @State private var knowledgeStats: KnowledgeBaseManager.KnowledgeStats?
    
    private let knowledgeManager = KnowledgeBaseManager.shared
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                SearchBar(text: $searchText, onSearch: performSearch)
                    .padding(.horizontal)
                
                // Filter Tabs
                FilterTabs(
                    selectedCategory: $selectedCategory,
                    selectedType: $selectedType,
                    onFilterChange: performSearch
                )
                
                // Content
                TabView(selection: $selectedTab) {
                    // Items Tab
                    ItemsView(
                        items: filteredItems,
                        searchResults: searchResults,
                        isSearching: isSearching,
                        onRefresh: refreshData,
                        onAddItem: { showAddItemSheet = true }
                    )
                    .tabItem {
                        Label("知识条目", systemImage: "doc")
                    }
                    .tag(0)
                    
                    // Collections Tab
                    CollectionsView(
                        collections: collections,
                        onRefresh: refreshData,
                        onAddCollection: { showAddCollectionSheet = true }
                    )
                    .tabItem {
                        Label("知识集合", systemImage: "folder")
                    }
                    .tag(1)
                    
                    // Stats Tab
                    StatsView(
                        stats: knowledgeStats,
                        onRefresh: refreshStats
                    )
                    .tabItem {
                        Label("统计", systemImage: "chart.bar")
                    }
                    .tag(2)
                    
                    // Tags Tab
                    TagsView(
                        items: knowledgeItems,
                        onRefresh: refreshData
                    )
                    .tabItem {
                        Label("标签", systemImage: "tag")
                    }
                    .tag(3)
                }
            }
            .navigationTitle("知识库管理")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("添加知识条目") {
                            showAddItemSheet = true
                        }
                        Button("创建知识集合") {
                            showAddCollectionSheet = true
                        }
                        Button("导入文件") {
                            showImportSheet = true
                        }
                        Divider()
                        Button("刷新") {
                            refreshData()
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .frame(width: 800, height: 600)
        .onAppear {
            initialize()
        }
        .sheet(isPresented: $showAddItemSheet) {
            AddKnowledgeItemView { item in
                addKnowledgeItem(item)
            }
        }
        .sheet(isPresented: $showAddCollectionSheet) {
            AddKnowledgeCollectionView { collection in
                addKnowledgeCollection(collection)
            }
        }
        .sheet(isPresented: $showImportSheet) {
            ImportFileView { url in
                importFile(url)
            }
        }
    }
    
    private func initialize() {
        isLoading = true
        
        Task {
            await knowledgeManager.initialize()
            await refreshData()
            await refreshStats()
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func refreshData() {
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            let items = knowledgeManager.getAllKnowledgeItems()
            let collections = knowledgeManager.getAllCollections()
            
            await MainActor.run {
                self.knowledgeItems = items
                self.collections = collections
                isLoading = false
                
                // Refresh search if needed
                if !searchText.isEmpty {
                    performSearch()
                }
            }
        }
    }
    
    private func refreshStats() {
        Task {
            let stats = await knowledgeManager.getKnowledgeStats()
            await MainActor.run {
                self.knowledgeStats = stats
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        
        Task {
            do {
                let results = try await knowledgeManager.searchKnowledge(
                    query: searchText,
                    category: selectedCategory,
                    type: selectedType
                )
                
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.searchResults = []
                    self.isSearching = false
                }
            }
        }
    }
    
    private func addKnowledgeItem(_ item: KnowledgeBaseManager.KnowledgeItem) {
        Task {
            do {
                _ = try await knowledgeManager.addKnowledgeItem(
                    title: item.title,
                    content: item.content,
                    type: item.type,
                    category: item.category,
                    tags: item.tags,
                    metadata: item.metadata
                )
                await refreshData()
                await refreshStats()
            } catch {
                print("Failed to add knowledge item: \(error)")
            }
        }
    }
    
    private func addKnowledgeCollection(_ collection: KnowledgeBaseManager.KnowledgeCollection) {
        Task {
            do {
                _ = try await knowledgeManager.createCollection(
                    name: collection.name,
                    description: collection.description,
                    category: collection.category,
                    tags: collection.tags
                )
                await refreshData()
            } catch {
                print("Failed to create collection: \(error)")
            }
        }
    }
    
    private func importFile(_ url: URL) {
        Task {
            do {
                _ = try await knowledgeManager.processFile(url)
                await refreshData()
                await refreshStats()
            } catch {
                print("Failed to import file: \(error)")
            }
        }
    }
    
    private var filteredItems: [KnowledgeBaseManager.KnowledgeItem] {
        var items = knowledgeItems
        
        // Apply category filter
        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }
        
        // Apply type filter
        if let type = selectedType {
            items = items.filter { $0.type == type }
        }
        
        // Apply search filter if no search results
        if !searchText.isEmpty && searchResults.isEmpty {
            items = items.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.content.localizedCaseInsensitiveContains(searchText) ||
                item.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return items.sorted { $0.updatedAt > $1.updatedAt }
    }
}

// MARK: - Subviews

struct SearchBar: View {
    @Binding var text: String
    let onSearch: () -> Void
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索知识库...", text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        onSearch()
                    }
                
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

struct FilterTabs: View {
    @Binding var selectedCategory: KnowledgeBaseManager.KnowledgeCategory?
    @Binding var selectedType: KnowledgeBaseManager.KnowledgeType?
    let onFilterChange: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Category Filter
                Menu {
                    ForEach(KnowledgeBaseManager.KnowledgeCategory.allCases, id: \.self) { category in
                        Button(category.displayName) {
                            selectedCategory = category
                            onFilterChange()
                        }
                    }
                    Button("所有类别") {
                        selectedCategory = nil
                        onFilterChange()
                    }
                } label: {
                    HStack {
                        Image(systemName: selectedCategory?.icon ?? "folder")
                        Text(selectedCategory?.displayName ?? "类别")
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedCategory != nil ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(6)
                }
                
                // Type Filter
                Menu {
                    ForEach(KnowledgeBaseManager.KnowledgeType.allCases, id: \.self) { type in
                        Button(type.displayName) {
                            selectedType = type
                            onFilterChange()
                        }
                    }
                    Button("所有类型") {
                        selectedType = nil
                        onFilterChange()
                    }
                } label: {
                    HStack {
                        Image(systemName: "doc")
                        Text(selectedType?.displayName ?? "类型")
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedType != nil ? Color.green.opacity(0.2) : Color.clear)
                    .cornerRadius(6)
                }
                
                // Clear Filters
                if selectedCategory != nil || selectedType != nil {
                    Button("清除筛选") {
                        selectedCategory = nil
                        selectedType = nil
                        onFilterChange()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(6)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ItemsView: View {
    let items: [KnowledgeBaseManager.KnowledgeItem]
    let searchResults: [KnowledgeBaseManager.SearchResult]
    let isSearching: Bool
    let onRefresh: () -> Void
    let onAddItem: () -> Void
    
    var body: some View {
        VStack {
            if isSearching {
                ProgressView()
                    .scaleEffect(0.8)
            } else if !searchResults.isEmpty {
                SearchResultsView(results: searchResults)
            } else if !items.isEmpty {
                KnowledgeItemsList(items: items)
            } else {
                EmptyStateView(
                    title: "暂无知识条目",
                    subtitle: "开始添加您的第一个知识条目",
                    action: onAddItem
                )
            }
        }
    }
}

struct CollectionsView: View {
    let collections: [KnowledgeBaseManager.KnowledgeCollection]
    let onRefresh: () -> Void
    let onAddCollection: () -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(collections.indices, id: \.self) { index in
                    CollectionCard(collection: collections[index])
                }
            }
            .padding()
        }
    }
}

struct StatsView: View {
    let stats: KnowledgeBaseManager.KnowledgeStats?
    let onRefresh: () -> Void
    
    var body: some View {
        ScrollView {
            if let stats = stats {
                LazyVStack(spacing: 20) {
                    OverviewStatsCard(stats: stats)
                    CategoryStatsCard(stats: stats)
                    TypeStatsCard(stats: stats)
                    TagStatsCard(stats: stats)
                }
                .padding()
            } else {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
    }
}

struct TagsView: View {
    let items: [KnowledgeBaseManager.KnowledgeItem]
    let onRefresh: () -> Void
    
    private var allTags: [String] {
        let tags = items.flatMap { $0.tags }
        return Array(Set(tags)).sorted()
    }
    
    private var tagCounts: [String: Int] {
        Dictionary(grouping: items.flatMap { $0.tags }, by: { $0 })
            .mapValues { $0.count }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(allTags, id: \.self) { tag in
                    TagCard(tag: tag, count: tagCounts[tag] ?? 0)
                }
            }
            .padding()
        }
    }
}

#Preview {
    KnowledgeBaseManagementView()
}