[English](README.md) | [简体中文](README.zh-CN.md)

# FlowKey — Intelligent Input Method for macOS

A macOS input method application that integrates local AI services, offering selection translation, smart rewriting, and voice dictation.

## Features

### Core
- ✅ Selection translation: translate any selected text instantly
- ✅ Quick translate: triple-press Space to translate current input
- ✅ Local-first: on-device translation models for privacy
- ✅ Multilingual: Chinese, English, Japanese, Korean, French, German, Russian

### AI Capabilities
- 🚧 Offline translation with MLX
- 🚧 Speech recognition powered by Whisper
- 🚧 Smart rewrite for text optimization
- 🚧 Knowledge base with semantic search

### User Experience
- ✅ Clean UI built with SwiftUI
- ✅ Deep macOS integration
- ✅ iCloud sync across devices
- ✅ Privacy-first, on-device processing

## Architecture

### Tech Stack
- Swift + SwiftUI: native macOS app development
- MLX Swift: local AI inference optimized for Apple Silicon
- IMKInputMethod: official macOS input method framework
- Composable Architecture: state management
- Core Data: local persistence

### Project Structure
```
FlowKey/
├── FlowKey/                    # Main app
│   ├── InputMethod/           # IME core
│   ├── Models/                # Data models
│   ├── Services/              # Services layer
│   ├── Views/                 # UI
│   └── App/                   # App entry
├── FlowKeyTests/              # Tests
├── FlowKeyInputMethod/        # Input Method extension
└── Documentation/             # Docs
```

## Getting Started

### Requirements
- macOS 13.0 or later
- Xcode 14.0 or later
- Swift 5.9 or later

### Build

1. Clone the repo:
```bash
git clone <repository-url>
cd flow-key
```

2. Build the app:
```bash
./build.sh
```

3. Install the app and input method:
```bash
# Copy the app to Applications
cp -r build/FlowKey.app /Applications/

# Install the input method
mkdir -p ~/Library/Input\ Methods/
cp -r build/FlowKeyInputMethod.bundle ~/Library/Input\ Methods/
```

4. Enable the input method:
   - Open System Settings > Keyboard > Input Sources
   - Click "+" to add an input source
   - Select "FlowKey" and enable it

## Usage

### Basic Translation
1. Select text in any application
2. The translation will appear automatically
3. Click the copy button to save the result

### Quick Translate
- Triple-press Space: translate the current selection
- Cmd+Shift+T: manually trigger translation

### Voice Input
- Enable voice features in Settings
- Click the microphone button to start recording
- Speech will be recognized and translated automatically

### Knowledge Base
- Import your documents into the knowledge base
- Use semantic search to find information
- Supports multiple document formats

## Development Guide

### Modules Overview

#### InputMethod/
- `FlowInputController.swift`: Handles user input
- `FlowInputMethod.swift`: Main class and system registration
- `FlowCandidateView.swift`: Candidate view

#### Models/
- `Translation/`: Translation-related models and services
- `KnowledgeBase/`: Knowledge base management
- `Speech/`: Speech recognition and processing

#### Services/
- `AIService.swift`: Unified AI service interface
- `MLXService.swift`: MLX integration
- `StorageService.swift`: Data storage service
- `SyncService.swift`: iCloud sync service

#### Views/
- `Settings/`: Settings UI
- `Overlay/`: Overlay UI

### Development Workflow

1. Environment setup
   ```bash
   # Install dependencies
   swift package update
   
   # Generate Xcode project
   swift package generate-xcodeproj
   ```

2. Development
   ```bash
   # Run the app
   swift run
   
   # Run tests
   swift test
   ```

3. Build
   ```bash
   # Build release
   swift build -c release
   ```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Open a Pull Request

## FAQ

### Q: The input method cannot be enabled?
A: Ensure it has been copied to `~/Library/Input Methods/` and enabled in System Settings.

### Q: Translation does not work?
A: Check your network connection or make sure the local translation model is downloaded.

### Q: Speech recognition fails?
A: Ensure microphone permission is granted and the speech model is downloaded.

## Changelog

### v1.0.0 (2025-08-23)
- ✅ Base input method framework
- ✅ Selection translation
- ✅ Online translation API integration
- ✅ Basic UI
- ✅ Settings page

### Roadmap
- 🚧 Local AI model integration
- 🚧 Speech recognition
- 🚧 Knowledge base system
- 🚧 iCloud sync
- 🚧 More language support

## License
This project is under the MIT License. See [LICENSE](LICENSE).

## Contact
- Issue tracking: [GitHub Issues](https://github.com/zh30/flow-key/issues)
- Feature requests: [GitHub Discussions](https://github.com/zh30/flow-key/discussions)
- Email: support@flowkey.app

---

FlowKey — Type smarter. Communicate better.