import Foundation
import CoreData
import Combine

// MARK: - Template Manager

public class TemplateManager: ObservableObject {
    static let shared = TemplateManager()
    
    // MARK: - Initialization
    
    public func loadTemplates() {
        // Load templates from storage
        isProcessing = true
        
        templateQueue.async {
            let loadedTemplates = self.loadTemplatesFromCoreData()
            
            DispatchQueue.main.async {
                self.templates = loadedTemplates
                self.isProcessing = false
            }
        }
        print("Template manager loaded templates")
    }
    
    // MARK: - Properties
    
    @Published var templates: [Template] = []
    @Published var categories: [TemplateCategory] = []
    @Published var isProcessing = false
    @Published var searchQuery = ""
    
    private let context = CoreDataManager.shared.context
    private let templateQueue = DispatchQueue(label: "com.flowkey.templates", qos: .userInitiated)
    
    // MARK: - Template Types
    
    public enum TemplateType: String, CaseIterable, Codable {
        case document = "document"
        case email = "email"
        case message = "message"
        case report = "report"
        case meeting = "meeting"
        case presentation = "presentation"
        case code = "code"
        case note = "note"
        case custom = "custom"
        
        var displayName: String {
            switch self {
            case .document: return "文档"
            case .email: return "邮件"
            case .message: return "消息"
            case .report: return "报告"
            case .meeting: return "会议"
            case .presentation: return "演示文稿"
            case .code: return "代码"
            case .note: return "笔记"
            case .custom: return "自定义"
            }
        }
        
        var icon: String {
            switch self {
            case .document: return "doc.text"
            case .email: return "envelope"
            case .message: return "message"
            case .report: return "chart.bar"
            case .meeting: return "calendar"
            case .presentation: return "display"
            case .code: return "chevron.left.forwardslash.chevron.right"
            case .note: return "note.text"
            case .custom: return "doc.richtext"
            }
        }
        
        var defaultVariables: [TemplateVariable] {
            switch self {
            case .email:
                return [
                    TemplateVariable(name: "recipient", displayName: "收件人", type: .text, required: true),
                    TemplateVariable(name: "subject", displayName: "主题", type: .text, required: true),
                    TemplateVariable(name: "greeting", displayName: "问候语", type: .text, defaultValue: "您好"),
                    TemplateVariable(name: "sender", displayName: "发件人", type: .text, required: true),
                    TemplateVariable(name: "signature", displayName: "签名", type: .text)
                ]
            case .meeting:
                return [
                    TemplateVariable(name: "meeting_title", displayName: "会议标题", type: .text, required: true),
                    TemplateVariable(name: "date", displayName: "日期", type: .date, required: true),
                    TemplateVariable(name: "time", displayName: "时间", type: .time, required: true),
                    TemplateVariable(name: "location", displayName: "地点", type: .text, required: true),
                    TemplateVariable(name: "attendees", displayName: "参会人员", type: .text, required: true),
                    TemplateVariable(name: "agenda", displayName: "议程", type: .text)
                ]
            case .document:
                return [
                    TemplateVariable(name: "title", displayName: "标题", type: .text, required: true),
                    TemplateVariable(name: "author", displayName: "作者", type: .text, required: true),
                    TemplateVariable(name: "date", displayName: "日期", type: .date, required: true),
                    TemplateVariable(name: "version", displayName: "版本", type: .text, defaultValue: "1.0"),
                    TemplateVariable(name: "description", displayName: "描述", type: .text)
                ]
            default:
                return []
            }
        }
    }
    
    public enum VariableType: String, CaseIterable, Codable {
        case text = "text"
        case number = "number"
        case date = "date"
        case time = "time"
        case datetime = "datetime"
        case boolean = "boolean"
        case select = "select"
        case multiselect = "multiselect"
        
        var displayName: String {
            switch self {
            case .text: return "文本"
            case .number: return "数字"
            case .date: return "日期"
            case .time: return "时间"
            case .datetime: return "日期时间"
            case .boolean: return "布尔值"
            case .select: return "单选"
            case .multiselect: return "多选"
            }
        }
    }
    
    // MARK: - Data Structures
    
    public struct Template: Identifiable, Codable, Equatable {
        public let id: UUID
        public var name: String
        public var type: TemplateType
        public var content: String
        public var variables: [TemplateVariable]
        public var category: TemplateCategory
        public var tags: [String]
        public var isFavorite: Bool
        public var usageCount: Int
        public var lastUsed: Date?
        public var createdAt: Date
        public var updatedAt: Date
        
        public init(
            id: UUID = UUID(),
            name: String,
            type: TemplateType,
            content: String,
            variables: [TemplateVariable] = [],
            category: TemplateCategory = .general,
            tags: [String] = [],
            isFavorite: Bool = false,
            usageCount: Int = 0,
            lastUsed: Date? = nil,
            createdAt: Date = Date(),
            updatedAt: Date = Date()
        ) {
            self.id = id
            self.name = name
            self.type = type
            self.content = content
            self.variables = variables
            self.category = category
            self.tags = tags
            self.isFavorite = isFavorite
            self.usageCount = usageCount
            self.lastUsed = lastUsed
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }
    
    public struct TemplateVariable: Identifiable, Codable, Equatable {
        public let id: UUID
        public var name: String
        public var displayName: String
        public var type: VariableType
        public var required: Bool
        public var defaultValue: String?
        public var options: [String]?
        public var validation: ValidationRule?
        public var description: String?
        
        public init(
            id: UUID = UUID(),
            name: String,
            displayName: String,
            type: VariableType,
            required: Bool = false,
            defaultValue: String? = nil,
            options: [String]? = nil,
            validation: ValidationRule? = nil,
            description: String? = nil
        ) {
            self.id = id
            self.name = name
            self.displayName = displayName
            self.type = type
            self.required = required
            self.defaultValue = defaultValue
            self.options = options
            self.validation = validation
            self.description = description
        }
    }
    
    public struct ValidationRule: Codable, Equatable {
        public var type: ValidationType
        public var parameters: [String: String]
        
        public init(type: ValidationType, parameters: [String: String] = [:]) {
            self.type = type
            self.parameters = parameters
        }
    }
    
    public enum ValidationType: String, CaseIterable, Codable {
        case minLength = "min_length"
        case maxLength = "max_length"
        case pattern = "pattern"
        case range = "range"
        case required = "required"
        
        var displayName: String {
            switch self {
            case .minLength: return "最小长度"
            case .maxLength: return "最大长度"
            case .pattern: return "正则表达式"
            case .range: return "数值范围"
            case .required: return "必填"
            }
        }
    }
    
    public enum TemplateCategory: String, CaseIterable, Codable {
        case general = "general"
        case business = "business"
        case personal = "personal"
        case technical = "technical"
        case creative = "creative"
        case academic = "academic"
        
        var displayName: String {
            switch self {
            case .general: return "通用"
            case .business: return "商务"
            case .personal: return "个人"
            case .technical: return "技术"
            case .creative: return "创意"
            case .academic: return "学术"
            }
        }
        
        var icon: String {
            switch self {
            case .general: return "folder"
            case .business: return "briefcase"
            case .personal: return "person"
            case .technical: return "wrench.and.screwdriver"
            case .creative: return "paintbrush"
            case .academic: return "graduationcap"
            }
        }
        
        var color: String {
            switch self {
            case .general: return "blue"
            case .business: return "green"
            case .personal: return "orange"
            case .technical: return "purple"
            case .creative: return "pink"
            case .academic: return "red"
            }
        }
    }
    
    public struct TemplateInstance: Identifiable, Codable {
        public let id: UUID
        public let templateId: UUID
        public var variables: [String: String]
        public var renderedContent: String
        public var createdAt: Date
        
        public init(
            id: UUID = UUID(),
            templateId: UUID,
            variables: [String: String],
            renderedContent: String,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.templateId = templateId
            self.variables = variables
            self.renderedContent = renderedContent
            self.createdAt = createdAt
        }
    }
    
    // MARK: - Error Types
    
    public enum TemplateError: Error, LocalizedError {
        case templateNotFound
        case invalidVariable(String)
        case validationFailed(String)
        case renderingFailed(String)
        
        public var errorDescription: String? {
            switch self {
            case .templateNotFound:
                return "模板未找到"
            case .invalidVariable(let message):
                return "无效变量: \(message)"
            case .validationFailed(let message):
                return "验证失败: \(message)"
            case .renderingFailed(let message):
                return "渲染失败: \(message)"
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        setupCategories()
        loadTemplates()
        createDefaultTemplatesIfNeeded()
    }
    
    // MARK: - Public Methods
    
    public func addTemplate(_ template: Template) async throws {
        try await withCheckedContinuation { continuation in
            templateQueue.async {
                do {
                    let newTemplate = Template(
                        id: UUID(),
                        name: template.name,
                        type: template.type,
                        content: template.content,
                        variables: template.variables,
                        category: template.category,
                        tags: template.tags,
                        isFavorite: template.isFavorite,
                        usageCount: 0,
                        lastUsed: nil,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    
                    try self.saveTemplateToCoreData(newTemplate)
                    self.loadTemplatesFromCoreData()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func updateTemplate(_ template: Template) async throws {
        try await withCheckedContinuation { continuation in
            templateQueue.async {
                do {
                    var updatedTemplate = template
                    updatedTemplate.updatedAt = Date()
                    
                    try self.updateTemplateInCoreData(updatedTemplate)
                    self.loadTemplatesFromCoreData()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func deleteTemplate(_ id: UUID) async throws {
        try await withCheckedContinuation { continuation in
            templateQueue.async {
                do {
                    try self.deleteTemplateFromCoreData(id)
                    self.loadTemplatesFromCoreData()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func useTemplate(_ id: UUID) async throws -> TemplateInstance {
        return try await withCheckedContinuation { continuation in
            templateQueue.async {
                do {
                    guard let template = self.templates.first(where: { $0.id == id }) else {
                        throw TemplateError.templateNotFound
                    }
                    
                    // Update usage count
                    var updatedTemplate = template
                    updatedTemplate.usageCount += 1
                    updatedTemplate.lastUsed = Date()
                    
                    try self.updateTemplateInCoreData(updatedTemplate)
                    self.loadTemplatesFromCoreData()
                    
                    // Create template instance with default values
                    let variables = self.getDefaultVariables(for: template)
                    let renderedContent = try self.renderTemplate(template, variables: variables)
                    
                    let instance = TemplateInstance(
                        templateId: template.id,
                        variables: variables,
                        renderedContent: renderedContent,
                        createdAt: Date()
                    )
                    
                    continuation.resume(returning: instance)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func renderTemplate(_ template: Template, variables: [String: String]) throws -> String {
        // Validate variables
        try validateVariables(template: template, variables: variables)
        
        // Render template
        var renderedContent = template.content
        
        // Replace variables
        for variable in template.variables {
            let placeholder = "{{\(variable.name)}}"
            let value = variables[variable.name] ?? variable.defaultValue ?? ""
            renderedContent = renderedContent.replacingOccurrences(of: placeholder, with: value)
        }
        
        // Replace system variables
        let systemVariables = getSystemVariables()
        for (key, value) in systemVariables {
            let placeholder = "{{\(key)}}"
            renderedContent = renderedContent.replacingOccurrences(of: placeholder, with: value)
        }
        
        return renderedContent
    }
    
    public func searchTemplates(_ query: String) -> [Template] {
        let lowercaseQuery = query.lowercased()
        
        return templates.filter { template in
            template.name.lowercased().contains(lowercaseQuery) ||
            template.content.lowercased().contains(lowercaseQuery) ||
            template.tags.contains { $0.lowercased().contains(lowercaseQuery) }
        }
    }
    
    public func getTemplatesByCategory(_ category: TemplateCategory) -> [Template] {
        return templates.filter { $0.category == category }
    }
    
    public func getTemplatesByType(_ type: TemplateType) -> [Template] {
        return templates.filter { $0.type == type }
    }
    
    public func getFavoriteTemplates() -> [Template] {
        return templates.filter { $0.isFavorite }
    }
    
    public func getRecentTemplates() -> [Template] {
        let recentTemplates = templates.filter { $0.lastUsed != nil }
        return recentTemplates.sorted {
            guard let date1 = $0.lastUsed, let date2 = $1.lastUsed else { return false }
            return date1 > date2
        }
    }
    
    public func exportTemplates(_ templateIds: [UUID]) throws -> Data {
        let templatesToExport = templates.filter { templateIds.contains($0.id) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(templatesToExport)
    }
    
    public func importTemplates(from data: Data) throws -> [Template] {
        let decoder = JSONDecoder()
        let importedTemplates = try decoder.decode([Template].self, from: data)
        
        // Add imported templates
        for template in importedTemplates {
            let newTemplate = Template(
                id: UUID(), // Generate new ID
                name: template.name,
                type: template.type,
                content: template.content,
                variables: template.variables,
                category: template.category,
                tags: template.tags,
                isFavorite: template.isFavorite,
                usageCount: 0,
                lastUsed: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try await addTemplate(newTemplate)
        }
        
        return importedTemplates
    }
    
    // MARK: - Private Methods
    
    private func setupCategories() {
        categories = TemplateCategory.allCases
    }
    
    private func createDefaultTemplatesIfNeeded() {
        if templates.isEmpty {
            createDefaultTemplates()
        }
    }
    
    private func createDefaultTemplates() {
        let defaultTemplates = [
            // Email template
            Template(
                name: "商务邮件",
                type: .email,
                content: """
                亲爱的{{recipient}}：
                
                {{greeting}}，
                
                {{content}}
                
                如有任何问题，请随时与我联系。
                
                此致
                敬礼
                
                {{sender}}
                {{signature}}
                """,
                variables: TemplateType.email.defaultVariables,
                category: .business,
                tags: ["邮件", "商务", "正式"]
            ),
            
            // Meeting template
            Template(
                name: "会议纪要",
                type: .meeting,
                content: """
                # {{meeting_title}}
                
                **日期**: {{date}}
                **时间**: {{time}}
                **地点**: {{location}}
                **参会人员**: {{attendees}}
                
                ## 议程
                {{agenda}}
                
                ## 会议纪要
                {{meeting_notes}}
                
                ## 行动项目
                {{action_items}}
                
                ## 下次会议
                {{next_meeting}}
                """,
                variables: TemplateType.meeting.defaultVariables + [
                    TemplateVariable(name: "meeting_notes", displayName: "会议纪要", type: .text),
                    TemplateVariable(name: "action_items", displayName: "行动项目", type: .text),
                    TemplateVariable(name: "next_meeting", displayName: "下次会议", type: .text)
                ],
                category: .business,
                tags: ["会议", "纪要", "商务"]
            ),
            
            // Document template
            Template(
                name: "技术文档",
                type: .document,
                content: """
                # {{title}}
                
                **作者**: {{author}}
                **版本**: {{version}}
                **日期**: {{date}}
                
                ## 概述
                {{overview}}
                
                ## 目录
                {{table_of_contents}}
                
                ## 正文
                {{content}}
                
                ## 附录
                {{appendix}}
                """,
                variables: TemplateType.document.defaultVariables + [
                    TemplateVariable(name: "overview", displayName: "概述", type: .text),
                    TemplateVariable(name: "table_of_contents", displayName: "目录", type: .text),
                    TemplateVariable(name: "content", displayName: "正文", type: .text),
                    TemplateVariable(name: "appendix", displayName: "附录", type: .text)
                ],
                category: .technical,
                tags: ["文档", "技术", "正式"]
            ),
            
            // Message template
            Template(
                name: "即时消息",
                type: .message,
                content: """
                {{greeting}}，{{recipient_name}}
                
                {{message_content}}
                
                {{closing}}
                {{sender_name}}
                """,
                variables: [
                    TemplateVariable(name: "greeting", displayName: "问候语", type: .text, defaultValue: "Hi"),
                    TemplateVariable(name: "recipient_name", displayName: "收件人姓名", type: .text, required: true),
                    TemplateVariable(name: "message_content", displayName: "消息内容", type: .text, required: true),
                    TemplateVariable(name: "closing", displayName: "结束语", type: .text, defaultValue: "Best regards"),
                    TemplateVariable(name: "sender_name", displayName: "发件人姓名", type: .text, required: true)
                ],
                category: .personal,
                tags: ["消息", "即时", "个人"]
            )
        ]
        
        // Save default templates
        for template in defaultTemplates {
            try? saveTemplateToCoreData(template)
        }
        
        loadTemplates()
    }
    
    private func getDefaultVariables(for template: Template) -> [String: String] {
        var variables: [String: String] = [:]
        
        for variable in template.variables {
            variables[variable.name] = variable.defaultValue ?? ""
        }
        
        return variables
    }
    
    private func validateVariables(template: Template, variables: [String: String]) throws {
        // Check required variables
        for variable in template.variables {
            if variable.required && (variables[variable.name]?.isEmpty ?? true) {
                throw TemplateError.validationFailed("必填变量 '\(variable.displayName)' 未提供")
            }
        }
        
        // Validate variable types and rules
        for (name, value) in variables {
            guard let variable = template.variables.first(where: { $0.name == name }) else { continue }
            
            // Apply validation rules
            if let validation = variable.validation {
                try applyValidation(value: value, rule: validation, variable: variable)
            }
        }
    }
    
    private func applyValidation(value: String, rule: ValidationRule, variable: TemplateVariable) throws {
        switch rule.type {
        case .minLength:
            if let minLength = rule.parameters["min_length"], value.count < Int(minLength) ?? 0 {
                throw TemplateError.validationFailed("'\(variable.displayName)' 长度不能少于 \(minLength) 个字符")
            }
        case .maxLength:
            if let maxLength = rule.parameters["max_length"], value.count > Int(maxLength) ?? Int.max {
                throw TemplateError.validationFailed("'\(variable.displayName)' 长度不能超过 \(maxLength) 个字符")
            }
        case .pattern:
            if let pattern = rule.parameters["pattern"] {
                let regex = try NSRegularExpression(pattern: pattern)
                let range = NSRange(location: 0, length: value.utf16.count)
                if regex.firstMatch(in: value, options: [], range: range) == nil {
                    throw TemplateError.validationFailed("'\(variable.displayName)' 格式不正确")
                }
            }
        case .range:
            if let minValue = rule.parameters["min"], let maxValue = rule.parameters["max"],
               let valueNum = Double(value), valueNum < Double(minValue) ?? 0 || valueNum > Double(maxValue) ?? Double.greatestFiniteMagnitude {
                throw TemplateError.validationFailed("'\(variable.displayName)' 必须在 \(minValue) 和 \(maxValue) 之间")
            }
        case .required:
            if value.isEmpty {
                throw TemplateError.validationFailed("'\(variable.displayName)' 是必填项")
            }
        }
    }
    
    private func getSystemVariables() -> [String: String] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .medium
        
        return [
            "date": formatter.string(from: Date()),
            "time": timeFormatter.string(from: Date()),
            "datetime": ISO8601DateFormatter().string(from: Date()),
            "year": String(Calendar.current.component(.year, from: Date())),
            "month": String(Calendar.current.component(.month, from: Date())),
            "day": String(Calendar.current.component(.day, from: Date())),
            "user_name": NSFullUserName() ?? "用户"
        ]
    }
    
    // MARK: - Core Data Operations
    
    private func loadTemplatesFromCoreData() -> [Template] {
        let request: NSFetchRequest<TemplateEntity> = TemplateEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let entities = try context.fetch(request)
            return entities.map { entity in
                Template(
                    id: entity.id ?? UUID(),
                    name: entity.name ?? "",
                    type: TemplateType(rawValue: entity.type ?? "") ?? .custom,
                    content: entity.content ?? "",
                    variables: (entity.variables as? [[String: Any]] ?? []).map { dict in
                        TemplateVariable(
                            name: dict["name"] as? String ?? "",
                            displayName: dict["displayName"] as? String ?? "",
                            type: VariableType(rawValue: dict["type"] as? String ?? "") ?? .text,
                            required: dict["required"] as? Bool ?? false,
                            defaultValue: dict["defaultValue"] as? String,
                            options: dict["options"] as? [String],
                            validation: (dict["validation"] as? [String: String]).flatMap { validationDict in
                            ValidationRule(
                                type: ValidationType(rawValue: validationDict["type"] as? String ?? "") ?? .required,
                                parameters: validationDict
                            )
                        },
                            description: dict["description"] as? String
                        )
                    },
                    category: TemplateCategory(rawValue: entity.category ?? "") ?? .general,
                    tags: entity.tags as? [String] ?? [],
                    isFavorite: entity.isFavorite,
                    usageCount: Int(entity.usageCount),
                    lastUsed: entity.lastUsed,
                    createdAt: entity.createdAt ?? Date(),
                    updatedAt: entity.updatedAt ?? Date()
                )
            }
        } catch {
            print("Error loading templates: \(error)")
            return []
        }
    }
    
    private func saveTemplateToCoreData(_ template: Template) throws {
        let entity = TemplateEntity(context: context)
        entity.id = template.id
        entity.name = template.name
        entity.type = template.type.rawValue
        entity.content = template.content
        entity.variables = template.variables.map { variable in
            var dict: [String: Any] = [
                "name": variable.name,
                "displayName": variable.displayName,
                "type": variable.type.rawValue,
                "required": variable.required
            ]
            
            if let defaultValue = variable.defaultValue {
                dict["defaultValue"] = defaultValue
            }
            if let options = variable.options {
                dict["options"] = options
            }
            if let validation = variable.validation {
                dict["validation"] = [
                    "type": validation.type.rawValue,
                    "parameters": validation.parameters
                ]
            }
            if let description = variable.description {
                dict["description"] = description
            }
            
            return dict
        } as NSObject
        entity.category = template.category.rawValue
        entity.tags = template.tags as NSObject
        entity.isFavorite = template.isFavorite
        entity.usageCount = Int16(template.usageCount)
        entity.lastUsed = template.lastUsed
        entity.createdAt = template.createdAt
        entity.updatedAt = template.updatedAt
        
        try context.save()
    }
    
    private func updateTemplateInCoreData(_ template: Template) throws {
        let fetchRequest: NSFetchRequest<TemplateEntity> = TemplateEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", template.id as CVarArg)
        
        let entities = try context.fetch(fetchRequest)
        guard let entity = entities.first else {
            throw TemplateError.templateNotFound
        }
        
        entity.name = template.name
        entity.type = template.type.rawValue
        entity.content = template.content
        entity.variables = template.variables.map { variable in
            var dict: [String: Any] = [
                "name": variable.name,
                "displayName": variable.displayName,
                "type": variable.type.rawValue,
                "required": variable.required
            ]
            
            if let defaultValue = variable.defaultValue {
                dict["defaultValue"] = defaultValue
            }
            if let options = variable.options {
                dict["options"] = options
            }
            if let validation = variable.validation {
                dict["validation"] = [
                    "type": validation.type.rawValue,
                    "parameters": validation.parameters
                ]
            }
            if let description = variable.description {
                dict["description"] = description
            }
            
            return dict
        } as NSObject
        entity.category = template.category.rawValue
        entity.tags = template.tags as NSObject
        entity.isFavorite = template.isFavorite
        entity.usageCount = Int16(template.usageCount)
        entity.lastUsed = template.lastUsed
        entity.updatedAt = template.updatedAt
        
        try context.save()
    }
    
    private func deleteTemplateFromCoreData(_ id: UUID) throws {
        let fetchRequest: NSFetchRequest<TemplateEntity> = TemplateEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        let entities = try context.fetch(fetchRequest)
        guard let entity = entities.first else {
            throw TemplateError.templateNotFound
        }
        
        context.delete(entity)
        try context.save()
    }
}