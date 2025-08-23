[English](README.md) | [简体中文](README.zh-CN.md) | [Español](README.es.md) | [हिन्दी](README.hi.md) | [العربية](README.ar.md)

# FlowKey — Intelligent Input Method for macOS

A cutting-edge macOS input method application that integrates local AI services, offering real-time translation, voice recognition, and intelligent text processing in 5 major languages.

## 🌍 Multilingual Support

FlowKey supports 5 of the world's most widely used languages:

- 🇺🇸 **English** (Default)
- 🇨🇳 **中文** (Chinese)
- 🇪🇸 **Español** (Spanish)
- 🇮🇳 **हिन्दी** (Hindi)
- 🇸🇦 **العربية** (Arabic)

## ✨ Key Features

### Core Translation
- ✅ **Selection Translation**: Instant translation of any selected text
- ✅ **Quick Translate**: Triple-press Space for immediate translation
- ✅ **Local-First**: On-device AI models ensure complete privacy
- ✅ **5 Languages**: Seamless switching between major world languages

### AI Capabilities
- 🚧 **Offline Translation**: MLX-powered local AI inference
- 🚧 **Speech Recognition**: Whisper-based voice dictation
- 🚧 **Smart Rewrite**: AI-powered text optimization
- 🚧 **Knowledge Base**: Semantic search with personal documents

### User Experience
- ✅ **Native UI**: Clean SwiftUI interface with full localization
- ✅ **Deep Integration**: Native macOS system integration
- ✅ **Real-time Switching**: Instant language switching
- ✅ **Privacy-First**: All processing happens on your device

## 🏗️ Architecture

### Technology Stack
- **Swift + SwiftUI**: Native macOS development
- **MLX Swift**: Local AI inference optimized for Apple Silicon
- **IMKInputMethod**: Official macOS input method framework
- **Core Data**: Robust local data persistence
- **iCloud Sync**: Seamless cross-device synchronization

### Project Structure
```
FlowKey/
├── Sources/FlowKey/
│   ├── App/                    # Application entry point
│   ├── InputMethod/           # IME core functionality
│   ├── Models/                # Data models and services
│   ├── Services/              # Business logic layer
│   ├── Views/                 # User interface
│   └── Resources/             # Assets and resources
├── Sources/FlowKeyTests/      # Test suite
└── Documentation/             # Project documentation
```

## 🚀 Getting Started

### Requirements
- macOS 14.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later
- Apple Silicon Mac recommended for AI features

### Quick Start

1. **Clone the repository**
```bash
git clone <repository-url>
cd flow-key
```

2. **Build the application**
```bash
# Development build
swift build

# Release build
swift build -c release
```

3. **Run the application**
```bash
# Development mode
swift run

# Or use the build script
./run_app.sh
```

### Installation

1. **Copy to Applications**
```bash
cp -r .build/debug/FlowKey.app /Applications/
```

2. **Enable Input Method**
   - Open System Settings > Keyboard > Input Sources
   - Click "+" to add new input source
   - Select "FlowKey" from the list
   - Enable it in your input sources

## 🎯 Usage Guide

### Basic Translation
1. Select text in any application
2. Translation appears automatically in the overlay
3. Use the copy button to save results

### Quick Actions
- **Triple-press Space**: Instant translation of current selection
- **Cmd+Shift+T**: Manual translation trigger
- **Cmd+Shift+V**: Voice input activation

### Voice Features
1. Enable voice recognition in Settings
2. Click the microphone button or use voice shortcut
3. Speak naturally - text is transcribed and translated
4. Results appear instantly with copy options

### Language Switching
1. Open FlowKey Settings
2. Navigate to "App Language" section
3. Select your preferred language from the dropdown
4. Interface updates immediately with full localization

## 🔧 Development

### Development Setup
```bash
# Install dependencies
swift package update

# Generate Xcode project
swift package generate-xcodeproj

# Run tests
swift test

# Build for release
swift build -c release
```

### Key Components

#### Input Method Core
- `FlowInputController.swift`: Handles user input and text processing
- `FlowInputMethod.swift`: Main input method class and system registration
- `FlowCandidateView.swift`: Candidate selection interface

#### AI Services
- `MLXService.swift`: Local AI model integration
- `AIService.swift`: Unified AI service interface
- `SpeechRecognizer.swift`: Voice recognition capabilities

#### Localization
- `LocalizationService.swift`: Multilingual support system
- Supports 5 major languages with real-time switching
- Complete UI localization with user preference persistence

### Building for Distribution
```bash
# Build release version
swift build -c release

# Create app bundle
mkdir -p FlowKey.app/Contents/MacOS
cp .build/release/FlowKey FlowKey.app/Contents/MacOS/

# Sign the app (required for distribution)
codesign --deep --force --verify --verbose --sign "-" FlowKey.app
```

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Commit your changes** (`git commit -m 'Add amazing feature'`)
4. **Push to the branch** (`git push origin feature/amazing-feature`)
5. **Open a Pull Request**

### Development Guidelines
- Follow Swift coding conventions
- Add tests for new features
- Update documentation
- Ensure all tests pass before submitting

## ❓ FAQ

### Q: How do I enable the input method?
A: Copy the app to Applications folder, then go to System Settings > Keyboard > Input Sources, click "+" and select "FlowKey".

### Q: Translation isn't working?
A: Check your internet connection for online translation, or ensure local AI models are downloaded for offline mode.

### Q: Voice recognition isn't working?
A: Grant microphone permissions in System Settings > Privacy & Security > Microphone, and ensure speech models are downloaded.

### Q: How do I change the interface language?
A: Open FlowKey Settings, go to "App Language", and select your preferred language from the dropdown menu.

## 📋 Changelog

### v1.0.0 (2025-08-23)
- ✅ Complete multilingual support (5 languages)
- ✅ Real-time language switching
- ✅ Local AI model integration framework
- ✅ Selection translation with overlay UI
- ✅ Voice recognition foundation
- ✅ Privacy-first architecture
- ✅ iCloud sync capabilities

### Roadmap
- 🚧 Advanced offline AI models
- 🚧 Enhanced voice recognition
- 🚧 Knowledge base with semantic search
- 🚧 Smart text rewriting
- 🚧 More language support

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## 📞 Contact

- **Issues**: [GitHub Issues](https://github.com/zh30/flow-key/issues)
- **Discussions**: [GitHub Discussions](https://github.com/zh30/flow-key/discussions)
- **Email**: support@flowkey.app
- **Website**: [flowkey.app](https://flowkey.app)

---

**FlowKey** — Type smarter. Communicate better. 🚀