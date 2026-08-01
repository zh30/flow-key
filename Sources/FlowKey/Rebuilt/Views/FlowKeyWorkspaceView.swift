import SwiftUI

struct FlowKeyWorkspaceView: View {
    let settings: AppSettings
    let terminologyStore: TerminologyStore
    @State private var mode: WorkspaceMode = .translate
    @State private var translationWorkspace: TranslationWorkspace
    @State private var rewriteWorkspace = RewriteWorkspace()

    init(settings: AppSettings, terminologyStore: TerminologyStore) {
        self.settings = settings
        self.terminologyStore = terminologyStore
        _translationWorkspace = State(
            initialValue: TranslationWorkspace(
                targetLanguage: settings.defaultTargetLanguage
            )
        )
    }

    var body: some View {
        Group {
            switch mode {
            case .translate:
                TranslationWorkspaceView(
                    settings: settings,
                    workspace: translationWorkspace
                )
            case .rewrite:
                RewriteWorkspaceView(
                    terminologyStore: terminologyStore,
                    workspace: rewriteWorkspace
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Workspace", selection: $mode) {
                    ForEach(WorkspaceMode.allCases) { mode in
                        Text(mode.title)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 210)
            }
        }
        .onChange(of: mode) { previousMode, newMode in
            transferDraft(from: previousMode, to: newMode)
        }
        .focusedSceneValue(
            \.flowKeyModeSelection,
            WorkspaceModeSelection(mode: mode, selection: $mode)
        )
    }

    private func transferDraft(
        from sourceMode: WorkspaceMode,
        to destinationMode: WorkspaceMode
    ) {
        switch (sourceMode, destinationMode) {
        case (.translate, .rewrite):
            rewriteWorkspace.replaceSource(with: translationWorkspace.sourceText)
        case (.rewrite, .translate):
            translationWorkspace.replaceSource(with: rewriteWorkspace.sourceText)
        default:
            break
        }
    }
}
