import SwiftUI

struct WorkspaceModeSelection {
    let mode: WorkspaceMode
    let selection: Binding<WorkspaceMode>
}

struct WorkspaceCommandAction {
    let title: String
    let isEnabled: Bool
    let perform: () -> Void
}

private struct WorkspaceModeSelectionKey: FocusedValueKey {
    typealias Value = WorkspaceModeSelection
}

private struct WorkspacePrimaryActionKey: FocusedValueKey {
    typealias Value = WorkspaceCommandAction
}

private struct WorkspaceClearActionKey: FocusedValueKey {
    typealias Value = WorkspaceCommandAction
}

extension FocusedValues {
    var flowKeyModeSelection: WorkspaceModeSelection? {
        get { self[WorkspaceModeSelectionKey.self] }
        set { self[WorkspaceModeSelectionKey.self] = newValue }
    }

    var flowKeyPrimaryAction: WorkspaceCommandAction? {
        get { self[WorkspacePrimaryActionKey.self] }
        set { self[WorkspacePrimaryActionKey.self] = newValue }
    }

    var flowKeyClearAction: WorkspaceCommandAction? {
        get { self[WorkspaceClearActionKey.self] }
        set { self[WorkspaceClearActionKey.self] = newValue }
    }
}

struct FlowKeyCommands: Commands {
    @FocusedValue(\.flowKeyModeSelection) private var modeSelection
    @FocusedValue(\.flowKeyPrimaryAction) private var primaryAction
    @FocusedValue(\.flowKeyClearAction) private var clearAction

    var body: some Commands {
        CommandMenu("Transform") {
            Toggle(
                "Translate Workspace",
                isOn: modeBinding(for: .translate)
            )
            .keyboardShortcut("1", modifiers: .command)
            .disabled(modeSelection == nil)

            Toggle(
                "Rewrite Workspace",
                isOn: modeBinding(for: .rewrite)
            )
            .keyboardShortcut("2", modifiers: .command)
            .disabled(modeSelection == nil)

            Divider()

            Button(primaryAction?.title ?? L10n.string("Run Action")) {
                primaryAction?.perform()
            }
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(primaryAction?.isEnabled != true)

            Button(clearAction?.title ?? L10n.string("Clear")) {
                clearAction?.perform()
            }
            .disabled(clearAction?.isEnabled != true)
        }
    }

    private func modeBinding(for mode: WorkspaceMode) -> Binding<Bool> {
        Binding(
            get: { modeSelection?.mode == mode },
            set: { isSelected in
                guard isSelected else { return }
                modeSelection?.selection.wrappedValue = mode
            }
        )
    }
}
