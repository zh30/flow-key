import XCTest
@testable import FlowKey

@MainActor
final class LocalizationServiceTests: XCTestCase {
    func testDefaultLanguageLoadsSystemOrEnglish() {
        let service = LocalizationService(userDefaults: .standard)
        XCTAssertFalse(service.currentLanguageCode.isEmpty)
    }
    
    func testLanguageSwitchPersists() {
        let defaults = UserDefaults(suiteName: "LocalizationServiceTests")!
        defaults.removePersistentDomain(forName: "LocalizationServiceTests")
        defer { defaults.removePersistentDomain(forName: "LocalizationServiceTests") }
        
        let service = LocalizationService(userDefaults: defaults)
        service.setLanguage(.spanish)
        XCTAssertEqual(service.currentLanguage, .spanish)
        
        let serviceReloaded = LocalizationService(userDefaults: defaults)
        XCTAssertEqual(serviceReloaded.currentLanguage, .spanish)
    }
    
    func testLocalizedStringFallsBackToEnglish() {
        let service = LocalizationService(userDefaults: .standard)
        service.setLanguage(.arabic)
        let title = service.localizedString(forKey: .appTitle)
        XCTAssertFalse(title.isEmpty)
    }
}
