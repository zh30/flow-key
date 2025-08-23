import SwiftUI

// MARK: - Shared UI Components

struct EmptyStateView: View {
    let title: String
    let description: String?
    let systemImage: String?
    let action: (() -> Void)?
    
    init(title: String, description: String? = nil, systemImage: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if let systemImage = systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            if let description = description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let action = action {
                Button(action: action) {
                    Text("添加")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TagsView: View {
    let tags: [String]
    let onTagTap: ((String) -> Void)?
    let onAddTag: (() -> Void)?
    
    init(tags: [String], onTagTap: ((String) -> Void)? = nil, onAddTag: (() -> Void)? = nil) {
        self.tags = tags
        self.onTagTap = onTagTap
        self.onAddTag = onAddTag
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    TagChip(tag: tag, onTap: { onTagTap?(tag) })
                }
                
                if let onAddTag = onAddTag {
                    Button(action: onAddTag) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
}

struct TagChip: View {
    let tag: String
    let onTap: (() -> Void)?
    
    init(tag: String, onTap: (() -> Void)? = nil) {
        self.tag = tag
        self.onTap = onTap
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
                .foregroundColor(.primary)
            
            if onTap != nil {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
        .onTapGesture {
            onTap?()
        }
    }
}