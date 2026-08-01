import AppKit
import ApplicationServices

enum SelectionCaptureFailure: Error, Equatable {
    case permissionRequired
    case noSelection
    case secureField
    case unsupportedApplication
    case unavailable

    var title: String {
        switch self {
        case .permissionRequired:
            return L10n.string("Allow selected-text access")
        case .noSelection:
            return L10n.string("No text is selected")
        case .secureField:
            return L10n.string("Secure text stays private")
        case .unsupportedApplication:
            return L10n.string("Selected text is unavailable here")
        case .unavailable:
            return L10n.string("FlowKey could not read the selection")
        }
    }

    var recoverySuggestion: String {
        switch self {
        case .permissionRequired:
            return L10n.string(
                "Allow FlowKey in Privacy & Security, then select text and use the shortcut again."
            )
        case .noSelection:
            return L10n.string(
                "Select text in another app and use the shortcut again, or use the clipboard."
            )
        case .secureField:
            return L10n.string(
                "FlowKey never reads password or other secure text fields. Use non-sensitive text instead."
            )
        case .unsupportedApplication:
            return L10n.string(
                "This app does not expose its selection to macOS. Copy the text, then use the clipboard."
            )
        case .unavailable:
            return L10n.string(
                "Return to the source app and try the shortcut again, or use the clipboard."
            )
        }
    }
}

enum SelectionReplacementFailure: Error, LocalizedError {
    case permissionRequired
    case selectionChanged
    case unsupportedApplication
    case unavailable

    var errorDescription: String? {
        switch self {
        case .permissionRequired:
            return L10n.string("Accessibility access is no longer allowed.")
        case .selectionChanged:
            return L10n.string(
                "The original selection is no longer available. Select the text and try again."
            )
        case .unsupportedApplication:
            return L10n.string(
                "This app does not support replacing selected text. Copy the translation instead."
            )
        case .unavailable:
            return L10n.string(
                "FlowKey could not replace the selected text. Copy the translation instead."
            )
        }
    }
}

@MainActor
struct CapturedSelection {
    let text: String
    let canReplace: Bool

    private let element: AXUIElement
    private let processIdentifier: pid_t

    init(
        text: String,
        canReplace: Bool,
        element: AXUIElement,
        processIdentifier: pid_t
    ) {
        self.text = text
        self.canReplace = canReplace
        self.element = element
        self.processIdentifier = processIdentifier
    }

    func replace(with replacement: String) throws {
        guard AccessibilitySelectionService.isAuthorized else {
            throw SelectionReplacementFailure.permissionRequired
        }

        var currentSelectionValue: CFTypeRef?
        let currentSelectionResult = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            &currentSelectionValue
        )
        guard
            currentSelectionResult == .success,
            let currentSelection = currentSelectionValue as? String,
            currentSelection == text
        else {
            throw SelectionReplacementFailure.selectionChanged
        }

        let result = AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            replacement as CFString
        )

        switch result {
        case .success:
            NSRunningApplication(processIdentifier: processIdentifier)?.activate()
        case .attributeUnsupported, .actionUnsupported:
            throw SelectionReplacementFailure.unsupportedApplication
        case .illegalArgument, .invalidUIElement:
            throw SelectionReplacementFailure.selectionChanged
        case .apiDisabled:
            throw SelectionReplacementFailure.permissionRequired
        default:
            throw SelectionReplacementFailure.unavailable
        }
    }
}

enum SelectionCaptureResult {
    case captured(CapturedSelection)
    case failed(SelectionCaptureFailure)
}

@MainActor
enum AccessibilitySelectionService {
    static var isAuthorized: Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    static func requestAuthorization() -> Bool {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true,
        ] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func openPrivacySettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    static func captureFocusedSelection() -> SelectionCaptureResult {
        guard isAuthorized else {
            return .failed(.permissionRequired)
        }

        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedValue: CFTypeRef?
        let focusedResult = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedValue
        )

        guard focusedResult == .success, let focusedValue else {
            return .failed(mapCaptureError(focusedResult, unsupported: .unavailable))
        }

        let focusedElement = focusedValue as! AXUIElement

        if stringAttribute(kAXSubroleAttribute as CFString, on: focusedElement) ==
            (kAXSecureTextFieldSubrole as String)
        {
            return .failed(.secureField)
        }

        var selectedValue: CFTypeRef?
        let selectedResult = AXUIElementCopyAttributeValue(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            &selectedValue
        )

        guard selectedResult == .success else {
            return .failed(mapCaptureError(selectedResult, unsupported: .unsupportedApplication))
        }

        guard let selectedText = selectedValue as? String else {
            return .failed(.unsupportedApplication)
        }

        guard selectedText.isEmpty == false else {
            return .failed(.noSelection)
        }

        var processIdentifier = pid_t()
        guard AXUIElementGetPid(focusedElement, &processIdentifier) == .success else {
            return .failed(.unavailable)
        }

        var selectedTextIsSettable = DarwinBoolean(false)
        let settableResult = AXUIElementIsAttributeSettable(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            &selectedTextIsSettable
        )

        return .captured(
            CapturedSelection(
                text: selectedText,
                canReplace: settableResult == .success && selectedTextIsSettable.boolValue,
                element: focusedElement,
                processIdentifier: processIdentifier
            )
        )
    }

    private static func stringAttribute(
        _ attribute: CFString,
        on element: AXUIElement
    ) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
            return nil
        }
        return value as? String
    }

    private static func mapCaptureError(
        _ error: AXError,
        unsupported: SelectionCaptureFailure
    ) -> SelectionCaptureFailure {
        switch error {
        case .apiDisabled:
            return .permissionRequired
        case .attributeUnsupported, .actionUnsupported:
            return unsupported
        default:
            return .unavailable
        }
    }
}
