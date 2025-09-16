import Foundation
import SwiftUI
import Observation

// Modern Localization Service with Swift 6 features and Observation framework
@Observable
@MainActor
public class ModernLocalizationService {
    public var currentLanguage: SupportedLanguage = .english
    public var currentLanguageCode: String = "en"
    public var isRTL: Bool = false

    private let userDefaults = UserDefaults.standard
    private let languageKey = "selected_language"

    // Modern async/await initialization
    public init() {
        Task {
            await loadSavedLanguage()
        }
    }

    // Modern async method for loading language
    private func loadSavedLanguage() async {
        // Check for saved language
        if let savedLanguageCode = userDefaults.string(forKey: languageKey),
           let savedLanguage = SupportedLanguage(rawValue: savedLanguageCode) {
            currentLanguage = savedLanguage
            currentLanguageCode = savedLanguageCode
            isRTL = savedLanguage.isRTL
        } else {
            // Use modern locale detection
            let detectedLanguage = await detectSystemLanguage()
            currentLanguage = detectedLanguage
            currentLanguageCode = detectedLanguage.rawValue
            isRTL = detectedLanguage.isRTL
        }

        // Notify observers of language change
        objectWillChange.send()
    }

    // Modern system language detection
    private func detectSystemLanguage() async -> SupportedLanguage {
        let systemLanguageCode: String

        // Use modern Locale API
        if #available(macOS 13, *) {
            systemLanguageCode = Locale.current.language.languageCode?.identifier ?? "en"
        } else {
            systemLanguageCode = Locale.current.languageCode ?? "en"
        }

        // Try to find matching language
        if let supportedLanguage = SupportedLanguage(rawValue: systemLanguageCode) {
            return supportedLanguage
        }

        // Fallback to English
        return .english
    }

    // Modern language setting with async support
    public func setLanguage(_ language: SupportedLanguage) async {
        currentLanguage = language
        currentLanguageCode = language.rawValue
        isRTL = language.isRTL

        // Save to UserDefaults
        userDefaults.set(language.rawValue, forKey: languageKey)

        // Notify observers
        objectWillChange.send()

        // Optional: Notify other parts of the app
        await NotificationCenter.default.post(
            name: .languageDidChange,
            object: language
        )
    }

    // Modern localized string method with fallback chain
    public func localizedString(forKey key: LocalizationKey) -> String {
        // Try current language first
        if let currentLanguageStrings = localizedStrings[currentLanguage],
           let localizedString = currentLanguageStrings[key.rawValue] {
            return localizedString
        }

        // Fallback to English
        if let englishStrings = localizedStrings[.english],
           let englishString = englishStrings[key.rawValue] {
            return englishString
        }

        // Final fallback: return the key itself
        return key.rawValue
    }

    // Modern async localization for dynamic content
    public func localizeAsync(_ key: LocalizationKey) async -> String {
        // This could be extended to fetch from a server or cache
        return localizedString(forKey: key)
    }

    // Modern format string support
    public func localizedFormat(_ key: LocalizationKey, _ arguments: CVarArg...) -> String {
        let formatString = localizedString(forKey: key)
        return String(format: formatString, arguments: arguments)
    }

    // Modern pluralization support
    public func localizedPlural(_ key: LocalizationKey, count: Int) -> String {
        let formatString = localizedString(forKey: key)
        return String.localizedStringWithFormat(formatString, count)
    }

    // MARK: - Modern Localized Strings

    // Updated localized strings with modern formatting
    private let localizedStrings: [SupportedLanguage: [String: String]] = [
        .english: [
            "app.title": "FlowKey Smart Input Method",
            "app.started": "App Started",
            "features.title": "Core Features",
            "feature.translation": "Text Translation",
            "feature.translation.desc": "Select text to translate",
            "feature.voice": "Voice Recognition",
            "feature.voice.desc": "Support voice input and commands",
            "feature.recommendation": "Smart Recommendations",
            "feature.recommendation.desc": "Context-aware intelligent suggestions",
            "feature.knowledge": "Knowledge Base",
            "feature.knowledge.desc": "Personal knowledge management system",
            "feature.sync": "Cloud Sync",
            "feature.sync.desc": "iCloud data synchronization",
            "button.open.settings": "Open Settings",
            "button.test.translation": "Test Translation",
            "button.exit.app": "Exit App",
            "button.done": "Done",
            "button.ok": "OK",
            "button.cancel": "Cancel",
            "button.copy.result": "Copy Result",
            "settings.title": "Settings",
            "settings.general": "General Settings",
            "settings.launch.at.login": "Launch at Login",
            "settings.show.in.menubar": "Show in Menu Bar",
            "settings.auto.check.updates": "Auto Check Updates",
            "settings.translation": "Translation Settings",
            "settings.source.language": "Source Language",
            "settings.target.language": "Target Language",
            "settings.auto.detect": "Auto Detect",
            "settings.app.language": "App Language",
            "settings.about": "About",
            "settings.version": "Version",
            "settings.build.time": "Build Time",
            "translation.test": "Translation Test",
            "translation.test.result": "Hello World → Hello World",
            "translation.confirmed": "Translation confirmed",
            "translation.copied": "Copied",
            "translation.copied.to.clipboard": "Translation result copied to clipboard",
            "notification.translation.test": "Translation Test",
            "notification.translation.confirmed": "Translation confirmed",
            "notification.copied": "Copied",
            "notification.translation.copied": "Translation result copied to clipboard",
            // New modern strings
            "status.active": "Active",
            "status.ready": "Ready",
            "status.inactive": "Inactive",
            "quick.access": "Quick Access",
            "smart.input": "Smart Input",
            "context.aware": "Context-aware suggestions",
            "reset.settings": "Reset Settings",
            "export.settings": "Export Settings",
            "import.settings": "Import Settings",
            "settings.saved": "Settings Saved",
            "language.changed": "Language Changed",
            "feature.ai.powered": "AI-Powered Features",
            "feature.real.time": "Real-time Processing",
            "feature.privacy.focused": "Privacy-Focused"
        ],
        .chinese: [
            "app.title": "FlowKey 智能输入法",
            "app.started": "应用已启动",
            "features.title": "核心功能",
            "feature.translation": "划词翻译",
            "feature.translation.desc": "选中文本即可翻译",
            "feature.voice": "语音识别",
            "feature.voice.desc": "支持语音输入和命令",
            "feature.recommendation": "智能推荐",
            "feature.recommendation.desc": "基于上下文的智能建议",
            "feature.knowledge": "知识库",
            "feature.knowledge.desc": "个人知识管理系统",
            "feature.sync": "云同步",
            "feature.sync.desc": "iCloud 数据同步",
            "button.open.settings": "打开设置",
            "button.test.translation": "测试翻译功能",
            "button.exit.app": "退出应用",
            "button.done": "完成",
            "button.ok": "确定",
            "button.cancel": "取消",
            "button.copy.result": "复制结果",
            "settings.title": "设置",
            "settings.general": "通用设置",
            "settings.launch.at.login": "开机自启动",
            "settings.show.in.menubar": "显示在菜单栏",
            "settings.auto.check.updates": "自动检查更新",
            "settings.translation": "翻译设置",
            "settings.source.language": "源语言",
            "settings.target.language": "目标语言",
            "settings.auto.detect": "自动检测",
            "settings.app.language": "应用语言",
            "settings.about": "关于",
            "settings.version": "版本",
            "settings.build.time": "构建时间",
            "translation.test": "翻译测试",
            "translation.test.result": "Hello World → 你好世界",
            "translation.confirmed": "已确认翻译结果",
            "translation.copied": "已复制",
            "translation.copied.to.clipboard": "翻译结果已复制到剪贴板",
            "notification.translation.test": "翻译测试",
            "notification.translation.confirmed": "已确认翻译结果",
            "notification.copied": "已复制",
            "notification.translation.copied": "翻译结果已复制到剪贴板",
            // New modern strings
            "status.active": "激活",
            "status.ready": "就绪",
            "status.inactive": "未激活",
            "quick.access": "快速访问",
            "smart.input": "智能输入",
            "context.aware": "上下文感知建议",
            "reset.settings": "重置设置",
            "export.settings": "导出设置",
            "import.settings": "导入设置",
            "settings.saved": "设置已保存",
            "language.changed": "语言已更改",
            "feature.ai.powered": "AI 驱动功能",
            "feature.real.time": "实时处理",
            "feature.privacy.focused": "注重隐私"
        ],
        .spanish: [
            "app.title": "FlowKey Método de Entrada Inteligente",
            "app.started": "Aplicación Iniciada",
            "features.title": "Características Principales",
            "feature.translation": "Traducción de Texto",
            "feature.translation.desc": "Selecciona texto para traducir",
            "feature.voice": "Reconocimiento de Voz",
            "feature.voice.desc": "Soporte de entrada de voz y comandos",
            "feature.recommendation": "Recomendaciones Inteligentes",
            "feature.recommendation.desc": "Sugerencias inteligentes conscientes del contexto",
            "feature.knowledge": "Base de Conocimiento",
            "feature.knowledge.desc": "Sistema de gestión de conocimiento personal",
            "feature.sync": "Sincronización en la Nube",
            "feature.sync.desc": "Sincronización de datos iCloud",
            "button.open.settings": "Abrir Configuración",
            "button.test.translation": "Probar Traducción",
            "button.exit.app": "Salir de la Aplicación",
            "button.done": "Hecho",
            "button.ok": "OK",
            "button.cancel": "Cancelar",
            "button.copy.result": "Copiar Resultado",
            "settings.title": "Configuración",
            "settings.general": "Configuración General",
            "settings.launch.at.login": "Iniciar al Iniciar Sesión",
            "settings.show.in.menubar": "Mostrar en la Barra de Menú",
            "settings.auto.check.updates": "Verificar Actualizaciones Automáticamente",
            "settings.translation": "Configuración de Traducción",
            "settings.source.language": "Idioma de Origen",
            "settings.target.language": "Idioma de Destino",
            "settings.auto.detect": "Detección Automática",
            "settings.app.language": "Idioma de la Aplicación",
            "settings.about": "Acerca de",
            "settings.version": "Versión",
            "settings.build.time": "Tiempo de Construcción",
            "translation.test": "Prueba de Traducción",
            "translation.test.result": "Hello World → Hola Mundo",
            "translation.confirmed": "Traducción confirmada",
            "translation.copied": "Copiado",
            "translation.copied.to.clipboard": "Resultado de traducción copiado al portapapeles",
            "notification.translation.test": "Prueba de Traducción",
            "notification.translation.confirmed": "Traducción confirmada",
            "notification.copied": "Copiado",
            "notification.translation.copied": "Resultado de traducción copiado al portapapeles",
            // New modern strings
            "status.active": "Activo",
            "status.ready": "Listo",
            "status.inactive": "Inactivo",
            "quick.access": "Acceso Rápido",
            "smart.input": "Entrada Inteligente",
            "context.aware": "Sugerencias conscientes del contexto",
            "reset.settings": "Restablecer Configuración",
            "export.settings": "Exportar Configuración",
            "import.settings": "Importar Configuración",
            "settings.saved": "Configuración Guardada",
            "language.changed": "Idioma Cambiado",
            "feature.ai.powered": "Características con IA",
            "feature.real.time": "Procesamiento en Tiempo Real",
            "feature.privacy.focused": "Enfoque en Privacidad"
        ],
        .hindi: [
            "app.title": "FlowKey स्मार्ट इनपुट मेथड",
            "app.started": "ऐप शुरू हो गई",
            "features.title": "मुख्य विशेषताएं",
            "feature.translation": "पाठ अनुवाद",
            "feature.translation.desc": "अनुवाद के लिए पाठ का चयन करें",
            "feature.voice": "आवाज़ पहचान",
            "feature.voice.desc": "आवाज़ इनपुट और कमांड का समर्थन",
            "feature.recommendation": "स्मार्ट सिफारिशें",
            "feature.recommendation.desc": "संदर्भ-जागरूक बुद्धिमान सुझाव",
            "feature.knowledge": "ज्ञान आधार",
            "feature.knowledge.desc": "व्यक्तिगत ज्ञान प्रबंधन प्रणाली",
            "feature.sync": "क्लाउड सिंक",
            "feature.sync.desc": "iCloud डेटा सिंक्रनाइज़ेशन",
            "button.open.settings": "सेटिंग्स खोलें",
            "button.test.translation": "अनुवाद परीक्षण",
            "button.exit.app": "ऐप से बाहर निकलें",
            "button.done": "हो गया",
            "button.ok": "ठीक है",
            "button.cancel": "रद्द करें",
            "button.copy.result": "परिणाम कॉपी करें",
            "settings.title": "सेटिंग्स",
            "settings.general": "सामान्य सेटिंग्स",
            "settings.launch.at.login": "लॉगिन पर लॉन्च करें",
            "settings.show.in.menubar": "मेनू बार में दिखाएं",
            "settings.auto.check.updates": "स्वचालित अपडेट जांचें",
            "settings.translation": "अनुवाद सेटिंग्स",
            "settings.source.language": "स्रोत भाषा",
            "settings.target.language": "लक्ष्य भाषा",
            "settings.auto.detect": "स्वचालित पहचान",
            "settings.app.language": "ऐप भाषा",
            "settings.about": "के बारे में",
            "settings.version": "संस्करण",
            "settings.build.time": "बिल्ड समय",
            "translation.test": "अनुवाद परीक्षण",
            "translation.test.result": "Hello World → नमस्ते दुनिया",
            "translation.confirmed": "अनुवाद की पुष्टि हुई",
            "translation.copied": "कॉपी हो गया",
            "translation.copied.to.clipboard": "अनुवाद परिणाम क्लिपबोर्ड में कॉपी हो गया",
            "notification.translation.test": "अनुवाद परीक्षण",
            "notification.translation.confirmed": "अनुवाद की पुष्टि हुई",
            "notification.copied": "कॉपी हो गया",
            "notification.translation.copied": "अनुवाद परिणाम क्लिपबोर्ड में कॉपी हो गया",
            // New modern strings
            "status.active": "सक्रिय",
            "status.ready": "तैयार",
            "status.inactive": "निष्क्रिय",
            "quick.access": "त्वरित पहुंच",
            "smart.input": "स्मार्ट इनपुट",
            "context.aware": "संदर्भ-जागरूक सुझाव",
            "reset.settings": "सेटिंग्स रीसेट करें",
            "export.settings": "सेटिंग्स निर्यात करें",
            "import.settings": "सेटिंग्स आयात करें",
            "settings.saved": "सेटिंग्स सहेजी गई",
            "language.changed": "भाषा बदली गई",
            "feature.ai.powered": "AI संचालित सुविधाएं",
            "feature.real.time": "रीयल-टाइम प्रोसेसिंग",
            "feature.privacy.focused": "गोपनीयता-केंद्रित"
        ],
        .arabic: [
            "app.title": "FlowKey طريقة الإدخال الذكية",
            "app.started": "تم بدء التطبيق",
            "features.title": "الميزات الرئيسية",
            "feature.translation": "ترجمة النص",
            "feature.translation.desc": "حدد النص للترجمة",
            "feature.voice": "التعرف على الصوت",
            "feature.voice.desc": "دعم إدخال الصوت والأوامر",
            "feature.recommendation": "توصيات ذكية",
            "feature.recommendation.desc": "اقتراحات ذكية واعية بالسياق",
            "feature.knowledge": "قاعدة المعرفة",
            "feature.knowledge.desc": "نظام إدارة المعرفة الشخصية",
            "feature.sync": "المزامنة السحابية",
            "feature.sync.desc": "مزامنة بيانات iCloud",
            "button.open.settings": "فتح الإعدادات",
            "button.test.translation": "اختبار الترجمة",
            "button.exit.app": "خروج من التطبيق",
            "button.done": "تم",
            "button.ok": "موافق",
            "button.cancel": "إلغاء",
            "button.copy.result": "نسخ النتيجة",
            "settings.title": "الإعدادات",
            "settings.general": "الإعدادات العامة",
            "settings.launch.at.login": "البدء عند تسجيل الدخول",
            "settings.show.in.menubar": "عرض في شريط القائمة",
            "settings.auto.check.updates": "التحقق التلقائي من التحديثات",
            "settings.translation": "إعدادات الترجمة",
            "settings.source.language": "لغة المصدر",
            "settings.target.language": "لغة الهدف",
            "settings.auto.detect": "كشف تلقائي",
            "settings.app.language": "لغة التطبيق",
            "settings.about": "حول",
            "settings.version": "الإصدار",
            "settings.build.time": "وقت البناء",
            "translation.test": "اختبار الترجمة",
            "translation.test.result": "Hello World → مرحبا بالعالم",
            "translation.confirmed": "تم تأكيد الترجمة",
            "translation.copied": "تم النسخ",
            "translation.copied.to.clipboard": "تم نسخ نتيجة الترجمة إلى الحافظة",
            "notification.translation.test": "اختبار الترجمة",
            "notification.translation.confirmed": "تم تأكيد الترجمة",
            "notification.copied": "تم النسخ",
            "notification.translation.copied": "تم نسخ نتيجة الترجمة إلى الحافظة",
            // New modern strings
            "status.active": "نشط",
            "status.ready": "جاهز",
            "status.inactive": "غير نشط",
            "quick.access": "وصول سريع",
            "smart.input": "إدخال ذكي",
            "context.aware": "اقتراحات واعية بالسياق",
            "reset.settings": "إعادة تعيين الإعدادات",
            "export.settings": "تصدير الإعدادات",
            "import.settings": "استيراد الإعدادات",
            "settings.saved": "تم حفظ الإعدادات",
            "language.changed": "تم تغيير اللغة",
            "feature.ai.powered": "ميزات مدعومة بالذكاء الاصطناعي",
            "feature.real.time": "معالجة فورية",
            "feature.privacy.focused": "مركز على الخصوصية"
        ]
    ]
}

// MARK: - Modern Language Enum

public enum SupportedLanguage: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case chinese = "zh"
    case spanish = "es"
    case hindi = "hi"
    case arabic = "ar"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        case .spanish: return "Español"
        case .hindi: return "हिन्दी"
        case .arabic: return "العربية"
        }
    }

    public var nativeName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        case .spanish: return "Español"
        case .hindi: return "हिन्दी"
        case .arabic: return "العربية"
        }
    }

    public var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .chinese: return "🇨🇳"
        case .spanish: return "🇪🇸"
        case .hindi: return "🇮🇳"
        case .arabic: return "🇸🇦"
        }
    }

    // RTL support
    public var isRTL: Bool {
        switch self {
        case .arabic: return true
        default: return false
        }
    }

    // Modern localization direction
    public var textDirection: LayoutDirection {
        return isRTL ? .rightToLeft : .leftToRight
    }
}

// MARK: - Modern Localization Keys

public enum LocalizationKey: String, CaseIterable, Codable {
    // App title and main
    case appTitle = "app.title"
    case appStarted = "app.started"

    // Features
    case featuresTitle = "features.title"
    case featureTranslation = "feature.translation"
    case featureTranslationDesc = "feature.translation.desc"
    case featureVoice = "feature.voice"
    case featureVoiceDesc = "feature.voice.desc"
    case featureRecommendation = "feature.recommendation"
    case featureRecommendationDesc = "feature.recommendation.desc"
    case featureKnowledge = "feature.knowledge"
    case featureKnowledgeDesc = "feature.knowledge.desc"
    case featureSync = "feature.sync"
    case featureSyncDesc = "feature.sync.desc"

    // Status
    case statusActive = "status.active"
    case statusReady = "status.ready"
    case statusInactive = "status.inactive"

    // Buttons
    case buttonOpenSettings = "button.open.settings"
    case buttonTestTranslation = "button.test.translation"
    case buttonExitApp = "button.exit.app"
    case buttonDone = "button.done"
    case buttonOK = "button.ok"
    case buttonCancel = "button.cancel"
    case buttonCopyResult = "button.copy.result"

    // Settings
    case settingsTitle = "settings.title"
    case settingsGeneral = "settings.general"
    case settingsLaunchAtLogin = "settings.launch.at.login"
    case settingsShowInMenuBar = "settings.show.in.menubar"
    case settingsAutoCheckUpdates = "settings.auto.check.updates"
    case settingsTranslation = "settings.translation"
    case settingsSourceLanguage = "settings.source.language"
    case settingsTargetLanguage = "settings.target.language"
    case settingsAutoDetect = "settings.auto.detect"
    case settingsAppLanguage = "settings.app.language"
    case settingsAbout = "settings.about"
    case settingsVersion = "settings.version"
    case settingsBuildTime = "settings.build.time"

    // Translation dialog
    case translationTest = "translation.test"
    case translationTestResult = "translation.test.result"
    case translationConfirmed = "translation.confirmed"
    case translationCopied = "translation.copied"
    case translationCopiedToClipboard = "translation.copied.to.clipboard"

    // Notifications
    case notificationTranslationTest = "notification.translation.test"
    case notificationTranslationConfirmed = "notification.translation.confirmed"
    case notificationCopied = "notification.copied"
    case notificationTranslationCopied = "notification.translation.copied"

    // New modern keys
    case quickAccess = "quick.access"
    case smartInput = "smart.input"
    case contextAware = "context.aware"
    case resetSettings = "reset.settings"
    case exportSettings = "export.settings"
    case importSettings = "import.settings"
    case settingsSaved = "settings.saved"
    case languageChanged = "language.changed"
    case featureAIPowered = "feature.ai.powered"
    case featureRealTime = "feature.real.time"
    case featurePrivacyFocused = "feature.privacy.focused"
}

// MARK: - Modern Notification Extensions

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
    static let localizationServiceDidUpdate = Notification.Name("localizationServiceDidUpdate")
}

// MARK: - Modern Localization Extensions

extension String {
    public func localized(with service: ModernLocalizationService) -> String {
        return service.localizedString(forKey: LocalizationKey(rawValue: self) ?? .appTitle)
    }
}

extension LocalizationKey {
    public func localized(with service: ModernLocalizationService) -> String {
        return service.localizedString(forKey: self)
    }
}

// MARK: - Modern Localization Provider

@MainActor
public struct LocalizationProvider {
    public let service: ModernLocalizationService

    public init(service: ModernLocalizationService = ModernLocalizationService()) {
        self.service = service
    }

    public func callAsFunction(_ key: LocalizationKey) -> String {
        return service.localizedString(forKey: key)
    }

    public func callAsFunction(_ key: LocalizationKey, _ arguments: CVarArg...) -> String {
        return service.localizedFormat(key, arguments)
    }
}