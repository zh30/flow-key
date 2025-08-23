import SwiftUI

// MARK: - Add Template View

struct AddTemplateView: View {
    let onComplete: (TemplateManager.Template) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var selectedType: TemplateManager.TemplateType = .document
    @State private var content = ""
    @State private var selectedCategory: TemplateManager.TemplateCategory = .general
    @State private var tags: String = ""
    @State private var isFavorite = false
    @State private var variables: [TemplateManager.TemplateVariable] = []
    @State private var showVariableEditor = false
    @State private var isAdding = false
    
    private var tagArray: [String] {
        tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("模板名称", text: $name)
                    
                    Picker("模板类型", selection: $selectedType) {
                        ForEach(TemplateManager.TemplateType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                        }
                    }
                    
                    Picker("分类", selection: $selectedCategory) {
                        ForEach(TemplateManager.TemplateCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.displayName)
                            }
                        }
                    }
                }
                
                Section(header: Text("模板内容")) {
                    TextEditor(text: $content)
                        .frame(height: 200)
                    
                    Text("使用 {{变量名}} 作为变量占位符")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("变量管理")) {
                    if variables.isEmpty {
                        Text("暂无变量")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(variables, id: \.id) { variable in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(variable.displayName)
                                        .font(.headline)
                                    
                                    Text("{{\(variable.name)}}")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if variable.required {
                                        Text("必填")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                Spacer()
                                
                                Button("删除") {
                                    variables.removeAll { $0.id == variable.id }
                                }
                        }
                    }
                }
                
                Section {
                    Button("添加变量") {
                        showVariableEditor = true
                    }
                    .buttonStyle(.bordered)
                    
                    if selectedType != .custom {
                        Button("使用默认变量") {
                            variables = selectedType.defaultVariables
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Section(header: Text("标签")) {
                    TextField("标签 (用逗号分隔)", text: $tags)
                    
                    if !tagArray.isEmpty {
                        TagsView(tags: tagArray)
                    }
                }
                
                Section(header: Text("设置")) {
                    Toggle("收藏", isOn: $isFavorite)
                }
                
                Section {
                    Button("添加") {
                        addTemplate()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.isEmpty || content.isEmpty || isAdding)
                    
                    if isAdding {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .navigationTitle("添加模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 800)
        .sheet(isPresented: $showVariableEditor) {
            VariableEditorView { variable in
                variables.append(variable)
                showVariableEditor = false
            }
        }
    }
    
    private func addTemplate() {
        isAdding = true
        
        let template = TemplateManager.Template(
            name: name,
            type: selectedType,
            content: content,
            variables: variables,
            category: selectedCategory,
            tags: tagArray,
            isFavorite: isFavorite
        )
        
        onComplete(template)
        dismiss()
    }
}

// MARK: - Edit Template View

struct EditTemplateView: View {
    let template: TemplateManager.Template
    let onComplete: (TemplateManager.Template) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var selectedType: TemplateManager.TemplateType
    @State private var content: String
    @State private var selectedCategory: TemplateManager.TemplateCategory
    @State private var tags: String
    @State private var isFavorite: Bool
    @State private var variables: [TemplateManager.TemplateVariable]
    @State private var showVariableEditor = false
    @State private var selectedVariable: TemplateManager.TemplateVariable?
    @State private var showVariableEditSheet = false
    @State private var isUpdating = false
    
    private var tagArray: [String] {
        tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    init(template: TemplateManager.Template, onComplete: @escaping (TemplateManager.Template) -> Void) {
        self.template = template
        self.onComplete = onComplete
        
        _name = State(initialValue: template.name)
        _selectedType = State(initialValue: template.type)
        _content = State(initialValue: template.content)
        _selectedCategory = State(initialValue: template.category)
        _tags = State(initialValue: template.tags.joined(separator: ", "))
        _isFavorite = State(initialValue: template.isFavorite)
        _variables = State(initialValue: template.variables)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("模板名称", text: $name)
                    
                    Picker("模板类型", selection: $selectedType) {
                        ForEach(TemplateManager.TemplateType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                        }
                    }
                    
                    Picker("分类", selection: $selectedCategory) {
                        ForEach(TemplateManager.TemplateCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.displayName)
                            }
                        }
                    }
                }
                
                Section(header: Text("模板内容")) {
                    TextEditor(text: $content)
                        .frame(height: 200)
                    
                    Text("使用 {{变量名}} 作为变量占位符")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("变量管理")) {
                    if variables.isEmpty {
                        Text("暂无变量")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(variables, id: \.id) { variable in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(variable.displayName)
                                        .font(.headline)
                                    
                                    Text("{{\(variable.name)}}")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if variable.required {
                                        Text("必填")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                Spacer()
                                
                                Button("编辑") {
                                    selectedVariable = variable
                                    showVariableEditSheet = true
                                }
                                .buttonStyle(.bordered)
                                
                                Button("删除") {
                                    variables.removeAll { $0.id == variable.id }
                                }
                                .buttonStyle(.bordered)
                                .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                Section {
                    Button("添加变量") {
                        showVariableEditor = true
                    }
                    .buttonStyle(.bordered)
                }
                
                Section(header: Text("标签")) {
                    TextField("标签 (用逗号分隔)", text: $tags)
                    
                    if !tagArray.isEmpty {
                        TagsView(tags: tagArray)
                    }
                }
                
                Section(header: Text("设置")) {
                    Toggle("收藏", isOn: $isFavorite)
                }
                
                Section {
                    Button("更新") {
                        updateTemplate()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.isEmpty || content.isEmpty || isUpdating)
                    
                    if isUpdating {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .navigationTitle("编辑模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 800)
        .sheet(isPresented: $showVariableEditor) {
            VariableEditorView { variable in
                variables.append(variable)
                showVariableEditor = false
            }
        }
        .sheet(isPresented: $showVariableEditSheet) {
            if let variable = selectedVariable {
                VariableEditorView(variable: variable) { updatedVariable in
                    if let index = variables.firstIndex(where: { $0.id == variable.id }) {
                        variables[index] = updatedVariable
                    }
                    showVariableEditSheet = false
                }
            }
        }
    }
    
    private func updateTemplate() {
        isUpdating = true
        
        let updatedTemplate = TemplateManager.Template(
            id: template.id,
            name: name,
            type: selectedType,
            content: content,
            variables: variables,
            category: selectedCategory,
            tags: tagArray,
            isFavorite: isFavorite,
            usageCount: template.usageCount,
            lastUsed: template.lastUsed,
            createdAt: template.createdAt,
            updatedAt: Date()
        )
        
        onComplete(updatedTemplate)
        dismiss()
    }
}

// MARK: - Use Template View

struct UseTemplateView: View {
    let template: TemplateManager.Template
    let onComplete: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var variables: [String: String] = [:]
    @State private var renderedContent: String = ""
    @State private var isRendering = false
    @State private var showingPreview = false
    @State private var validationErrors: [String] = []
    
    var body: some View {
        NavigationView {
            VStack {
                if showingPreview {
                    TemplatePreviewView(content: renderedContent)
                } else {
                    Form {
                        Section(header: Text("模板信息")) {
                            HStack {
                                Image(systemName: template.type.icon)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading) {
                                    Text(template.name)
                                        .font(.headline)
                                    
                                    Text(template.type.displayName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                        
                        Section(header: Text("变量设置")) {
                            ForEach(template.variables, id: \.id) { variable in
                                VariableInputView(
                                    variable: variable,
                                    value: Binding(
                                        get: { variables[variable.name] ?? variable.defaultValue ?? "" },
                                        set: { variables[variable.name] = $0 }
                                    )
                                )
                            }
                        }
                        
                        if !validationErrors.isEmpty {
                            Section(header: Text("验证错误")) {
                                ForEach(validationErrors, id: \.self) { error in
                                    Text(error)
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                            }
                        }
                        
                        Section {
                            Button("预览") {
                                previewTemplate()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("使用模板") {
                                useTemplate()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!validationErrors.isEmpty)
                            
                            if isRendering {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                }
            }
            .navigationTitle("使用模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(showingPreview ? "编辑" : "预览") {
                        showingPreview.toggle()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .frame(width: 700, height: 800)
    }
    
    private func previewTemplate() {
        isRendering = true
        validationErrors = []
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            do {
                renderedContent = try TemplateManager.shared.renderTemplate(template, variables: variables)
                showingPreview = true
            } catch {
                if let templateError = error as? TemplateManager.TemplateError {
                    validationErrors = [templateError.localizedDescription]
                } else {
                    validationErrors = [error.localizedDescription]
                }
            }
            
            isRendering = false
        }
    }
    
    private func useTemplate() {
        isRendering = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            do {
                let content = try TemplateManager.shared.renderTemplate(template, variables: variables)
                onComplete(content)
                dismiss()
            } catch {
                validationErrors = [error.localizedDescription]
            }
            
            isRendering = false
        }
    }
}

// MARK: - Template Preview View

struct TemplatePreviewView: View {
    let content: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(content)
                    .font(.body)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
            }
            .padding()
        }
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Variable Editor View

struct VariableEditorView: View {
    let variable: TemplateManager.TemplateVariable?
    let onComplete: (TemplateManager.TemplateVariable) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var displayName = ""
    @State private var selectedType: TemplateManager.VariableType = .text
    @State private var isRequired = false
    @State private var defaultValue = ""
    @State private var options: String = ""
    @State private var description = ""
    @State private var showValidationEditor = false
    @State private var validationRule: TemplateManager.ValidationRule?
    
    init(variable: TemplateManager.TemplateVariable? = nil, onComplete: @escaping (TemplateManager.TemplateVariable) -> Void) {
        self.variable = variable
        self.onComplete = onComplete
        
        if let variable = variable {
            _name = State(initialValue: variable.name)
            _displayName = State(initialValue: variable.displayName)
            _selectedType = State(initialValue: variable.type)
            _isRequired = State(initialValue: variable.required)
            _defaultValue = State(initialValue: variable.defaultValue ?? "")
            _options = State(initialValue: variable.options?.joined(separator: ", ") ?? "")
            _description = State(initialValue: variable.description ?? "")
            _validationRule = State(initialValue: variable.validation)
        }
    }
    
    private var optionArray: [String] {
        options.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("变量名", text: $name)
                        .font(.system(.body, design: .monospaced))
                    
                    TextField("显示名称", text: $displayName)
                    
                    Picker("变量类型", selection: $selectedType) {
                        ForEach(TemplateManager.VariableType.allCases, id: \.self) { type in
                            Text(type.displayName)
                        }
                    }
                    
                    Toggle("必填", isOn: $isRequired)
                }
                
                Section(header: Text("默认值")) {
                    TextField("默认值", text: $defaultValue)
                    
                    if selectedType == .select || selectedType == .multiselect {
                        TextField("选项 (用逗号分隔)", text: $options)
                        
                        if !optionArray.isEmpty {
                            TagsView(tags: optionArray)
                        }
                    }
                }
                
                Section(header: Text("验证规则")) {
                    if let validation = validationRule {
                        HStack {
                            Text(validation.type.displayName)
                            Spacer()
                            Button("编辑") {
                                showValidationEditor = true
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        Button("添加验证规则") {
                            showValidationEditor = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Section(header: Text("描述")) {
                    TextField("描述 (可选)", text: $description, axis: .vertical)
                        .lineLimit(3)
                }
                
                Section {
                    Button("保存") {
                        saveVariable()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.isEmpty || displayName.isEmpty)
                }
            }
            .navigationTitle(variable == nil ? "添加变量" : "编辑变量")
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
        .sheet(isPresented: $showValidationEditor) {
            ValidationRuleEditorView(rule: validationRule) { rule in
                validationRule = rule
                showValidationEditor = false
            }
        }
    }
    
    private func saveVariable() {
        let newVariable = TemplateManager.TemplateVariable(
            name: name,
            displayName: displayName,
            type: selectedType,
            required: isRequired,
            defaultValue: defaultValue.isEmpty ? nil : defaultValue,
            options: optionArray.isEmpty ? nil : optionArray,
            validation: validationRule,
            description: description.isEmpty ? nil : description
        )
        
        onComplete(newVariable)
        dismiss()
    }
}

// MARK: - Supporting Views

struct VariableInputView: View {
    let variable: TemplateManager.TemplateVariable
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(variable.displayName)
                    .font(.headline)
                
                if variable.required {
                    Text("*")
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Text("{{\(variable.name)}}")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            switch variable.type {
            case .text:
                TextField(variable.displayName, text: $value)
            case .number:
                TextField("数字", text: $value)
                    .keyboardType(.numberPad)
            case .date:
                DatePicker("日期", selection: Binding(
                    get: { Date() },
                    set: { value = DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .none) }
                ), displayedComponents: .date)
            case .time:
                DatePicker("时间", selection: Binding(
                    get: { Date() },
                    set: { value = DateFormatter.localizedString(from: $0, dateStyle: .none, timeStyle: .medium) }
                ), displayedComponents: .time)
            case .datetime:
                DatePicker("日期时间", selection: Binding(
                    get: { Date() },
                    set: { value = DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .medium) }
                ))
            case .boolean:
                Toggle("", isOn: Binding(
                    get: { value.lowercased() == "true" },
                    set: { value = $0 ? "true" : "false" }
                ))
                .labelsHidden()
            case .select:
                if let options = variable.options {
                    Picker("选择", selection: $value) {
                        ForEach(options, id: \.self) { option in
                            Text(option)
                        }
                    }
                    .pickerStyle(.menu)
                }
            case .multiselect:
                if let options = variable.options {
                    // For multiselect, we'd need a more complex UI
                    Text("多选功能开发中")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let description = variable.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ValidationRuleEditorView: View {
    let rule: TemplateManager.ValidationRule?
    let onComplete: (TemplateManager.ValidationRule?) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedType: TemplateManager.ValidationType = .required
    @State private var minLength = ""
    @State private var maxLength = ""
    @State private var pattern = ""
    @State private var minValue = ""
    @State private var maxValue = ""
    
    init(rule: TemplateManager.ValidationRule?, onComplete: @escaping (TemplateManager.ValidationRule?) -> Void) {
        self.rule = rule
        self.onComplete = onComplete
        
        if let rule = rule {
            _selectedType = State(initialValue: rule.type)
            
            switch rule.type {
            case .minLength:
                _minLength = State(initialValue: rule.parameters["min_length"] ?? "")
            case .maxLength:
                _maxLength = State(initialValue: rule.parameters["max_length"] ?? "")
            case .pattern:
                _pattern = State(initialValue: rule.parameters["pattern"] ?? "")
            case .range:
                _minValue = State(initialValue: rule.parameters["min"] ?? "")
                _maxValue = State(initialValue: rule.parameters["max"] ?? "")
            case .required:
                break
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("验证类型")) {
                    Picker("类型", selection: $selectedType) {
                        ForEach(TemplateManager.ValidationType.allCases, id: \.self) { type in
                            Text(type.displayName)
                        }
                    }
                }
                
                switch selectedType {
                case .minLength:
                    TextField("最小长度", text: $minLength)
                        .keyboardType(.numberPad)
                case .maxLength:
                    TextField("最大长度", text: $maxLength)
                        .keyboardType(.numberPad)
                case .pattern:
                    TextField("正则表达式", text: $pattern)
                case .range:
                    TextField("最小值", text: $minValue)
                        .keyboardType(.numberPad)
                    TextField("最大值", text: $maxValue)
                        .keyboardType(.numberPad)
                case .required:
                    Text("必填验证")
                        .font(.body)
                }
                
                Section {
                    Button("保存") {
                        saveValidationRule()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("删除") {
                        onComplete(nil)
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("验证规则")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 400, height: 400)
    }
    
    private func saveValidationRule() {
        var parameters: [String: String] = [:]
        
        switch selectedType {
        case .minLength:
            parameters["min_length"] = minLength
        case .maxLength:
            parameters["max_length"] = maxLength
        case .pattern:
            parameters["pattern"] = pattern
        case .range:
            parameters["min"] = minValue
            parameters["max"] = maxValue
        case .required:
            break
        }
        
        let validationRule = TemplateManager.ValidationRule(type: selectedType, parameters: parameters)
        onComplete(validationRule)
        dismiss()
    }
}

#Preview {
    AddTemplateView { _ in }
}