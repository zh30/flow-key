import AppKit
import Carbon
import Observation

@MainActor
@Observable
final class InputMethodManager {
    enum State: Equatable {
        case unavailable
        case notInstalled
        case installed
        case enabled
        case selected

        var label: String {
            switch self {
            case .unavailable:
                return L10n.string("Unavailable in this build")
            case .notInstalled:
                return L10n.string("Not installed")
            case .installed:
                return L10n.string("Installed")
            case .enabled:
                return L10n.string("Added to Input Sources")
            case .selected:
                return L10n.string("Currently selected")
            }
        }

        var systemImage: String {
            switch self {
            case .unavailable:
                return "exclamationmark.triangle.fill"
            case .notInstalled:
                return "square.and.arrow.down"
            case .installed:
                return "checkmark.circle"
            case .enabled:
                return "checkmark.circle.fill"
            case .selected:
                return "keyboard.fill"
            }
        }
    }

    private(set) var state: State = .notInstalled
    private(set) var lastErrorMessage: String?

    private let bundleIdentifier = "com.flowkey.inputmethod"
    private let inputMethodName = "FlowKey Compose.app"

    var canInstall: Bool {
        state == .notInstalled
    }

    func refresh() {
        lastErrorMessage = nil

        guard FileManager.default.fileExists(atPath: embeddedInputMethodURL.path) else {
            state = .unavailable
            return
        }

        guard FileManager.default.fileExists(atPath: installedInputMethodURL.path) else {
            state = .notInstalled
            return
        }

        let sources = registeredInputSources()
        if sources.contains(where: isSelectedInputSource) {
            state = .selected
        } else if sources.contains(where: isEnabledInputSource) {
            state = .enabled
        } else {
            state = .installed
        }
    }

    func install() {
        lastErrorMessage = nil

        guard canInstall else {
            refresh()
            return
        }

        do {
            try FileManager.default.createDirectory(
                at: inputMethodsDirectory,
                withIntermediateDirectories: true
            )
            try FileManager.default.copyItem(
                at: embeddedInputMethodURL,
                to: installedInputMethodURL
            )

            let registrationResult = TISRegisterInputSource(installedInputMethodURL as CFURL)
            guard registrationResult == noErr else {
                state = .installed
                lastErrorMessage =
                    L10n.string(
                        "The bundle was copied, but macOS could not register it yet. Sign out and back in, then open Keyboard Settings."
                    )
                return
            }

            refresh()
            openKeyboardSettings()
        } catch {
            lastErrorMessage = error.localizedDescription
            refreshAfterErrorPreservingMessage()
        }
    }

    func openKeyboardSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension"
        ) else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private var embeddedInputMethodURL: URL {
        Bundle.main.bundleURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Input Methods", isDirectory: true)
            .appendingPathComponent(inputMethodName, isDirectory: true)
    }

    private var inputMethodsDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Input Methods", isDirectory: true)
    }

    private var installedInputMethodURL: URL {
        inputMethodsDirectory.appendingPathComponent(inputMethodName, isDirectory: true)
    }

    private func registeredInputSources() -> [TISInputSource] {
        let properties = [
            kTISPropertyBundleID as String: bundleIdentifier,
        ] as CFDictionary

        guard let unmanagedSources = TISCreateInputSourceList(properties, false) else {
            return []
        }
        return unmanagedSources.takeRetainedValue() as NSArray as? [TISInputSource] ?? []
    }

    private func isEnabledInputSource(_ source: TISInputSource) -> Bool {
        booleanProperty(kTISPropertyInputSourceIsEnabled, of: source)
    }

    private func isSelectedInputSource(_ source: TISInputSource) -> Bool {
        booleanProperty(kTISPropertyInputSourceIsSelected, of: source)
    }

    private func booleanProperty(_ key: CFString, of source: TISInputSource) -> Bool {
        guard let pointer = TISGetInputSourceProperty(source, key) else { return false }
        let value = Unmanaged<CFBoolean>
            .fromOpaque(pointer)
            .takeUnretainedValue()
        return CFBooleanGetValue(value)
    }

    private func refreshAfterErrorPreservingMessage() {
        let message = lastErrorMessage
        refresh()
        lastErrorMessage = message
    }
}
