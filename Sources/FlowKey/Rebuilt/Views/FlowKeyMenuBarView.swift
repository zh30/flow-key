import AppKit
import SwiftUI

struct FlowKeyMenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    let settings: AppSettings
    let systemQuickTranslation: SystemQuickTranslation

    var body: some View {
        Button {
            systemQuickTranslation.showPanel()
        } label: {
            HStack {
                Label("Quick Action", systemImage: "selection.pin.in.out")
                Spacer()
                Text(settings.quickTranslationShortcut.symbols)
                    .foregroundStyle(.secondary)
            }
        }

        Button {
            systemQuickTranslation.dismissPanel()
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "translator")
        } label: {
            Label("Open FlowKey", systemImage: "character.bubble")
        }

        SettingsLink {
            Label("Settings…", systemImage: "gearshape")
        }

        Divider()

        Button("Quit FlowKey") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
