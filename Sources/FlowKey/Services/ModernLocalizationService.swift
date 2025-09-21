import Foundation
import SwiftUI

@MainActor
final class ModernLocalizationService: ObservableObject {
    @Published private(set) var currentLanguage: SupportedLanguage
    @Published private(set) var currentLanguageCode: String
    @Published private(set) var isRTL: Bool
    
    private let baseService: LocalizationService
    
    init(baseService: LocalizationService = LocalizationService()) {
        self.baseService = baseService
        self.currentLanguage = baseService.currentLanguage
        self.currentLanguageCode = baseService.currentLanguageCode
        self.isRTL = baseService.currentLanguage.isRTL
    }
    
    func refresh() {
        currentLanguage = baseService.currentLanguage
        currentLanguageCode = baseService.currentLanguageCode
        isRTL = currentLanguage.isRTL
    }
    
    func setLanguage(_ language: SupportedLanguage) {
        baseService.setLanguage(language)
        refresh()
        NotificationCenter.default.post(name: .languageDidChange, object: language)
    }
    
    func localizedString(forKey key: LocalizationKey) -> String {
        baseService.localizedString(forKey: key)
    }
    
    func localizedFormat(_ key: LocalizationKey, _ arguments: CVarArg...) -> String {
        String(format: localizedString(forKey: key), arguments: arguments)
    }
    
    func localizedPlural(_ key: LocalizationKey, count: Int) -> String {
        String.localizedStringWithFormat(localizedString(forKey: key), count)
    }
    
    @discardableResult
    func callAsFunction(_ key: LocalizationKey) -> String {
        localizedString(forKey: key)
    }
}

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

@MainActor
struct ModernLocalizationProxy {
    let service: ModernLocalizationService
    
    init(service: ModernLocalizationService = ModernLocalizationService()) {
        self.service = service
    }
    
    func callAsFunction(_ key: LocalizationKey) -> String {
        service.localizedString(forKey: key)
    }
    
    func callAsFunction(_ key: LocalizationKey, _ arguments: CVarArg...) -> String {
        service.localizedFormat(key, arguments...)
    }
}
