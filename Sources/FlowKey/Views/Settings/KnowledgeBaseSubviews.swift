import SwiftUI

// MARK: - Search Results View

struct SearchResultsView: View {
    let results: [KnowledgeBaseManager.SearchResult]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(results.indices, id: \.self) { index in
                    SearchResultCard(result: results[index])
                }
            }
            .padding()
        }
    }
}

struct SearchResultCard: View {
    let result: KnowledgeBaseManager.SearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.item.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                ScoreBadge(score: result.score)
            }
            
            HStack {
                CategoryBadge(category: result.item.category)
                TypeBadge(type: result.item.type)
                
                Spacer()
                
                Text(result.item.updatedAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !result.snippet.isEmpty {
                Text(result.snippet)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            if !result.matchedTerms.isEmpty {
                HStack {
                    Text("匹配:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(result.matchedTerms, id: \.self) { term in
                        Text(term)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            
            if !result.item.tags.isEmpty {
                TagsView(tags: result.item.tags)
            }
            
            HStack {
                if result.item.isStarred {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
                
                if result.item.isArchived {
                    Image(systemName: "archivebox")
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("\(result.item.content.count) 字符")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Knowledge Items List

struct KnowledgeItemsList: View {
    let items: [KnowledgeBaseManager.KnowledgeItem]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(items.indices, id: \.self) { index in
                    KnowledgeItemCard(item: items[index])
                }
            }
            .padding()
        }
    }
}

struct KnowledgeItemCard: View {
    let item: KnowledgeBaseManager.KnowledgeItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
                
                if item.isStarred {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
                
                if item.isArchived {
                    Image(systemName: "archivebox")
                        .foregroundColor(.gray)
                }
            }
            
            HStack {
                CategoryBadge(category: item.category)
                TypeBadge(type: item.type)
                
                Spacer()
                
                Text(item.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(item.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(4)
            
            if !item.tags.isEmpty {
                TagsView(tags: item.tags)
            }
            
            HStack {
                if let fileSize = item.fileSize {
                    Text(ByteCountFormatter.string(fromByteCount: fileSize))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("ID: \(item.id.prefix(8))...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Collection Card

struct CollectionCard: View {
    let collection: KnowledgeBaseManager.KnowledgeCollection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(collection.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                if collection.isPublic {
                    Image(systemName: "globe")
                        .foregroundColor(.blue)
                }
            }
            
            if let description = collection.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                if let category = collection.category {
                    CategoryBadge(category: category)
                }
                
                Text("\(collection.items.count) 个条目")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(collection.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !collection.tags.isEmpty {
                TagsView(tags: collection.tags)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Stats Cards

struct OverviewStatsCard: View {
    let stats: KnowledgeBaseManager.KnowledgeStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("概览")
                .font(.headline)
            
            HStack {
                StatCard(title: "总条目", value: "\(stats.totalItems)", color: .blue)
                StatCard(title: "已收藏", value: "\(stats.starredItems)", color: .yellow)
                StatCard(title: "已归档", value: "\(stats.archivedItems)", color: .gray)
                StatCard(title: "最近", value: "\(stats.recentItems)", color: .green)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct CategoryStatsCard: View {
    let stats: KnowledgeBaseManager.KnowledgeStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("按类别分布")
                .font(.headline)
            
            ForEach(KnowledgeBaseManager.KnowledgeCategory.allCases, id: \.self) { category in
                HStack {
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(.blue)
                        Text(category.displayName)
                    }
                    
                    Spacer()
                    
                    Text("\(stats.itemsByCategory[category] ?? 0)")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct TypeStatsCard: View {
    let stats: KnowledgeBaseManager.KnowledgeStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("按类型分布")
                .font(.headline)
            
            ForEach(KnowledgeBaseManager.KnowledgeType.allCases, id: \.self) { type in
                HStack {
                    Text(type.displayName)
                    
                    Spacer()
                    
                    Text("\(stats.itemsByType[type] ?? 0)")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct TagStatsCard: View {
    let stats: KnowledgeBaseManager.KnowledgeStats
    
    private var sortedTags: [(String, Int)] {
        stats.tags.sorted { $0.value > $1.value }.prefix(10)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("热门标签")
                .font(.headline)
            
            ForEach(sortedTags, id: \.0) { tag, count in
                HStack {
                    Text(tag)
                    
                    Spacer()
                    
                    Text("\(count)")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Utility Views

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}

struct ScoreBadge: View {
    let score: Double
    
    var body: some View {
        Text(String(format: "%.1f%%", score * 100))
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(scoreColor)
            .foregroundColor(.white)
            .cornerRadius(12)
    }
    
    private var scoreColor: Color {
        switch score {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .yellow
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

struct CategoryBadge: View {
    let category: KnowledgeBaseManager.KnowledgeCategory
    
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

struct TypeBadge: View {
    let type: KnowledgeBaseManager.KnowledgeType
    
    var body: some View {
        Text(type.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.purple.opacity(0.2))
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

struct TagCard: View {
    let tag: String
    let count: Int
    
    var body: some View {
        VStack {
            Text(tag)
                .font(.body)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("添加第一个条目") {
                action()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Formatters

extension ByteCountFormatter {
    static func string(fromByteCount byteCount: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: byteCount)
    }
}