import Foundation
import SwiftUI

// Supported languages enum
enum SupportedLanguage: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case chinese = "zh"
    case spanish = "es"
    case hindi = "hi"
    case arabic = "ar"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        case .spanish: return "Español"
        case .hindi: return "हिन्दी"
        case .arabic: return "العربية"
        }
    }
    
    var nativeName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        case .spanish: return "Español"
        case .hindi: return "हिन्दी"
        case .arabic: return "العربية"
        }
    }
    
    var flag: String {
        switch self {
        case .english: return "🇺🇸 English"
        case .chinese: return "🇨🇳 中文"
        case .spanish: return "🇪🇸 Español"
        case .hindi: return "🇮🇳 हिन्दी"
        case .arabic: return "🇸🇦 العربية"
        }
    }
    
    var isRTL: Bool { self == .arabic }
}

// Localization keys
enum LocalizationKey: String, CaseIterable, Codable {
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
}

// Localization service
@MainActor
class LocalizationService: ObservableObject {
    @Published var currentLanguage: SupportedLanguage = .english
    @Published var currentLanguageCode: String = "en"
    
    private let userDefaults: UserDefaults
    private let languageKey = "selected_language"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadSavedLanguage()
    }
    
    private func loadSavedLanguage() {
        if let savedLanguageCode = userDefaults.string(forKey: languageKey),
           let savedLanguage = SupportedLanguage(rawValue: savedLanguageCode) {
            currentLanguage = savedLanguage
            currentLanguageCode = savedLanguageCode
        } else {
            let systemLanguage: String
            if #available(macOS 13, *) {
                systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            } else {
                systemLanguage = Locale.current.languageCode ?? "en"
            }
            currentLanguage = SupportedLanguage(rawValue: systemLanguage) ?? .english
            currentLanguageCode = currentLanguage.rawValue
        }
    }
    
    func setLanguage(_ language: SupportedLanguage) {
        currentLanguage = language
        currentLanguageCode = language.rawValue
        userDefaults.set(language.rawValue, forKey: languageKey)
        objectWillChange.send()
    }
    
    func localizedString(forKey key: LocalizationKey) -> String {
        localizedStrings[currentLanguage]?[key.rawValue] ??
        localizedStrings[.english]?[key.rawValue] ??
        key.rawValue
    }
    
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
            "notification.translation.copied": "Translation result copied to clipboard"
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
            "notification.translation.confirmed": "翻译结果已确认",
            "notification.copied": "已复制",
            "notification.translation.copied": "翻译结果已复制"
        ],
        .spanish: [
            "app.title": "FlowKey Método de Entrada Inteligente",
            "app.started": "Aplicación Iniciada",
            "features.title": "Funciones Clave",
            "feature.translation": "Traducción de Texto",
            "feature.translation.desc": "Selecciona texto para traducir",
            "feature.voice": "Reconocimiento de Voz",
            "feature.voice.desc": "Soporte para comandos de voz",
            "feature.recommendation": "Recomendaciones Inteligentes",
            "feature.recommendation.desc": "Sugerencias basadas en contexto",
            "feature.knowledge": "Base de Conocimientos",
            "feature.knowledge.desc": "Gestión personal del conocimiento",
            "feature.sync": "Sincronización en la Nube",
            "feature.sync.desc": "Sincronización de datos con iCloud",
            "button.open.settings": "Abrir Ajustes",
            "button.test.translation": "Probar Traducción",
            "button.exit.app": "Salir",
            "button.done": "Hecho",
            "button.ok": "Aceptar",
            "button.cancel": "Cancelar",
            "button.copy.result": "Copiar Resultado",
            "settings.title": "Ajustes",
            "settings.general": "Ajustes Generales",
            "settings.launch.at.login": "Iniciar con el Sistema",
            "settings.show.in.menubar": "Mostrar en la Barra de Menús",
            "settings.auto.check.updates": "Buscar Actualizaciones Automáticamente",
            "settings.translation": "Ajustes de Traducción",
            "settings.source.language": "Idioma de Origen",
            "settings.target.language": "Idioma de Destino",
            "settings.auto.detect": "Detección Automática",
            "settings.app.language": "Idioma de la Aplicación",
            "settings.about": "Acerca de",
            "settings.version": "Versión",
            "settings.build.time": "Tiempo de Compilación",
            "translation.test": "Prueba de Traducción",
            "translation.test.result": "Hello World → Hola Mundo",
            "translation.confirmed": "Traducción confirmada",
            "translation.copied": "Copiado",
            "translation.copied.to.clipboard": "Resultado copiado al portapapeles",
            "notification.translation.test": "Prueba de Traducción",
            "notification.translation.confirmed": "Traducción confirmada",
            "notification.copied": "Copiado",
            "notification.translation.copied": "Resultado copiado"
        ],
        .hindi: [
            "app.title": "FlowKey स्मार्ट इनपुट विधि",
            "app.started": "एप प्रारंभ हुआ",
            "features.title": "प्रमुख विशेषताएँ",
            "feature.translation": "पाठ अनुवाद",
            "feature.translation.desc": "अनुवाद के लिए पाठ चुनें",
            "feature.voice": "वॉइस मान्यता",
            "feature.voice.desc": "वॉइस इनपुट और कमांड",
            "feature.recommendation": "स्मार्ट अनुशंसाएँ",
            "feature.recommendation.desc": "संदर्भ आधारित बुद्धिमान सुझाव",
            "feature.knowledge": "ज्ञान आधार",
            "feature.knowledge.desc": "व्यक्तिगत ज्ञान प्रबंधन",
            "feature.sync": "क्लाउड सिंक",
            "feature.sync.desc": "iCloud डेटा सिंक",
            "button.open.settings": "सेटिंग्स खोलें",
            "button.test.translation": "अनुवाद परीक्षण",
            "button.exit.app": "एप बंद करें",
            "button.done": "पूर्ण",
            "button.ok": "ठीक",
            "button.cancel": "रद्द करें",
            "button.copy.result": "परिणाम कॉपी करें",
            "settings.title": "सेटिंग्स",
            "settings.general": "सामान्य सेटिंग्स",
            "settings.launch.at.login": "लॉगिन पर लॉन्च करें",
            "settings.show.in.menubar": "मेनू बार में दिखाएँ",
            "settings.auto.check.updates": "स्वचालित अपडेट जाँचें",
            "settings.translation": "अनुवाद सेटिंग्स",
            "settings.source.language": "स्रोत भाषा",
            "settings.target.language": "लक्ष्य भाषा",
            "settings.auto.detect": "स्वचालित पहचान",
            "settings.app.language": "एप भाषा",
            "settings.about": "परिचय",
            "settings.version": "संस्करण",
            "settings.build.time": "बिल्ड समय",
            "translation.test": "अनुवाद परीक्षण",
            "translation.test.result": "Hello World → नमस्ते दुनिया",
            "translation.confirmed": "अनुवाद की पुष्टि हुई",
            "translation.copied": "कॉपी किया गया",
            "translation.copied.to.clipboard": "परिणाम क्लिपबोर्ड पर कॉपी किया गया",
            "notification.translation.test": "अनुवाद परीक्षण",
            "notification.translation.confirmed": "अनुवाद की पुष्टि",
            "notification.copied": "कॉपी किया गया",
            "notification.translation.copied": "अनुवाद परिणाम कॉपी"
        ],
        .arabic: [
            "app.title": "كيبورد FlowKey الذكي",
            "app.started": "تم تشغيل التطبيق",
            "features.title": "الميزات الرئيسية",
            "feature.translation": "ترجمة النص",
            "feature.translation.desc": "حدد النص للترجمة",
            "feature.voice": "التعرف على الصوت",
            "feature.voice.desc": "دعم أوامر الإدخال الصوتي",
            "feature.recommendation": "التوصيات الذكية",
            "feature.recommendation.desc": "اقتراحات ذكية بحسب السياق",
            "feature.knowledge": "قاعدة المعرفة",
            "feature.knowledge.desc": "إدارة المعرفة الشخصية",
            "feature.sync": "مزامنة سحابية",
            "feature.sync.desc": "مزامنة بيانات iCloud",
            "button.open.settings": "فتح الإعدادات",
            "button.test.translation": "اختبار الترجمة",
            "button.exit.app": "إنهاء التطبيق",
            "button.done": "تم",
            "button.ok": "موافق",
            "button.cancel": "إلغاء",
            "button.copy.result": "نسخ النتيجة",
            "settings.title": "الإعدادات",
            "settings.general": "إعدادات عامة",
            "settings.launch.at.login": "تشغيل عند تسجيل الدخول",
            "settings.show.in.menubar": "إظهار في شريط القوائم",
            "settings.auto.check.updates": "التحقق التلقائي من التحديثات",
            "settings.translation": "إعدادات الترجمة",
            "settings.source.language": "اللغة المصدر",
            "settings.target.language": "اللغة الهدف",
            "settings.auto.detect": "كشف تلقائي",
            "settings.app.language": "لغة التطبيق",
            "settings.about": "حول",
            "settings.version": "الإصدار",
            "settings.build.time": "وقت البناء",
            "translation.test": "اختبار الترجمة",
            "translation.test.result": "Hello World → مرحبا بالعالم",
            "translation.confirmed": "تم تأكيد الترجمة",
            "translation.copied": "تم النسخ",
            "translation.copied.to.clipboard": "تم نسخ النتيجة إلى الحافظة",
            "notification.translation.test": "اختبار الترجمة",
            "notification.translation.confirmed": "تم تأكيد الترجمة",
            "notification.copied": "تم النسخ",
            "notification.translation.copied": "تم نسخ نتيجة الترجمة"
        ]
    ]
}

@MainActor
extension LocalizationKey {
    func localized(using service: LocalizationService) -> String {
        service.localizedString(forKey: self)
    }
}
