import SwiftUI
import Foundation

// Legacy simplified app - maintained for compatibility
@main
struct SimpleFlowKeyApp: App {
    @StateObject private var localizationService = LocalizationService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(localizationService)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 400, height: 600)
    }
}

struct ContentView: View {
    @State private var showSettings = false
    @State private var selectedTab = 0
    @EnvironmentObject var localizationService: LocalizationService
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text(localizationService.localizedString(forKey: .appTitle))
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            // 状态指示器
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
            
            // 功能列表
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
            
            // 操作按钮
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
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 600)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(localizationService)
        }
    }
    
    private func testTranslation() {
        let alert = NSAlert()
        alert.messageText = localizationService.localizedString(forKey: .translationTest)
        alert.informativeText = localizationService.localizedString(forKey: .translationTestResult)
        alert.alertStyle = .informational
        
        // 添加多个按钮以测试交互
        alert.addButton(withTitle: localizationService.localizedString(forKey: .buttonOK))
        alert.addButton(withTitle: localizationService.localizedString(forKey: .buttonCopyResult))
        alert.addButton(withTitle: localizationService.localizedString(forKey: .buttonCancel))
        
        if let window = NSApplication.shared.windows.first {
            // 使用 sheet 模式显示弹窗
            alert.beginSheetModal(for: window) { response in
                switch response {
                case .alertFirstButtonReturn:
                    // 确定 按钮
                    print("用户点击了确定")
                    self.showNotification(
                        localizationService.localizedString(forKey: .notificationTranslationTest),
                        localizationService.localizedString(forKey: .notificationTranslationConfirmed)
                    )
                case .alertSecondButtonReturn:
                    // 复制结果 按钮
                    print("用户点击了复制结果")
                    let translatedText = getTranslatedText()
                    self.copyToClipboard(translatedText)
                    self.showNotification(
                        localizationService.localizedString(forKey: .notificationCopied),
                        localizationService.localizedString(forKey: .notificationTranslationCopied)
                    )
                case .alertThirdButtonReturn:
                    // 取消 按钮
                    print("用户点击了取消")
                default:
                    break
                }
            }
        } else {
            // 备选方案：使用模态弹窗
            let response = alert.runModal()
            self.handleAlertResponse(response)
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
    
    private func handleAlertResponse(_ response: NSApplication.ModalResponse) {
        switch response {
        case .alertFirstButtonReturn:
            print("用户点击了确定")
            self.showNotification(
                localizationService.localizedString(forKey: .notificationTranslationTest),
                localizationService.localizedString(forKey: .notificationTranslationConfirmed)
            )
        case .alertSecondButtonReturn:
            print("用户点击了复制结果")
            let translatedText = getTranslatedText()
            self.copyToClipboard(translatedText)
            self.showNotification(
                localizationService.localizedString(forKey: .notificationCopied),
                localizationService.localizedString(forKey: .notificationTranslationCopied)
            )
        case .alertThirdButtonReturn:
            print("用户点击了取消")
        default:
            break
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func showNotification(_ title: String, _ message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
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
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var localizationService: LocalizationService
    @State private var launchAtLogin = false
    @State private var showInMenuBar = true
    @State private var autoCheckUpdates = true
    @State private var selectedLanguage: SupportedLanguage = .english
    
    var body: some View {
        VStack(spacing: 20) {
            Text(localizationService.localizedString(forKey: .settingsTitle))
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            Form {
                Section(localizationService.localizedString(forKey: .settingsGeneral)) {
                    Toggle(localizationService.localizedString(forKey: .settingsLaunchAtLogin), isOn: $launchAtLogin)
                    Toggle(localizationService.localizedString(forKey: .settingsShowInMenuBar), isOn: $showInMenuBar)
                    Toggle(localizationService.localizedString(forKey: .settingsAutoCheckUpdates), isOn: $autoCheckUpdates)
                }
                
                Section(localizationService.localizedString(forKey: .settingsAppLanguage)) {
                    Picker(selection: $selectedLanguage, label: Text(localizationService.localizedString(forKey: .settingsAppLanguage))) {
                        ForEach(SupportedLanguage.allCases) { language in
                            HStack {
                                Text(language.flag)
                                Text(language.nativeName)
                            }
                            .tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedLanguage) { newLanguage in
                        localizationService.setLanguage(newLanguage)
                    }
                    .onAppear {
                        selectedLanguage = localizationService.currentLanguage
                    }
                }
                
                Section(localizationService.localizedString(forKey: .settingsTranslation)) {
                    HStack {
                        Text(localizationService.localizedString(forKey: .settingsSourceLanguage))
                        Spacer()
                        Text(localizationService.localizedString(forKey: .settingsAutoDetect))
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text(localizationService.localizedString(forKey: .settingsTargetLanguage))
                        Spacer()
                        Text(getTargetLanguageName())
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(localizationService.localizedString(forKey: .settingsAbout)) {
                    HStack {
                        Text(localizationService.localizedString(forKey: .settingsVersion))
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text(localizationService.localizedString(forKey: .settingsBuildTime))
                        Spacer()
                        Text(Date().formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            
            Spacer()
            
            Button(localizationService.localizedString(forKey: .buttonDone)) {
                presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 20)
        }
        .frame(width: 500, height: 600)
        .padding()
    }
    
    private func getTargetLanguageName() -> String {
        switch localizationService.currentLanguage {
        case .english:
            return "Chinese"
        case .chinese:
            return "英语"
        case .spanish:
            return "Inglés"
        case .hindi:
            return "अंग्रेजी"
        case .arabic:
            return "الإنجليزية"
        }
    }
}

// 为 macOS 应用程序提供必要的扩展
extension NSApplication {
    static func sharedApp() -> NSApplication {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        return app
    }
}