# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FlowKey is a macOS intelligent input method application built with Swift and SwiftUI. It provides real-time translation, voice recognition, and AI-powered text processing with support for 5 major languages (English, Chinese, Spanish, Hindi, Arabic).

## Development Commands

### Building and Running

```bash
# Development build
swift build

# Release build
swift build -c release

# Run the application
swift run

# Or use the provided script
./run_app.sh

# Build using the comprehensive build script
./build.sh

# Run tests
swift test

# Generate Xcode project
swift package generate-xcodeproj

# Update dependencies
swift package update
```

### Testing Scripts

```bash
# Test the application
./test_project.sh

# Test multilingual features
./test_multilingual.sh

# Test dialog fixes
./test_dialog_fix.sh
```

## Architecture Overview

### Core Components

1. **Input Method Core** (`Sources/FlowKey/InputMethod/`)
   - `FlowInputController.swift`: Handles user input and text processing
   - `FlowInputMethod.swift`: Main input method class and system registration

2. **Application Layer** (`Sources/FlowKey/App/`)
   - `SimpleFlowKeyApp.swift`: Simplified app entry point for testing
   - `FlowKeyApp.swift`: Full-featured application (complex dependencies commented out)

3. **Services** (`Sources/FlowKey/Services/`)
   - `LocalizationService.swift`: Multilingual support system with 5 languages

4. **Models** (`Sources/FlowKey/Models/`)
   - `Translation/`: Translation service implementations
   - `CoreData/`: Data persistence with Core Data
   - `KnowledgeBase/`: Vector database for semantic search
   - `VoiceCommands/`: Voice recognition and command processing

5. **Views** (`Sources/FlowKey/Views/`)
   - `Settings/`: Comprehensive settings interface with multiple subviews

### Current Implementation State

The project currently has a **simplified working version** that focuses on:
- Basic SwiftUI application interface
- Multilingual localization system (5 languages)
- Settings management
- Translation testing functionality

The full-featured version with AI integration (MLX, voice recognition, etc.) has dependencies commented out in `Package.swift` to allow for basic compilation and testing.

## Key Features

### Multilingual System
- **5 Supported Languages**: English, Chinese, Spanish, Hindi, Arabic
- **Real-time Language Switching**: Instant interface localization
- **User Preference Persistence**: Language settings saved to UserDefaults
- **Complete UI Translation**: All interface elements localized

### Architecture Patterns
- **MVVM Pattern**: SwiftUI views with ObservableObject services
- **Dependency Injection**: Services injected through environment objects
- **Localization Service**: Centralized string management with fallbacks
- **Settings System**: Modular settings with multiple configuration panels

## Project Structure

```
FlowKey/
├── Sources/FlowKey/
│   ├── App/                    # Application entry points
│   │   ├── SimpleFlowKeyApp.swift    # Simplified version (working)
│   │   └── FlowKeyApp.swift         # Full version (complex dependencies)
│   ├── InputMethod/           # IME core functionality
│   │   ├── FlowInputController.swift
│   │   └── FlowInputMethod.swift
│   ├── Services/              # Business logic
│   │   └── LocalizationService.swift
│   ├── Models/                # Data models and services
│   │   ├── Translation/
│   │   ├── CoreData/
│   │   ├── KnowledgeBase/
│   │   └── VoiceCommands/
│   ├── Views/                 # User interface
│   │   └── Settings/          # Settings subviews
│   └── Resources/             # Assets and resources
├── Sources/FlowKeyTests/      # Test suite
└── Documentation/             # Project documentation
```

## Development Guidelines

### Current Limitations
- The full AI features (MLX, voice recognition) are disabled due to dependency complexity
- The project currently runs a simplified version for testing the core interface
- Focus is on multilingual support and basic functionality

### When Adding Features
1. **Test with Simplified Version**: Ensure new features work with the current simplified implementation
2. **Follow Localization Patterns**: Use the `LocalizationService` for all user-facing text
3. **Maintain SwiftUI Patterns**: Use `@StateObject`, `@EnvironmentObject` for service injection
4. **Settings Integration**: Add new settings to the modular settings system

### Build Configuration
- **Package.swift**: Contains simplified dependencies for basic compilation
- **Build Scripts**: `build.sh` for comprehensive builds, `run_app.sh` for quick testing
- **Testing**: Multiple test scripts for different functionality areas

### Localization System
- Use `LocalizationKey` enum for all string keys
- Access strings through `LocalizationService` via `@EnvironmentObject`
- All 5 languages must be supported for new features
- Fallback to English for missing translations

## Important Files

- `Package.swift`: Build configuration with commented complex dependencies
- `Sources/FlowKey/App/SimpleFlowKeyApp.swift`: Current working application entry point
- `Sources/FlowKey/Services/LocalizationService.swift`: Complete multilingual system
- `build.sh`: Comprehensive build script for creating app bundles
- `run_app.sh`: Quick application launcher for development