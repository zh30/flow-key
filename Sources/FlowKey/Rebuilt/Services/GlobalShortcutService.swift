import Carbon
import Foundation

enum GlobalShortcutRegistrationFailure: Error, Equatable {
    case unavailable
}

private extension Notification.Name {
    static let flowKeyGlobalShortcutPressed = Notification.Name(
        "com.flowkey.global-shortcut-pressed"
    )
}

private let flowKeyHotKeySignature: OSType = 0x464C4B59 // "FLKY"
private let flowKeyHotKeyIdentifier: UInt32 = 1

private let flowKeyHotKeyHandler: EventHandlerUPP = { _, event, _ in
    guard let event else { return OSStatus(eventNotHandledErr) }

    var hotKeyID = EventHotKeyID()
    let result = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )

    guard
        result == noErr,
        hotKeyID.signature == flowKeyHotKeySignature,
        hotKeyID.id == flowKeyHotKeyIdentifier
    else {
        return OSStatus(eventNotHandledErr)
    }

    DispatchQueue.main.async {
        NotificationCenter.default.post(name: .flowKeyGlobalShortcutPressed, object: nil)
    }
    return noErr
}

@MainActor
final class GlobalShortcutService {
    private var eventHandlerReference: EventHandlerRef?
    private var hotKeyReference: EventHotKeyRef?
    private var observer: NSObjectProtocol?
    private var action: (() -> Void)?

    @discardableResult
    func start(action: @escaping () -> Void) -> Bool {
        guard eventHandlerReference == nil else {
            self.action = action
            return true
        }

        self.action = action

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let result = InstallEventHandler(
            GetApplicationEventTarget(),
            flowKeyHotKeyHandler,
            1,
            &eventType,
            nil,
            &eventHandlerReference
        )

        guard result == noErr else {
            eventHandlerReference = nil
            self.action = nil
            return false
        }

        observer = NotificationCenter.default.addObserver(
            forName: .flowKeyGlobalShortcutPressed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.action?()
            }
        }
        return true
    }

    func register(_ shortcut: QuickTranslationShortcut) -> Result<Void, GlobalShortcutRegistrationFailure> {
        unregister()

        guard let specification = shortcut.carbonSpecification else {
            return .success(())
        }

        guard eventHandlerReference != nil else {
            return .failure(.unavailable)
        }

        let hotKeyID = EventHotKeyID(
            signature: flowKeyHotKeySignature,
            id: flowKeyHotKeyIdentifier
        )
        let result = RegisterEventHotKey(
            specification.keyCode,
            specification.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyReference
        )

        guard result == noErr else {
            hotKeyReference = nil
            return .failure(.unavailable)
        }

        return .success(())
    }

    func stop() {
        unregister()
        action = nil

        if let observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }

        if let eventHandlerReference {
            RemoveEventHandler(eventHandlerReference)
            self.eventHandlerReference = nil
        }
    }

    private func unregister() {
        guard let hotKeyReference else { return }
        UnregisterEventHotKey(hotKeyReference)
        self.hotKeyReference = nil
    }
}

private extension QuickTranslationShortcut {
    struct CarbonSpecification {
        let keyCode: UInt32
        let modifiers: UInt32
    }

    var carbonSpecification: CarbonSpecification? {
        switch self {
        case .optionSpace:
            return CarbonSpecification(
                keyCode: UInt32(kVK_Space),
                modifiers: UInt32(optionKey)
            )
        case .controlSpace:
            return CarbonSpecification(
                keyCode: UInt32(kVK_Space),
                modifiers: UInt32(controlKey)
            )
        case .optionT:
            return CarbonSpecification(
                keyCode: UInt32(kVK_ANSI_T),
                modifiers: UInt32(optionKey)
            )
        case .controlOptionSpace:
            return CarbonSpecification(
                keyCode: UInt32(kVK_Space),
                modifiers: UInt32(controlKey | optionKey)
            )
        case .disabled:
            return nil
        }
    }
}
