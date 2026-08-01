import SwiftUI
import Translation

struct QuickTranslationView: View {
    let model: QuickTranslationModel
    let terminologyStore: TerminologyStore
    let onRequestAccessibility: () -> Void
    let onOpenPrivacySettings: () -> Void
    let onDismiss: () -> Void

    @FocusState private var sourceIsFocused: Bool
    @State private var rewriteAvailability = OnDeviceRewriteService.availability
    @State private var rewriteTask: Task<Void, Never>?

    var body: some View {
        @Bindable var workspace = model.workspace

        VStack(spacing: 14) {
            contextHeader

            sourceEditor(workspace: workspace)

            translationResult(workspace: workspace)

            footer(workspace: workspace)
        }
        .padding(16)
        .frame(width: 500, height: 410)
        .background(.background)
        .translationTask(workspace.configuration) { session in
            await translate(using: session, workspace: workspace)
        }
        .onExitCommand(perform: onDismiss)
        .onAppear {
            rewriteAvailability = OnDeviceRewriteService.availability
        }
        .onChange(of: workspace.requestRevision) { _, _ in
            guard workspace.phase != .translating else { return }
            rewriteTask?.cancel()
            rewriteTask = nil
        }
        .onDisappear {
            rewriteTask?.cancel()
            rewriteTask = nil
        }
    }

    private var contextHeader: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: model.contextState.systemImage)
                .foregroundStyle(contextColor)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 3) {
                Text(model.contextState.label)
                    .font(.headline)

                if let message = model.contextState.message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            if model.contextState == .captureFailed(.permissionRequired) {
                Menu("Allow Access") {
                    Button("Request Access…", action: onRequestAccessibility)
                    Button("Open Privacy Settings…", action: onOpenPrivacySettings)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            Button {
                _ = model.useClipboard(Clipboard.text)
                sourceIsFocused = true
            } label: {
                Label("Use Clipboard", systemImage: "doc.on.clipboard")
            }
            .controlSize(.small)
        }
    }

    private func sourceEditor(workspace: TranslationWorkspace) -> some View {
        @Bindable var workspace = workspace
        @Bindable var model = model

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Original")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Picker("Action", selection: $model.action) {
                    ForEach(QuickTransformAction.allCases) { action in
                        Label(action.title, systemImage: action.systemImage)
                            .tag(action)
                    }
                }
                .labelsHidden()
                .controlSize(.small)
                .frame(width: 125)

                if model.action == .translate {
                    Picker("To", selection: $workspace.targetLanguage) {
                        ForEach(TranslationLanguage.allCases) { language in
                            Text(language.nativeName)
                                .tag(language)
                        }
                    }
                    .labelsHidden()
                    .controlSize(.small)
                    .frame(width: 125)
                }
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $workspace.sourceText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .focused($sourceIsFocused)
                    .accessibilityLabel("Text to transform")

                if workspace.sourceText.isEmpty {
                    Text("Type text or use the clipboard")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 7)
                        .allowsHitTesting(false)
                }
            }
            .padding(7)
            .frame(height: 92)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 9))
        }
    }

    private func translationResult(workspace: TranslationWorkspace) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(
                model.action == .translate
                    ? L10n.string("Translation")
                    : L10n.string("Rewritten")
            )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Group {
                if workspace.phase == .translating && workspace.translatedText.isEmpty {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text(
                            model.action == .translate
                                ? L10n.string("Translating…")
                                : L10n.string("Rewriting on this Mac…")
                        )
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if workspace.translatedText.isEmpty {
                    Text(
                        model.action == .translate
                            ? L10n.string("The translation will appear here.")
                            : L10n.string("The rewritten text will appear here.")
                    )
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(11)
                } else {
                    ScrollView {
                        Text(workspace.translatedText)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(11)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 9))
        }
    }

    private func footer(workspace: TranslationWorkspace) -> some View {
        HStack(spacing: 10) {
            statusView(workspace: workspace)

            Spacer()

            if workspace.phase == .translated {
                Button {
                    _ = model.copyTranslation()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }

            if model.canReplaceSelection {
                Button("Replace Selection") {
                    if model.replaceSelection() {
                        onDismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(model.action.title) {
                    model.clearActionStatus()
                    performAction(workspace: workspace)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(workspace.canTranslate == false || actionIsAvailable == false)
            }
        }
    }

    @ViewBuilder
    private func statusView(workspace: TranslationWorkspace) -> some View {
        if let actionStatus = model.actionStatus {
            switch actionStatus {
            case .copied:
                Label("Copied", systemImage: "checkmark")
                    .foregroundStyle(.green)
            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        } else if workspace.phase == .failed {
            Label(
                workspace.errorMessage ?? L10n.string("Translation failed."),
                systemImage: "exclamationmark.triangle.fill"
            )
            .foregroundStyle(.red)
            .lineLimit(2)
        } else if workspace.phase == .translated {
            Label("Ready", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } else {
            if actionIsAvailable {
                Text(L10n.format("⌘↩ to %@", model.action.title))
                    .foregroundStyle(.secondary)
            } else {
                Text(rewriteAvailability.label)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var contextColor: Color {
        switch model.contextState {
        case .capturedSelection, .clipboard:
            return .accentColor
        case .captureFailed(.secureField):
            return .secondary
        case .captureFailed:
            return .orange
        }
    }

    private func translate(
        using session: TranslationSession,
        workspace: TranslationWorkspace
    ) async {
        let requestSourceText = workspace.sourceText
        let requestRevision = model.actionRevision
        let requestWorkspaceRevision = workspace.requestRevision

        do {
            let response = try await session.translate(requestSourceText)
            guard
                model.action == .translate,
                model.actionRevision == requestRevision,
                workspace.requestRevision == requestWorkspaceRevision
            else {
                return
            }
            workspace.complete(
                translatedText: response.targetText,
                requestSourceText: requestSourceText,
                detectedSourceLanguage: response.sourceLanguage
            )
        } catch {
            guard
                model.action == .translate,
                model.actionRevision == requestRevision,
                workspace.requestRevision == requestWorkspaceRevision
            else {
                return
            }
            workspace.fail(error)
        }
    }

    private var actionIsAvailable: Bool {
        model.action == .translate || rewriteAvailability == .available
    }

    private func performAction(workspace: TranslationWorkspace) {
        if model.action == .translate {
            _ = workspace.requestTranslation()
            return
        }

        guard
            let rewriteAction = model.action.rewriteAction,
            let requestSourceText = workspace.beginTransformation()
        else {
            return
        }
        let requestAction = model.action
        let requestRevision = model.actionRevision
        let requestWorkspaceRevision = workspace.requestRevision

        rewriteTask?.cancel()
        rewriteTask = Task {
            do {
                let result = try await OnDeviceRewriteService.rewrite(
                    text: requestSourceText,
                    action: rewriteAction,
                    terminology: terminologyStore.entries
                )
                guard
                    model.action == requestAction,
                    model.actionRevision == requestRevision,
                    workspace.requestRevision == requestWorkspaceRevision
                else {
                    return
                }
                workspace.complete(
                    translatedText: result,
                    requestSourceText: requestSourceText,
                    detectedSourceLanguage: nil
                )
            } catch {
                guard
                    model.action == requestAction,
                    model.actionRevision == requestRevision,
                    workspace.requestRevision == requestWorkspaceRevision
                else {
                    return
                }
                workspace.fail(error)
            }
            rewriteTask = nil
        }
    }
}
