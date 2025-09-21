import SwiftUI
import AppKit
import UserNotifications

// Modern ContentView with macOS 26 features
struct ModernContentView: View {
    @State private var showSettings = false
    @State private var selectedTab = 0
    @State private var showingTranslationTest = false
    @State private var copiedToClipboard = false
    @State private var pulseAnimation = false

    @EnvironmentObject var localizationService: LocalizationService
    @Environment(\.openWindow) private var openWindow

    // Modern input method controller
    @StateObject private var inputController = FlowInputController.shared

    var body: some View {
        VStack(spacing: 24) {
            headerView

            statusIndicatorView

            featuresView

            actionButtonsView

            Spacer()
        }
        .padding(24)
        .frame(width: 420, height: 650)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .primary.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .sheet(isPresented: $showSettings) {
            ModernSettingsView()
                .environmentObject(localizationService)
        }
        .alert("Translation Test", isPresented: $showingTranslationTest) {
            Button("OK") { }
            Button("Copy Result") {
                copyTranslationResult()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(localizationService.localizedString(forKey: .translationTestResult))
        }
        .overlay(
            // Modern floating action button for quick access
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    QuickAccessButton()
                }
                .padding()
            }
        )
        // Keyboard shortcuts could be reintroduced once the app targets the latest macOS APIs.
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Text(localizationService.localizedString(forKey: .appTitle))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Spacer()

                // Modern status indicator
                StatusPulseView(isActive: inputController.isActive)
            }

            Text("Intelligent Input Method for macOS")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var statusIndicatorView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(inputController.isActive ? Color.green : Color.orange)
                            .frame(width: 16, height: 16)
                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)

                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 20, height: 20)
                    }

                    Text(inputController.isActive ? "Active" : "Ready")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(localizationService.localizedString(forKey: .appStarted))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Version 2.0")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            pulseAnimation = true
        }
    }

    private var featuresView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationService.localizedString(forKey: .featuresTitle))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ModernFeatureCard(
                    icon: "globe",
                    title: localizationService.localizedString(forKey: .featureTranslation),
                    description: localizationService.localizedString(forKey: .featureTranslationDesc),
                    color: .blue
                )

                ModernFeatureCard(
                    icon: "mic",
                    title: localizationService.localizedString(forKey: .featureVoice),
                    description: localizationService.localizedString(forKey: .featureVoiceDesc),
                    color: .green
                )

                ModernFeatureCard(
                    icon: "brain",
                    title: localizationService.localizedString(forKey: .featureRecommendation),
                    description: localizationService.localizedString(forKey: .featureRecommendationDesc),
                    color: .purple
                )

                ModernFeatureCard(
                    icon: "book",
                    title: localizationService.localizedString(forKey: .featureKnowledge),
                    description: localizationService.localizedString(forKey: .featureKnowledgeDesc),
                    color: .orange
                )

                ModernFeatureCard(
                    icon: "cloud",
                    title: localizationService.localizedString(forKey: .featureSync),
                    description: localizationService.localizedString(forKey: .featureSyncDesc),
                    color: .cyan
                )

                ModernFeatureCard(
                    icon: "keyboard",
                    title: "Smart Input",
                    description: "Context-aware suggestions",
                    color: .indigo
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            Button(action: { showSettings = true }) {
                Label(localizationService.localizedString(forKey: .buttonOpenSettings), systemImage: "gear")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            HStack(spacing: 12) {
                Button(action: testTranslation) {
                    Label(localizationService.localizedString(forKey: .buttonTestTranslation), systemImage: "bubble.left")
                }
                .buttonStyle(.bordered)

                Button(action: toggleInputMethod) {
                    Label(inputController.isActive ? "Deactivate" : "Activate", systemImage: inputController.isActive ? "pause.circle" : "play.circle")
                }
                .buttonStyle(.bordered)
            }

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Label(localizationService.localizedString(forKey: .buttonExitApp), systemImage: "power")
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
        }
    }

    private func testTranslation() {
        showingTranslationTest = true
    }

    private func copyTranslationResult() {
        let translatedText = getTranslatedText()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(translatedText, forType: .string)

        copiedToClipboard = true

        // Show notification using modern UNUserNotificationCenter
        let content = UNMutableNotificationContent()
        content.title = localizationService.localizedString(forKey: .notificationCopied)
        content.body = localizationService.localizedString(forKey: .notificationTranslationCopied)
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

        // Reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            copiedToClipboard = false
        }
    }

    private func getTranslatedText() -> String {
        switch localizationService.currentLanguage {
        case .english: return "Hello World"
        case .chinese: return "你好世界"
        case .spanish: return "Hola Mundo"
        case .hindi: return "नमस्ते दुनिया"
        case .arabic: return "مرحبا بالعالم"
        }
    }

    private func toggleInputMethod() {
        if inputController.isActive {
            inputController.deactivateInputMethod()
        } else {
            inputController.activateInputMethod()
        }
    }
}

// MARK: - Modern Supporting Views

struct ModernFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32, height: 32)

            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? color.opacity(0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isHovered ? color : Color.gray.opacity(0.2), lineWidth: isHovered ? 2 : 1)
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct StatusPulseView: View {
    let isActive: Bool

    @State private var pulseScale = 1.0

    var body: some View {
        ZStack {
            Circle()
                .fill(isActive ? Color.green : Color.orange)
                .frame(width: 12, height: 12)
                .scaleEffect(pulseScale)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseScale)
        }
        .onAppear {
            pulseScale = 1.0
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
            }
        }
    }
}

struct QuickAccessButton: View {
    @State private var isHovered = false

    var body: some View {
        Button(action: {
            // Quick access action
        }) {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: .primary.opacity(0.2), radius: 4, x: 0, y: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isHovered ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}