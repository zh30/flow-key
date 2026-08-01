import AppKit
import SwiftUI
import Translation

struct TranslationWorkspaceView: View {
    private enum FocusedEditor {
        case source
    }

    let settings: AppSettings
    let workspace: TranslationWorkspace
    @State private var copied = false
    @State private var copyResetTask: Task<Void, Never>?
    @FocusState private var focusedEditor: FocusedEditor?

    var body: some View {
        @Bindable var workspace = workspace

        VStack(spacing: 0) {
            languageBar(workspace: workspace)

            Divider()

            HSplitView {
                sourceEditor(workspace: workspace)
                translationResult(workspace: workspace)
            }

            Divider()

            footer(workspace: workspace)
        }
        .frame(minWidth: 680, minHeight: 430)
        .navigationTitle("FlowKey")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    paste(workspace: workspace)
                } label: {
                    Label("Paste", systemImage: "doc.on.clipboard")
                }
                .help("Paste text from the clipboard")

                Button {
                    workspace.clear()
                    focusedEditor = .source
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .help("Clear the translation")
                .disabled(workspace.sourceText.isEmpty && workspace.translatedText.isEmpty)

                SettingsLink()
            }
        }
        .translationTask(workspace.configuration) { session in
            await translate(using: session, workspace: workspace)
        }
        .task {
            await Task.yield()
            focusedEditor = .source
        }
        .onDisappear {
            copyResetTask?.cancel()
            copyResetTask = nil
        }
        .onChange(of: settings.defaultTargetLanguage) { _, newLanguage in
            guard workspace.phase != .translating else { return }
            workspace.targetLanguage = newLanguage
        }
        .focusedSceneValue(
            \.flowKeyPrimaryAction,
            WorkspaceCommandAction(
                title: L10n.string("Translate"),
                isEnabled: true,
                perform: { _ = workspace.requestTranslation() }
            )
        )
        .focusedSceneValue(
            \.flowKeyClearAction,
            WorkspaceCommandAction(
                title: L10n.string("Clear Translation"),
                isEnabled: true,
                perform: workspace.clear
            )
        )
    }

    private func languageBar(workspace: TranslationWorkspace) -> some View {
        @Bindable var workspace = workspace

        return HStack(spacing: 12) {
            Picker("From", selection: $workspace.sourceLanguage) {
                Text("Detect Automatically")
                    .tag(Optional<TranslationLanguage>.none)

                Divider()

                ForEach(TranslationLanguage.allCases) { language in
                    Text(language.nativeName)
                        .tag(Optional(language))
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .disabled(workspace.phase == .translating)

            Button {
                workspace.swapLanguages()
            } label: {
                Image(systemName: "arrow.left.arrow.right")
            }
            .buttonStyle(.borderless)
            .help("Swap languages")
            .accessibilityLabel("Swap languages")
            .disabled(workspace.sourceLanguage == nil || workspace.phase == .translating)

            Picker("To", selection: $workspace.targetLanguage) {
                ForEach(TranslationLanguage.allCases) { language in
                    Text(language.nativeName)
                        .tag(language)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .disabled(workspace.phase == .translating)
        }
        .controlSize(.large)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func sourceEditor(workspace: TranslationWorkspace) -> some View {
        @Bindable var workspace = workspace

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Original")
                    .font(.headline)

                Spacer()

                DictationControl(
                    text: $workspace.sourceText,
                    localeIdentifier: workspace.sourceLanguage?.rawValue ?? Locale.current.identifier
                )

                Text(L10n.format("%d characters", workspace.sourceText.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $workspace.sourceText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .focused($focusedEditor, equals: .source)
                    .accessibilityLabel("Text to translate")

                if workspace.sourceText.isEmpty {
                    Text("Type or paste text here")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
            }
            .padding(8)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(20)
        .frame(minWidth: 280)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func translationResult(workspace: TranslationWorkspace) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Translation")
                    .font(.headline)

                Spacer()

                if workspace.translatedText.isEmpty == false {
                    Button {
                        copyResult(workspace: workspace)
                    } label: {
                        Label(
                            copied ? L10n.string("Copied") : L10n.string("Copy"),
                            systemImage: copied ? "checkmark" : "doc.on.doc"
                        )
                    }
                    .buttonStyle(.borderless)
                }
            }

            Group {
                if workspace.phase == .translating && workspace.translatedText.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Translating…")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if workspace.translatedText.isEmpty {
                    ContentUnavailableView(
                        "Ready to Translate",
                        systemImage: "character.bubble",
                        description: Text("Your translation will appear here.")
                    )
                } else {
                    ScrollView {
                        Text(workspace.translatedText)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .textSelection(.enabled)
                            .padding(14)
                    }
                }
            }
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(20)
        .frame(minWidth: 280)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func footer(workspace: TranslationWorkspace) -> some View {
        HStack(spacing: 12) {
            statusView(workspace: workspace)

            Spacer()

            Button("Translate") {
                _ = workspace.requestTranslation()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(workspace.canTranslate == false)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func statusView(workspace: TranslationWorkspace) -> some View {
        switch workspace.phase {
        case .idle:
            Label("Ready", systemImage: "checkmark.circle")
                .foregroundStyle(.secondary)
        case .translating:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Translating…")
            }
            .foregroundStyle(.secondary)
        case .translated:
            Label("Translation complete", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Label(
                workspace.errorMessage ?? L10n.string("Translation failed."),
                systemImage: "exclamationmark.triangle.fill"
            )
                .foregroundStyle(.red)
                .lineLimit(2)
        }
    }

    private func translate(
        using session: TranslationSession,
        workspace: TranslationWorkspace
    ) async {
        let requestSourceText = workspace.sourceText
        let requestRevision = workspace.requestRevision

        do {
            let response = try await session.translate(requestSourceText)
            guard workspace.requestRevision == requestRevision else { return }
            workspace.complete(
                translatedText: response.targetText,
                requestSourceText: requestSourceText,
                detectedSourceLanguage: response.sourceLanguage
            )

            if settings.automaticallyCopiesTranslations {
                copyResult(workspace: workspace)
            }
        } catch {
            guard workspace.requestRevision == requestRevision else { return }
            workspace.fail(error)
        }
    }

    private func paste(workspace: TranslationWorkspace) {
        guard let text = Clipboard.text, text.isEmpty == false else {
            workspace.fail(message: L10n.string("The clipboard does not contain text."))
            return
        }

        workspace.sourceText = text
        focusedEditor = .source
    }

    private func copyResult(workspace: TranslationWorkspace) {
        guard workspace.translatedText.isEmpty == false else { return }
        copyResetTask?.cancel()
        copied = Clipboard.write(workspace.translatedText)
        guard copied else { return }

        copyResetTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard Task.isCancelled == false else { return }
            copied = false
        }
    }
}
