import Foundation
import UniformTypeIdentifiers

public class DocumentProcessor {
    public static let shared = DocumentProcessor()
    
    private init() {}
    
    // MARK: - Document Processing
    
    public func processDocument(at url: URL) async throws -> ProcessedDocument {
        guard url.startAccessingSecurityScopedResource() else {
            throw DocumentError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let type = try determineDocumentType(url)
        let content = try extractContent(from: url, type: type)
        let metadata = try extractMetadata(from: url, type: type)
        
        let processedDocument = ProcessedDocument(
            id: UUID().uuidString,
            title: extractTitle(from: url, metadata: metadata),
            content: content,
            type: type,
            url: url,
            metadata: metadata,
            processedAt: Date()
        )
        
        return processedDocument
    }
    
    // MARK: - Document Type Detection
    
    private func determineDocumentType(_ url: URL) throws -> DocumentType {
        guard let resourceValues = try? url.resourceValues(forKeys: [.typeIdentifierKey]),
              let typeIdentifier = resourceValues.typeIdentifier else {
            throw DocumentError.unknownType
        }
        
        if typeIdentifier == UTType.plainText.identifier || typeIdentifier == UTType.text.identifier {
            return .text
        } else if typeIdentifier == "net.daringfireball.markdown" || url.pathExtension.lowercased() == "md" {
            return .markdown
        } else if typeIdentifier == UTType.pdf.identifier {
            return .pdf
        } else if typeIdentifier == UTType.data.identifier && url.pathExtension.lowercased() == "pdf" {
            return .pdf
        } else if typeIdentifier.contains("word") || url.pathExtension.lowercased() == "docx" {
            return .docx
        } else if typeIdentifier == UTType.rtf.identifier {
            return .rtf
        } else if typeIdentifier == UTType.html.identifier || typeIdentifier == UTType.webArchive.identifier {
            return .html
        } else if typeIdentifier.contains("sourcecode") || isCodeFile(url) {
            return .code
        } else {
            return .text // Default to text
        }
    }
    
    private func isCodeFile(_ url: URL) -> Bool {
        let codeExtensions = ["swift", "py", "js", "ts", "java", "cpp", "c", "h", "cs", "php", "rb", "go", "rs", "kt", "scala", "sh", "sql", "json", "xml", "yaml", "yml"]
        return codeExtensions.contains(url.pathExtension.lowercased())
    }
    
    // MARK: - Content Extraction
    
    private func extractContent(from url: URL, type: DocumentType) throws -> String {
        switch type {
        case .text, .markdown, .code:
            return try String(contentsOf: url)
        case .pdf:
            return try extractPDFContent(from: url)
        case .docx:
            return try extractDocxContent(from: url)
        case .rtf:
            return try extractRTFContent(from: url)
        case .html:
            return try extractHTMLContent(from: url)
        }
    }
    
    private func extractPDFContent(from url: URL) throws -> String {
        // In production, this would use PDFKit or a PDF parsing library
        // For now, return mock content
        return "PDF content from \(url.lastPathComponent)\n\nThis is a placeholder for PDF text extraction. In production, this would use PDFKit to extract text from PDF files."
    }
    
    private func extractDocxContent(from url: URL) throws -> String {
        // In production, this would use a DOCX parsing library
        // For now, return mock content
        return "DOCX content from \(url.lastPathComponent)\n\nThis is a placeholder for DOCX text extraction. In production, this would parse the DOCX XML structure."
    }
    
    private func extractRTFContent(from url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        let attributedString = try NSAttributedString(data: data, options: [:], documentAttributes: nil)
        return attributedString.string
    }
    
    private func extractHTMLContent(from url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        let attributedString = try NSAttributedString(data: data, options: options, documentAttributes: nil)
        return attributedString.string
    }
    
    // MARK: - Metadata Extraction
    
    private func extractMetadata(from url: URL, type: DocumentType) throws -> [String: String] {
        var metadata: [String: String] = [:]
        
        // Basic file metadata
        if let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey, .contentModificationDateKey]) {
            if let fileSize = resourceValues.fileSize {
                metadata["fileSize"] = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
            }
            if let creationDate = resourceValues.creationDate {
                metadata["creationDate"] = ISO8601DateFormatter().string(from: creationDate)
            }
            if let modificationDate = resourceValues.contentModificationDate {
                metadata["modificationDate"] = ISO8601DateFormatter().string(from: modificationDate)
            }
        }
        
        // Type-specific metadata
        switch type {
        case .code:
            metadata["language"] = url.pathExtension.lowercased()
        case .pdf:
            // In production, extract PDF-specific metadata
            metadata["type"] = "PDF"
        case .docx:
            // In production, extract DOCX-specific metadata
            metadata["type"] = "DOCX"
        default:
            break
        }
        
        return metadata
    }
    
    // MARK: - Title Extraction
    
    private func extractTitle(from url: URL, metadata: [String: String]) -> String {
        // Try to get title from filename first
        let filename = url.deletingPathExtension().lastPathComponent
        
        // For certain file types, try to extract title from content
        switch url.pathExtension.lowercased() {
        case "md", "markdown":
            // Try to extract title from first H1 heading
            if let content = try? String(contentsOf: url),
               let firstLine = content.components(separatedBy: .newlines).first,
               firstLine.hasPrefix("# ") {
                return String(firstLine.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            }
        case "html", "htm":
            // In production, extract title from HTML <title> tag
            break
        default:
            break
        }
        
        return filename
    }
    
    // MARK: - Text Processing
    
    public func preprocessText(_ text: String) -> String {
        // Remove extra whitespace
        let cleanedText = text
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common boilerplate text
        let boilerplatePatterns = [
            #"© \d{4}.*All rights reserved"#,
            #"Terms of Service"#,
            #"Privacy Policy"#,
            #"Cookie Policy"#
        ]
        
        var processedText = cleanedText
        for pattern in boilerplatePatterns {
            processedText = processedText.replacingOccurrences(
                of: pattern,
                with: "",
                options: .regularExpression
            )
        }
        
        return processedText
    }
    
    public func extractKeywords(from text: String, limit: Int = 20) -> [String] {
        // Simple keyword extraction
        let words = text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.count > 2 }
        
        // Remove common stop words
        let stopWords = ["the", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "is", "are", "was", "were", "be", "been", "being", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should", "may", "might", "must", "can", "this", "that", "these", "those", "a", "an", "the"]
        
        let filteredWords = words.filter { !stopWords.contains($0) }
        
        // Count word frequencies
        var wordCounts: [String: Int] = [:]
        for word in filteredWords {
            wordCounts[word, default: 0] += 1
        }
        
        // Sort by frequency and return top keywords
        return wordCounts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }
    
    public func generateSummary(from text: String, maxLength: Int = 200) -> String {
        let sentences = text.components(separatedBy: ".")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !sentences.isEmpty else { return text }
        
        // Simple extractive summarization - take first few sentences
        var summary = ""
        for sentence in sentences {
            if summary.count + sentence.count + 1 <= maxLength {
                summary += sentence + ". "
            } else {
                break
            }
        }
        
        return summary.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Processed Document Structure

public struct ProcessedDocument {
    public let id: String
    public let title: String
    public let content: String
    public let type: DocumentType
    public let url: URL
    public let metadata: [String: String]
    public let processedAt: Date
}

public enum DocumentType: String, CaseIterable {
    case text = "text"
    case markdown = "markdown"
    case pdf = "pdf"
    case docx = "docx"
    case rtf = "rtf"
    case html = "html"
    case code = "code"
    
    public var displayName: String {
        switch self {
        case .text: return "Text"
        case .markdown: return "Markdown"
        case .pdf: return "PDF"
        case .docx: return "Word Document"
        case .rtf: return "Rich Text"
        case .html: return "HTML"
        case .code: return "Code"
        }
    }
    
    public var icon: String {
        switch self {
        case .text: return "doc.text"
        case .markdown: return "doc.richtext"
        case .pdf: return "doc.fill"
        case .docx: return "doc.text"
        case .rtf: return "doc.richtext"
        case .html: return "globe"
        case .code: return "chevron.left.forwardslash.chevron.right"
        }
    }
}

// MARK: - Error Types

public enum DocumentError: Error, LocalizedError {
    case accessDenied
    case unknownType
    case contentExtractionFailed
    case fileNotFound
    case invalidFormat
    
    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Access to the file was denied"
        case .unknownType:
            return "Unknown document type"
        case .contentExtractionFailed:
            return "Failed to extract content from document"
        case .fileNotFound:
            return "File not found"
        case .invalidFormat:
            return "Invalid document format"
        }
    }
}