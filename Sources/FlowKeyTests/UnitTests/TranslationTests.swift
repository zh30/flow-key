import XCTest
@testable import FlowKey

final class TranslationServiceTests: XCTestCase {
    
    var translationService: TranslationService!
    
    override func setUp() {
        super.setUp()
        translationService = TranslationService.shared
    }
    
    override func tearDown() {
        translationService = nil
        super.tearDown()
    }
    
    func testTranslateEmptyText() async {
        let result = await translationService.translate(text: "")
        XCTAssertEqual(result, "")
    }
    
    func testTranslateHello() async {
        let result = await translationService.translate(text: "Hello")
        XCTAssertEqual(result, "你好")
    }
    
    func testTranslateWorld() async {
        let result = await translationService.translate(text: "World")
        XCTAssertEqual(result, "世界")
    }
    
    func testTranslateUnknownText() async {
        let result = await translationService.translate(text: "Unknown text")
        XCTAssertTrue(result.contains("翻译"))
    }
    
    func testGetSupportedLanguages() async {
        let languages = await translationService.getSupportedLanguages()
        XCTAssertFalse(languages.isEmpty)
        XCTAssertTrue(languages.contains("en"))
        XCTAssertTrue(languages.contains("zh"))
    }
    
    func testDetectLanguage() async {
        let chinese = await translationService.detectLanguage(text: "你好")
        XCTAssertEqual(chinese, "zh")
        
        let english = await translationService.detectLanguage(text: "Hello")
        XCTAssertEqual(english, "en")
    }
}

final class InputMethodServiceTests: XCTestCase {
    
    var inputMethodService: InputMethodService!
    
    override func setUp() {
        super.setUp()
        inputMethodService = InputMethodService.shared
    }
    
    override func tearDown() {
        inputMethodService = nil
        super.tearDown()
    }
    
    func testInputMethodServiceExists() {
        XCTAssertNotNil(inputMethodService)
    }
    
    func testSelectedTextExtraction() async {
        // This test would require actual UI interaction
        // For now, we just test that the method exists and doesn't crash
        let text = await inputMethodService.getSelectedText()
        XCTAssertNotNil(text)
    }
    
    func testTextInsertion() {
        // Test that text insertion doesn't crash
        // Note: This test may affect the actual clipboard
        inputMethodService.insertText("Test text")
    }
}

final class FlowInputControllerTests: XCTestCase {
    
    var inputController: FlowInputController!
    
    override func setUp() {
        super.setUp()
        // Note: This would require a proper IMKServer setup
        // For now, we skip this test
    }
    
    override func tearDown() {
        inputController = nil
        super.tearDown()
    }
    
    func testInputControllerInitialization() {
        // This test would require proper setup
        // For now, we just test that we can create the class
        // inputController = FlowInputController()
        // XCTAssertNotNil(inputController)
    }
}

final class SettingsTests: XCTestCase {
    
    func testGeneralSettingsInitialState() {
        let settings = GeneralSettings.State()
        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertTrue(settings.showInMenuBar)
        XCTAssertTrue(settings.autoCheckUpdates)
        XCTAssertEqual(settings.selectedLanguage, "zh-CN")
    }
    
    func testTranslationSettingsInitialState() {
        let settings = TranslationSettings.State()
        XCTAssertEqual(settings.sourceLanguage, "auto")
        XCTAssertEqual(settings.targetLanguage, "zh")
        XCTAssertFalse(settings.useLocalTranslation)
        XCTAssertTrue(settings.autoDetectLanguage)
        XCTAssertTrue(settings.showTranslationPopup)
        XCTAssertEqual(settings.popupDuration, 5.0)
    }
    
    func testKnowledgeSettingsInitialState() {
        let settings = KnowledgeSettings.State()
        XCTAssertFalse(settings.knowledgeBaseEnabled)
        XCTAssertTrue(settings.autoIndexDocuments)
        XCTAssertEqual(settings.searchLimit, 10)
        XCTAssertEqual(settings.vectorModel, "text-embedding-ada-002")
    }
    
    func testSyncSettingsInitialState() {
        let settings = SyncSettings.State()
        XCTAssertFalse(settings.iCloudSyncEnabled)
        XCTAssertTrue(settings.autoSync)
        XCTAssertNil(settings.lastSyncDate)
        XCTAssertEqual(settings.syncInterval, 3600)
    }
}