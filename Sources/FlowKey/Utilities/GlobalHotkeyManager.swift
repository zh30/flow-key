import Cocoa
import Carbon

// MARK: - Global Hotkey Manager

@MainActor
class GlobalHotkeyManager: ObservableObject {
    static let shared = GlobalHotkeyManager()
    
    private var hotkeyRef: EventHotKeyRef?
    private var hotkeyID = EventHotKeyID(signature: OSType("FlowK"), id: UInt32(1))
    
    private let voiceCommandManager = VoiceCommandManager.shared
    
    private init() {
        setupGlobalHotkey()
    }
    
    deinit {
        removeGlobalHotkey()
    }
    
    // MARK: - Public Methods
    
    func setupGlobalHotkey() {
        // Register Command+Shift+V as the global hotkey
        let keyCode = UInt32(kVK_ANSI_V) // V key
        let modifiers = UInt32(cmdKey | shiftKey)
        
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )
        
        if status != noErr {
            print("Failed to register global hotkey: \(status)")
        } else {
            print("Global hotkey registered successfully")
        }
        
        // Add event handler
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            hotkeyHandler,
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            nil
        )
    }
    
    func removeGlobalHotkey() {
        if let hotkeyRef = hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
        }
    }
    
    func toggleVoiceCommand() {
        voiceCommandManager.toggleVoiceCommand()
    }
}

// MARK: - Hotkey Handler

private let hotkeyHandler: EventHandlerCallPtr = { (nextHandler, anEvent, userData) -> OSStatus in
    guard let userData = userData else { return noErr }
    
    // Get back our GlobalHotkeyManager instance
    let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
    
    // Handle the hotkey press
    DispatchQueue.main.async {
        manager.toggleVoiceCommand()
    }
    
    return noErr
}

// MARK: - Hotkey Helper

extension GlobalHotkeyManager {
    func setHotkey(_ keyString: String) {
        removeGlobalHotkey()
        
        // Parse key string (e.g., "Command+Shift+V")
        let components = keyString.split(separator: "+")
        guard !components.isEmpty else { return }
        
        let key = components.last?.lowercased() ?? "v"
        let modifiers = components.dropLast()
        
        // Get key code
        let keyCode: UInt32
        switch key {
        case "v": keyCode = UInt32(kVK_ANSI_V)
        case "c": keyCode = UInt32(kVK_ANSI_C)
        case "x": keyCode = UInt32(kVK_ANSI_X)
        case "z": keyCode = UInt32(kVK_ANSI_Z)
        case "a": keyCode = UInt32(kVK_ANSI_A)
        case "s": keyCode = UInt32(kVK_ANSI_S)
        case "d": keyCode = UInt32(kVK_ANSI_D)
        case "f": keyCode = UInt32(kVK_ANSI_F)
        case "space": keyCode = UInt32(kVK_Space)
        case "return": keyCode = UInt32(kVK_Return)
        case "tab": keyCode = UInt32(kVK_Tab)
        case "escape": keyCode = UInt32(kVK_Escape)
        default: keyCode = UInt32(kVK_ANSI_V) // Default to V
        }
        
        // Get modifiers
        var modifierFlags: UInt32 = 0
        for modifier in modifiers {
            switch modifier.lowercased() {
            case "command", "cmd":
                modifierFlags |= UInt32(cmdKey)
            case "shift":
                modifierFlags |= UInt32(shiftKey)
            case "option", "alt":
                modifierFlags |= UInt32(optionKey)
            case "control", "ctrl":
                modifierFlags |= UInt32(controlKey)
            default:
                break
            }
        }
        
        // Register new hotkey
        let status = RegisterEventHotKey(
            keyCode,
            modifierFlags,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )
        
        if status != noErr {
            print("Failed to register hotkey '\(keyString)': \(status)")
        } else {
            print("Hotkey '\(keyString)' registered successfully")
        }
    }
}

// MARK: - Key Code Constants

// Virtual key codes (partial list)
let kVK_ANSI_A: UInt16 = 0x00
let kVK_ANSI_S: UInt16 = 0x01
let kVK_ANSI_D: UInt16 = 0x02
let kVK_ANSI_F: UInt16 = 0x03
let kVK_ANSI_H: UInt16 = 0x04
let kVK_ANSI_G: UInt16 = 0x05
let kVK_ANSI_Z: UInt16 = 0x06
let kVK_ANSI_X: UInt16 = 0x07
let kVK_ANSI_C: UInt16 = 0x08
let kVK_ANSI_V: UInt16 = 0x09
let kVK_ANSI_B: UInt16 = 0x0B
let kVK_ANSI_Q: UInt16 = 0x0C
let kVK_ANSI_W: UInt16 = 0x0D
let kVK_ANSI_E: UInt16 = 0x0E
let kVK_ANSI_R: UInt16 = 0x0F
let kVK_ANSI_Y: UInt16 = 0x10
let kVK_ANSI_T: UInt16 = 0x11
let kVK_ANSI_1: UInt16 = 0x12
let kVK_ANSI_2: UInt16 = 0x13
let kVK_ANSI_3: UInt16 = 0x14
let kVK_ANSI_4: UInt16 = 0x15
let kVK_ANSI_6: UInt16 = 0x16
let kVK_ANSI_5: UInt16 = 0x17
let kVK_ANSI_Equal: UInt16 = 0x18
let kVK_ANSI_9: UInt16 = 0x19
let kVK_ANSI_7: UInt16 = 0x1A
let kVK_ANSI_Minus: UInt16 = 0x1B
let kVK_ANSI_8: UInt16 = 0x1C
let kVK_ANSI_0: UInt16 = 0x1D
let kVK_ANSI_RightBracket: UInt16 = 0x1E
let kVK_ANSI_O: UInt16 = 0x1F
let kVK_ANSI_U: UInt16 = 0x20
let kVK_ANSI_LeftBracket: UInt16 = 0x21
let kVK_ANSI_I: UInt16 = 0x22
let kVK_ANSI_P: UInt16 = 0x23
let kVK_ANSI_L: UInt16 = 0x25
let kVK_ANSI_J: UInt16 = 0x26
let kVK_ANSI_Quote: UInt16 = 0x27
let kVK_ANSI_K: UInt16 = 0x28
let kVK_ANSI_Semicolon: UInt16 = 0x29
let kVK_ANSI_Backslash: UInt16 = 0x2A
let kVK_ANSI_Comma: UInt16 = 0x2B
let kVK_ANSI_Slash: UInt16 = 0x2C
let kVK_ANSI_N: UInt16 = 0x2D
let kVK_ANSI_M: UInt16 = 0x2E
let kVK_ANSI_Period: UInt16 = 0x2F
let kVK_ANSI_Grave: UInt16 = 0x32
let kVK_ANSI_KeypadDecimal: UInt16 = 0x41
let kVK_ANSI_KeypadMultiply: UInt16 = 0x43
let kVK_ANSI_KeypadPlus: UInt16 = 0x45
let kVK_ANSI_KeypadClear: UInt16 = 0x47
let kVK_ANSI_KeypadDivide: UInt16 = 0x4B
let kVK_ANSI_KeypadEnter: UInt16 = 0x4C
let kVK_ANSI_KeypadMinus: UInt16 = 0x4E
let kVK_ANSI_KeypadEquals: UInt16 = 0x51
let kVK_ANSI_Keypad0: UInt16 = 0x52
let kVK_ANSI_Keypad1: UInt16 = 0x53
let kVK_ANSI_Keypad2: UInt16 = 0x54
let kVK_ANSI_Keypad3: UInt16 = 0x55
let kVK_ANSI_Keypad4: UInt16 = 0x56
let kVK_ANSI_Keypad5: UInt16 = 0x57
let kVK_ANSI_Keypad6: UInt16 = 0x58
let kVK_ANSI_Keypad7: UInt16 = 0x59
let kVK_ANSI_Keypad8: UInt16 = 0x5B
let kVK_ANSI_Keypad9: UInt16 = 0x5C
let kVK_Return: UInt16 = 0x24
let kVK_Tab: UInt16 = 0x30
let kVK_Space: UInt16 = 0x31
let kVK_Delete: UInt16 = 0x33
let kVK_Escape: UInt16 = 0x35
let kVK_Command: UInt16 = 0x37
let kVK_Shift: UInt16 = 0x38
let kVK_CapsLock: UInt16 = 0x39
let kVK_Option: UInt16 = 0x3A
let kVK_Control: UInt16 = 0x3B
let kVK_RightCommand: UInt16 = 0x36
let kVK_RightShift: UInt16 = 0x3C
let kVK_RightOption: UInt16 = 0x3D
let kVK_RightControl: UInt16 = 0x3E
let kVK_Function: UInt16 = 0x3F
let kVK_F17: UInt16 = 0x40
let kVK_VolumeUp: UInt16 = 0x48
let kVK_VolumeDown: UInt16 = 0x49
let kVK_Mute: UInt16 = 0x4A
let kVK_F18: UInt16 = 0x4F
let kVK_F19: UInt16 = 0x50
let kVK_F20: UInt16 = 0x5A
let kVK_F5: UInt16 = 0x60
let kVK_F6: UInt16 = 0x61
let kVK_F7: UInt16 = 0x62
let kVK_F3: UInt16 = 0x63
let kVK_F8: UInt16 = 0x64
let kVK_F9: UInt16 = 0x65
let kVK_F11: UInt16 = 0x67
let kVK_F13: UInt16 = 0x69
let kVK_F16: UInt16 = 0x6A
let kVK_F14: UInt16 = 0x6B
let kVK_F10: UInt16 = 0x6D
let kVK_F12: UInt16 = 0x6F
let kVK_F15: UInt16 = 0x71
let kVK_Help: UInt16 = 0x72
let kVK_Home: UInt16 = 0x73
let kVK_PageUp: UInt16 = 0x74
let kVK_ForwardDelete: UInt16 = 0x75
let kVK_F4: UInt16 = 0x76
let kVK_End: UInt16 = 0x77
let kVK_F2: UInt16 = 0x78
let kVK_PageDown: UInt16 = 0x79
let kVK_F1: UInt16 = 0x7A
let kVK_LeftArrow: UInt16 = 0x7B
let kVK_RightArrow: UInt16 = 0x7C
let kVK_DownArrow: UInt16 = 0x7D
let kVK_UpArrow: UInt16 = 0x7E