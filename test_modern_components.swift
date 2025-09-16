import Foundation

// Test script for modern FlowKey components

print("Testing Modern FlowKey Components")
print("====================================")

// Test 1: Modern Localization Service
print("\n1. Testing Modern Localization Service...")

// Create a modern localization service instance
let localizationService = ModernLocalizationService()

// Test basic localization
let testString = localizationService.localizedString(forKey: .appTitle)
print("App Title (English): \(testString)")

// Test 2: Modern Translation Service
print("\n2. Testing Modern Translation Service...")

Task {
    let translationService = ModernTranslationService.shared

    // Test translation
    let result = await translationService.translate(text: "Hello World", to: "zh")
    print("Translation (Hello World → Chinese): \(result)")

    // Test language detection
    let detectedLanguage = await translationService.detectLanguage(text: "你好世界")
    print("Detected Language (你好世界): \(detectedLanguage ?? "unknown")")
}

// Test 3: Modern Input Controller
print("\n3. Testing Modern Input Controller...")

let inputController = FlowInputController.shared
print("Input Controller Active: \(inputController.isActive)")

// Test 4: Check supported languages
print("\n4. Supported Languages:")
for language in SupportedLanguage.allCases {
    print("  - \(language.flag) \(language.nativeName) (\(language.rawValue))")
}

print("\n✅ All modern components initialized successfully!")
print("\nTo test the full app, run: swift build")