import SwiftUI
import AppKit
import UserNotifications

// Legacy simplified views reused by the main app entry point in AppDelegate.swift
struct ContentView: View {
    @State private var showSettings = false
    @EnvironmentObject var localizationService: LocalizationService
    
    var body: some View {
        VStack(spacing: 20) {
            Text(localizationService.localizedString(forKey: .appTitle))
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            statusIndicator
            featureList
            actionButtons
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 600)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(localizationService)
        }
    }
    
    private var statusIndicator: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(Color.green)
                .frame(width: 20, height: 20)
            Text(localizationService.localizedString(forKey: .appStarted))
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var featureList: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(localizationService.localizedString(forKey: .featuresTitle))
                .font(.title2)
                .fontWeight(.semibold)
            
            FeatureRow(
                icon: "globe",
                title: localizationService.localizedString(forKey: .featureTranslation),
                description: localizationService.localizedString(forKey: .featureTranslationDesc)
            )
            FeatureRow(
                icon: "mic",
                title: localizationService.localizedString(forKey: .featureVoice),
                description: localizationService.localizedString(forKey: .featureVoiceDesc)
            )
            FeatureRow(
                icon: "brain",
                title: localizationService.localizedString(forKey: .featureRecommendation),
                description: localizationService.localizedString(forKey: .featureRecommendationDesc)
            )
            FeatureRow(
                icon: "book",
                title: localizationService.localizedString(forKey: .featureKnowledge),
                description: localizationService.localizedString(forKey: .featureKnowledgeDesc)
            )
            FeatureRow(
                icon: "cloud",
                title: localizationService.localizedString(forKey: .featureSync),
                description: localizationService.localizedString(forKey: .featureSyncDesc)
            )
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(localizationService.localizedString(forKey: .buttonOpenSettings)) {
                showSettings = true
            }
            .buttonStyle(.borderedProminent)
            
            Button(localizationService.localizedString(forKey: .buttonTestTranslation)) {
                testTranslation()
            }
            .buttonStyle(.bordered)
            
            Button(localizationService.localizedString(forKey: .buttonExitApp)) {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.bordered)
        }
        .padding(.top, 20)
    }
    
    private func testTranslation() {
        let alert = NSAlert()
        alert.messageText = localizationService.localizedString(forKey: .translationTest)
        alert.informativeText = localizationService.localizedString(forKey: .translationTestResult)
        alert.alertStyle = .informational
        
        alert.addButton(withTitle: localizationService.localizedString(forKey: .buttonOK))
        alert.addButton(withTitle: localizationService.localizedString(forKey: .buttonCopyResult))
        alert.addButton(withTitle: localizationService.localizedString(forKey: .buttonCancel))
        
        if let window = NSApplication.shared.windows.first {
            alert.beginSheetModal(for: window) { response in
                handleAlertResponse(response)
            }
        } else {
            let response = alert.runModal()
            handleAlertResponse(response)
        }
    }
    
    private func handleAlertResponse(_ response: NSApplication.ModalResponse) {
        switch response {
        case .alertFirstButtonReturn:
            showNotification(
                localizationService.localizedString(forKey: .notificationTranslationTest),
                localizationService.localizedString(forKey: .notificationTranslationConfirmed)
            )
        case .alertSecondButtonReturn:
            let translatedText = getTranslatedText()
            copyToClipboard(translatedText)
            showNotification(
                localizationService.localizedString(forKey: .notificationCopied),
                localizationService.localizedString(forKey: .notificationTranslationCopied)
            )
        default:
            break
        }
    }
    
    private func getTranslatedText() -> String {
        switch localizationService.currentLanguage {
        case .english:
            return "Hello World"
        case .chinese:
            return "你好世界"
        case .spanish:
            return "Hola Mundo"
        case .hindi:
            return "नमस्ते दुनिया"
        case .arabic:
            return "مرحبا بالعالم"
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func showNotification(_ title: String, _ message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var localizationService: LocalizationService
    @State private var selectedLanguage: SupportedLanguage = .english
    
    var body: some View {
        VStack(spacing: 20) {
            Text(localizationService.localizedString(forKey: .settingsTitle))
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Picker(localizationService.localizedString(forKey: .settingsAppLanguage), selection: $selectedLanguage) {
                ForEach(SupportedLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.radioGroup)
            
            Button(localizationService.localizedString(forKey: .buttonDone)) {
                localizationService.setLanguage(selectedLanguage)
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
        .frame(width: 360, height: 320)
        .onAppear {
            selectedLanguage = localizationService.currentLanguage
        }
    }
}
