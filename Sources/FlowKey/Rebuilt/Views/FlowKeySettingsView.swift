import AppKit
import SwiftUI

struct FlowKeySettingsView: View {
    @Bindable var settings: AppSettings
    let systemQuickTranslation: SystemQuickTranslation
    let inputMethodManager: InputMethodManager
    let terminologyStore: TerminologyStore

    @Environment(\.scenePhase) private var scenePhase
    @State private var showsInputMethodConfirmation = false

    var body: some View {
        TabView {
            Form {
                Section("Translation") {
                    Picker("Default target language", selection: $settings.defaultTargetLanguage) {
                        ForEach(TranslationLanguage.allCases) { language in
                            Text(language.nativeName)
                                .tag(language)
                        }
                    }

                    Toggle(
                        "Copy translations from the main window automatically",
                        isOn: $settings.automaticallyCopiesTranslations
                    )
                }

                Section("Quick Action") {
                    Picker("Global shortcut", selection: $settings.quickTranslationShortcut) {
                        ForEach(QuickTranslationShortcut.allCases) { shortcut in
                            HStack {
                                Text(shortcut.displayName)
                                Spacer()
                                Text(shortcut.symbols)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(shortcut)
                        }
                    }

                    LabeledContent("Shortcut status") {
                        Label(
                            systemQuickTranslation.shortcutStatus.label,
                            systemImage: shortcutStatusImage
                        )
                        .foregroundStyle(shortcutStatusColor)
                    }

                    LabeledContent("Selected-text access") {
                        HStack(spacing: 8) {
                            Label(
                                systemQuickTranslation.accessibilityAuthorized
                                    ? L10n.string("Allowed")
                                    : L10n.string("Not allowed"),
                                systemImage: systemQuickTranslation.accessibilityAuthorized
                                    ? "checkmark.circle.fill"
                                    : "hand.raised.fill"
                            )
                            .foregroundStyle(
                                systemQuickTranslation.accessibilityAuthorized ? .green : .orange
                            )

                            if systemQuickTranslation.accessibilityAuthorized == false {
                                Menu("Allow…") {
                                    Button("Request Access…") {
                                        systemQuickTranslation.requestAccessibilityAccess()
                                    }

                                    Button("Open Privacy Settings…") {
                                        systemQuickTranslation.openAccessibilitySettings()
                                    }
                                }
                                .menuStyle(.borderlessButton)
                                .fixedSize()
                            }
                        }
                    }

                    Text(
                        "Accessibility is used only when you invoke Quick Action, so FlowKey can read the current selection. Replacing text always requires a separate click."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                    if systemQuickTranslation.shortcutStatus == .unavailable {
                        Label(
                            "Another app is already using this shortcut. Choose a different one.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(.orange)
                    }
                }

                Section("Privacy") {
                    Text("Translation uses Apple's Translation framework. Rewrite uses Apple's on-device model when this Mac supports it. Dictation starts only when you click the microphone. FlowKey does not add its own language server.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section("Optional Input Method") {
                    LabeledContent("FlowKey Compose") {
                        Label(
                            inputMethodManager.state.label,
                            systemImage: inputMethodManager.state.systemImage
                        )
                        .foregroundStyle(inputMethodStatusColor)
                    }

                    Text(
                        "Adds a real macOS input source. While it is selected, press Control-Option-F to start a marked composition, type, choose a native candidate, then press Return to commit or Escape to cancel. Ordinary typing passes through unchanged."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                    if let errorMessage = inputMethodManager.lastErrorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack {
                        if inputMethodManager.canInstall {
                            Button("Install Input Method…") {
                                showsInputMethodConfirmation = true
                            }
                        }

                        Button("Open Keyboard Settings…") {
                            inputMethodManager.openKeyboardSettings()
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("General", systemImage: "gearshape")
            }
            .onAppear {
                systemQuickTranslation.dismissPanel()
                systemQuickTranslation.refreshAccessibilityStatus()
                inputMethodManager.refresh()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    systemQuickTranslation.refreshAccessibilityStatus()
                    inputMethodManager.refresh()
                }
            }

            TerminologySettingsView(store: terminologyStore)
                .tabItem {
                    Label("Terms", systemImage: "text.book.closed")
                }

            AboutFlowKeyView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 560, height: 690)
        .scenePadding()
        .confirmationDialog(
            "Install FlowKey Compose?",
            isPresented: $showsInputMethodConfirmation
        ) {
            Button("Install") {
                inputMethodManager.install()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "FlowKey will copy its signed input-method bundle to your user Library/Input Methods folder. macOS will still require you to add or select it in Keyboard Settings."
            )
        }
    }

    private var shortcutStatusImage: String {
        switch systemQuickTranslation.shortcutStatus {
        case .registered:
            return "checkmark.circle.fill"
        case .disabled:
            return "minus.circle"
        case .unavailable:
            return "exclamationmark.triangle.fill"
        }
    }

    private var shortcutStatusColor: Color {
        switch systemQuickTranslation.shortcutStatus {
        case .registered:
            return .green
        case .disabled:
            return .secondary
        case .unavailable:
            return .orange
        }
    }

    private var inputMethodStatusColor: Color {
        switch inputMethodManager.state {
        case .enabled, .selected:
            return .green
        case .installed:
            return .secondary
        case .notInstalled:
            return .secondary
        case .unavailable:
            return .orange
        }
    }
}

private struct AboutFlowKeyView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ??
            L10n.string("Development")
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "character.bubble.fill")
                .font(.system(size: 48))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)

            Text("FlowKey")
                .font(.title2.weight(.semibold))

            Text(L10n.format("Version %@", version))
                .foregroundStyle(.secondary)

            Text("Translate, rewrite, and dictate with tools built into macOS.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
