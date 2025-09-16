import SwiftUI
import AppKit

// Modern Settings View with macOS 26 features
struct ModernSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationService: LocalizationService

    // Modern state management
    @State private var generalSettings = GeneralSettings()
    @State private var translationSettings = TranslationSettings()
    @State private var advancedSettings = AdvancedSettings()
    @State private var selectedLanguage: SupportedLanguage = .english

    // Modern form state
    @State private var showResetAlert = false
    @State private var showExportAlert = false
    @State private var showImportAlert = false

    var body: some View {
        NavigationView {
            List {
                Section("General") {
                    GeneralSettingsView(settings: $generalSettings)
                }

                Section("Translation") {
                    TranslationSettingsView(settings: $translationSettings)
                }

                Section("App Language") {
                    LanguageSettingsView(
                        selectedLanguage: $selectedLanguage,
                        localizationService: localizationService
                    )
                }

                Section("Advanced") {
                    AdvancedSettingsView(settings: $advancedSettings)
                }

                Section("About") {
                    AboutView()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        saveSettings()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }

                ToolbarItem(placement: .secondaryAction) {
                    Menu("More") {
                        Button("Reset to Defaults") {
                            showResetAlert = true
                        }
                        Button("Export Settings") {
                            showExportAlert = true
                        }
                        Button("Import Settings") {
                            showImportAlert = true
                        }
                    }
                }
            }
        }
        .frame(width: 600, height: 700)
        .alert("Reset Settings", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) {
                resetToDefaults()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to reset all settings to their default values?")
        }
        .alert("Export Settings", isPresented: $showExportAlert) {
            Button("Export") {
                exportSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose a location to save your settings file.")
        }
        .alert("Import Settings", isPresented: $showImportAlert) {
            Button("Import") {
                importSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Select a settings file to import.")
        }
        .onAppear {
            loadSettings()
        }
    }

    private func loadSettings() {
        // Load settings from UserDefaults
        generalSettings = GeneralSettings.load()
        translationSettings = TranslationSettings.load()
        advancedSettings = AdvancedSettings.load()
        selectedLanguage = localizationService.currentLanguage
    }

    private func saveSettings() {
        // Save settings to UserDefaults
        generalSettings.save()
        translationSettings.save()
        advancedSettings.save()
        localizationService.setLanguage(selectedLanguage)

        // Show notification
        showSettingsSavedNotification()
    }

    private func resetToDefaults() {
        generalSettings = GeneralSettings()
        translationSettings = TranslationSettings()
        advancedSettings = AdvancedSettings()
        selectedLanguage = .english
        saveSettings()
    }

    private func exportSettings() {
        let settings = SettingsBundle(
            general: generalSettings,
            translation: translationSettings,
            advanced: advancedSettings,
            language: selectedLanguage
        )

        // Create JSON data
        do {
            let jsonData = try JSONEncoder().encode(settings)
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = "FlowKey-Settings.json"

            if panel.runModal() == .OK {
                try jsonData.write(to: panel.url!)
            }
        } catch {
            print("Error exporting settings: \(error)")
        }
    }

    private func importSettings() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            do {
                let data = try Data(contentsOf: panel.urls.first!)
                let settings = try JSONDecoder().decode(SettingsBundle.self, from: data)

                generalSettings = settings.general
                translationSettings = settings.translation
                advancedSettings = settings.advanced
                selectedLanguage = settings.language

                saveSettings()
            } catch {
                print("Error importing settings: \(error)")
            }
        }
    }

    private func showSettingsSavedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Settings Saved"
        content.body = "Your settings have been saved successfully."
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }
        }
    }
}

// MARK: - Settings Models

struct GeneralSettings: Codable {
    var launchAtLogin = false
    var showInMenuBar = true
    var autoCheckUpdates = true
    var showNotifications = true
    var startAtLogin = false

    static func load() -> GeneralSettings {
        if let data = UserDefaults.standard.data(forKey: "GeneralSettings"),
           let settings = try? JSONDecoder().decode(GeneralSettings.self, from: data) {
            return settings
        }
        return GeneralSettings()
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "GeneralSettings")
        }
    }
}

struct TranslationSettings: Codable {
    var autoDetectLanguage = true
    var sourceLanguage = "auto"
    var targetLanguage = "en"
    var showTranslationPopup = true
    var autoTranslateSelectedText = true
    var translateOnTripleSpace = true

    static func load() -> TranslationSettings {
        if let data = UserDefaults.standard.data(forKey: "TranslationSettings"),
           let settings = try? JSONDecoder().decode(TranslationSettings.self, from: data) {
            return settings
        }
        return TranslationSettings()
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "TranslationSettings")
        }
    }
}

struct AdvancedSettings: Codable {
    var debugMode = false
    var logLevel = "info"
    var dataCollectionEnabled = false
    var performanceMonitoring = false
    var betaFeaturesEnabled = false

    static func load() -> AdvancedSettings {
        if let data = UserDefaults.standard.data(forKey: "AdvancedSettings"),
           let settings = try? JSONDecoder().decode(AdvancedSettings.self, from: data) {
            return settings
        }
        return AdvancedSettings()
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "AdvancedSettings")
        }
    }
}

struct SettingsBundle: Codable {
    let general: GeneralSettings
    let translation: TranslationSettings
    let advanced: AdvancedSettings
    let language: SupportedLanguage
}

// MARK: - Settings Subviews

struct GeneralSettingsView: View {
    @Binding var settings: GeneralSettings

    var body: some View {
        Toggle("Launch at Login", isOn: $settings.launchAtLogin)
        Toggle("Show in Menu Bar", isOn: $settings.showInMenuBar)
        Toggle("Start at Login", isOn: $settings.startAtLogin)
        Toggle("Auto Check Updates", isOn: $settings.autoCheckUpdates)
        Toggle("Show Notifications", isOn: $settings.showNotifications)
    }
}

struct TranslationSettingsView: View {
    @Binding var settings: TranslationSettings

    let languages = [
        ("Auto Detect", "auto"),
        ("English", "en"),
        ("Chinese", "zh"),
        ("Spanish", "es"),
        ("Hindi", "hi"),
        ("Arabic", "ar")
    ]

    var body: some View {
        Toggle("Auto Detect Language", isOn: $settings.autoDetectLanguage)

        if !settings.autoDetectLanguage {
            Picker("Source Language", selection: $settings.sourceLanguage) {
                ForEach(languages, id: \.1) { name, code in
                    Text(name).tag(code)
                }
            }
            .pickerStyle(.menu)
        }

        Picker("Target Language", selection: $settings.targetLanguage) {
            ForEach(languages.dropFirst(), id: \.1) { name, code in
                Text(name).tag(code)
            }
        }
        .pickerStyle(.menu)

        Toggle("Show Translation Popup", isOn: $settings.showTranslationPopup)
        Toggle("Auto Translate Selected Text", isOn: $settings.autoTranslateSelectedText)
        Toggle("Translate on Triple Space", isOn: $settings.translateOnTripleSpace)
    }
}

struct LanguageSettingsView: View {
    @Binding var selectedLanguage: SupportedLanguage
    @ObservedObject var localizationService: LocalizationService

    var body: some View {
        Picker("App Language", selection: $selectedLanguage) {
            ForEach(SupportedLanguage.allCases) { language in
                HStack {
                    Text(language.flag)
                    Text(language.nativeName)
                }
                .tag(language)
            }
        }
        .pickerStyle(.navigationLink)
        .onChange(of: selectedLanguage) { newLanguage in
            localizationService.setLanguage(newLanguage)
        }
    }
}

struct AdvancedSettingsView: View {
    @Binding var settings: AdvancedSettings

    var body: some View {
        Toggle("Debug Mode", isOn: $settings.debugMode)
        Toggle("Performance Monitoring", isOn: $settings.performanceMonitoring)
        Toggle("Beta Features", isOn: $settings.betaFeaturesEnabled)

        if settings.debugMode {
            Picker("Log Level", selection: $settings.logLevel) {
                Text("Debug").tag("debug")
                Text("Info").tag("info")
                Text("Warning").tag("warning")
                Text("Error").tag("error")
            }
            .pickerStyle(.menu)
        }

        Toggle("Data Collection", isOn: $settings.dataCollectionEnabled)
            .foregroundColor(.red)
    }
}

struct AboutView: View {
    @State private var buildDate = Date()

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("FlowKey")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Text("v2.0")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Build Date:")
                    .foregroundColor(.secondary)

                Spacer()

                Text(buildDate.formatted(date: .abbreviated, time: .shortened))
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("macOS Version:")
                    .foregroundColor(.secondary)

                Spacer()

                Text(ProcessInfo.processInfo.operatingSystemVersionString)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Swift Version:")
                    .foregroundColor(.secondary)

                Spacer()

                Text("6.0")
                    .foregroundColor(.secondary)
            }

            Divider()

            Text("© 2025 FlowKey Team. All rights reserved.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .onAppear {
            // Get actual build date
            if let buildDateString = Bundle.main.infoDictionary?["BuildDate"] as? String {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                buildDate = formatter.date(from: buildDateString) ?? Date()
            }
        }
    }
}

// MARK: - Extensions

extension UTType {
    static let json = UTType("public.json")
}