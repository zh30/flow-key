import SwiftUI

struct RewriteWorkspaceView: View {
    let terminologyStore: TerminologyStore
    let workspace: RewriteWorkspace

    @State private var availability = OnDeviceRewriteService.availability
    @State private var copied = false
    @State private var copyResetTask: Task<Void, Never>?
    @State private var rewriteTask: Task<Void, Never>?
    @FocusState private var sourceIsFocused: Bool

    var body: some View {
        @Bindable var workspace = workspace

        VStack(spacing: 0) {
            actionBar(workspace: workspace)

            Divider()

            HSplitView {
                sourceEditor(workspace: workspace)
                resultView(workspace: workspace)
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
                    sourceIsFocused = true
                } label: {
                    Label("Paste", systemImage: "doc.on.clipboard")
                }

                Button {
                    workspace.clear()
                    sourceIsFocused = true
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .disabled(workspace.sourceText.isEmpty && workspace.resultText.isEmpty)

                SettingsLink()
            }
        }
        .onAppear {
            availability = OnDeviceRewriteService.availability
        }
        .task {
            await Task.yield()
            sourceIsFocused = true
        }
        .onChange(of: workspace.requestRevision) { _, _ in
            guard workspace.phase != .rewriting else { return }
            rewriteTask?.cancel()
            rewriteTask = nil
        }
        .onDisappear {
            copyResetTask?.cancel()
            rewriteTask?.cancel()
            copyResetTask = nil
            rewriteTask = nil
        }
        .focusedSceneValue(
            \.flowKeyPrimaryAction,
            WorkspaceCommandAction(
                title: workspace.action.title,
                isEnabled: availability == .available,
                perform: { rewrite(workspace: workspace) }
            )
        )
        .focusedSceneValue(
            \.flowKeyClearAction,
            WorkspaceCommandAction(
                title: L10n.string("Clear Rewrite"),
                isEnabled: true,
                perform: workspace.clear
            )
        )
    }

    private func actionBar(workspace: RewriteWorkspace) -> some View {
        @Bindable var workspace = workspace

        return VStack(alignment: .leading, spacing: 10) {
            Picker("Rewrite action", selection: $workspace.action) {
                ForEach(RewriteAction.allCases) { action in
                    Label(action.title, systemImage: action.systemImage)
                        .tag(action)
                }
            }
            .pickerStyle(.segmented)

            if availability != .available {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "apple.intelligence")
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(availability.label)
                            .font(.callout.weight(.medium))
                        if let recovery = availability.recoverySuggestion {
                            Text(recovery)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func sourceEditor(workspace: RewriteWorkspace) -> some View {
        @Bindable var workspace = workspace

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Original")
                    .font(.headline)
                Spacer()

                DictationControl(
                    text: $workspace.sourceText,
                    localeIdentifier: Locale.current.identifier
                )

                Text(L10n.format("%d characters", workspace.sourceText.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $workspace.sourceText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .focused($sourceIsFocused)
                    .accessibilityLabel("Text to rewrite")

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

    private func resultView(workspace: RewriteWorkspace) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Rewritten")
                    .font(.headline)
                Spacer()

                if workspace.resultText.isEmpty == false {
                    Button("Use as Original") {
                        workspace.useResultAsSource()
                        sourceIsFocused = true
                    }
                    .buttonStyle(.borderless)
                }
            }

            Group {
                if workspace.phase == .rewriting && workspace.resultText.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Rewriting on this Mac…")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if workspace.resultText.isEmpty {
                    ContentUnavailableView(
                        "Ready to Rewrite",
                        systemImage: "apple.intelligence",
                        description: Text("The rewritten text will appear here.")
                    )
                } else {
                    ScrollView {
                        Text(workspace.resultText)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
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

    private func footer(workspace: RewriteWorkspace) -> some View {
        HStack(spacing: 12) {
            statusView(workspace: workspace)
            Spacer()

            if workspace.resultText.isEmpty == false {
                Button {
                    copyResult(workspace: workspace)
                } label: {
                    Label(
                        copied ? L10n.string("Copied") : L10n.string("Copy"),
                        systemImage: copied ? "checkmark" : "doc.on.doc"
                    )
                }
            }

            Button(workspace.action.title) {
                rewrite(workspace: workspace)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(workspace.canRewrite == false || availability != .available)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func statusView(workspace: RewriteWorkspace) -> some View {
        switch workspace.phase {
        case .idle:
            Label(
                availability == .available
                    ? L10n.string("On-device")
                    : L10n.string("Rewrite unavailable"),
                systemImage: "lock.shield"
            )
                .foregroundStyle(.secondary)
        case .rewriting:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Rewriting…")
            }
            .foregroundStyle(.secondary)
        case .rewritten:
            Label("Rewrite complete", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Label(
                workspace.errorMessage ?? L10n.string("Rewrite failed."),
                systemImage: "exclamationmark.triangle.fill"
            )
                .foregroundStyle(.red)
                .lineLimit(2)
        }
    }

    private func rewrite(workspace: RewriteWorkspace) {
        guard let requestSourceText = workspace.beginRewrite() else { return }
        let action = workspace.action
        let requestRevision = workspace.requestRevision

        rewriteTask?.cancel()
        rewriteTask = Task {
            do {
                let result = try await OnDeviceRewriteService.rewrite(
                    text: requestSourceText,
                    action: action,
                    terminology: terminologyStore.entries
                )
                guard
                    workspace.action == action,
                    workspace.requestRevision == requestRevision
                else {
                    return
                }
                workspace.complete(result: result, requestSourceText: requestSourceText)
            } catch {
                guard workspace.requestRevision == requestRevision else { return }
                workspace.fail(error)
            }
            rewriteTask = nil
        }
    }

    private func copyResult(workspace: RewriteWorkspace) {
        guard workspace.resultText.isEmpty == false else { return }
        copyResetTask?.cancel()
        copied = Clipboard.write(workspace.resultText)
        guard copied else { return }

        copyResetTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard Task.isCancelled == false else { return }
            copied = false
        }
    }

    private func paste(workspace: RewriteWorkspace) {
        guard let text = Clipboard.text, text.isEmpty == false else {
            workspace.fail(message: L10n.string("The clipboard does not contain text."))
            return
        }
        workspace.sourceText = text
    }
}
