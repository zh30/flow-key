import AppKit
import Carbon
import FlowKeyInputMethodCore
import InputMethodKit

@objc(FlowKeyInputController)
final class FlowKeyInputController: IMKInputController {
    private var composition = FlowKeyComposition()
    private var candidatePanel: IMKCandidates?

    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        super.init(server: server, delegate: delegate, client: inputClient)

        candidatePanel = IMKCandidates(
            server: server,
            panelType: kIMKSingleColumnScrollingCandidatePanel
        )
        candidatePanel?.setAttributes([
            IMKCandidatesSendServerKeyEventFirst: true,
        ])
    }

    override func recognizedEvents(_ sender: Any!) -> Int {
        Int(NSEvent.EventTypeMask.keyDown.rawValue)
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event, let sender, event.type == .keyDown else { return false }

        if composition.isActive == false {
            guard isStartShortcut(event) else { return false }
            composition.start()
            return true
        }

        switch Int(event.keyCode) {
        case kVK_Escape:
            cancelComposition()
            return true
        case kVK_Return, kVK_ANSI_KeypadEnter:
            guard composition.text.isEmpty == false else {
                cancelComposition()
                return false
            }
            let selectedCandidate = candidatePanel?.selectedCandidateString()?.string
            commit(selectedCandidate ?? composition.text, to: sender)
            return true
        case kVK_Delete:
            composition.deleteBackward()
            refreshComposition()
            return true
        case kVK_UpArrow, kVK_DownArrow, kVK_PageUp, kVK_PageDown:
            if composition.text.isEmpty {
                cancelComposition()
            }
            return false
        default:
            break
        }

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if modifiers.contains(.command) || modifiers.contains(.control) {
            commit(composition.text, to: sender)
            return false
        }

        guard let input = event.characters, input.isEmpty == false else {
            return false
        }

        composition.append(input)
        refreshComposition()
        return true
    }

    override func composedString(_ sender: Any!) -> Any! {
        composition.text as NSString
    }

    override func originalString(_ sender: Any!) -> NSAttributedString! {
        NSAttributedString(string: "")
    }

    override func selectionRange() -> NSRange {
        NSRange(location: composition.text.utf16.count, length: 0)
    }

    override func commitComposition(_ sender: Any!) {
        guard composition.isActive, let sender else { return }
        commit(composition.text, to: sender)
    }

    override func cancelComposition() {
        guard composition.isActive else { return }
        composition.cancel()
        candidatePanel?.hide()
        super.cancelComposition()
    }

    override func candidateSelected(_ candidateString: NSAttributedString!) {
        guard let candidateString, let client = client() else { return }
        commit(candidateString.string, to: client)
    }

    override func deactivateServer(_ sender: Any!) {
        if composition.isActive, let sender {
            commitComposition(sender)
        }
        candidatePanel?.hide()
        super.deactivateServer(sender)
    }

    override func inputControllerWillClose() {
        candidatePanel?.hide()
        composition.cancel()
        super.inputControllerWillClose()
    }

    override func menu() -> NSMenu! {
        let menu = NSMenu(title: "FlowKey Compose")
        let helpItem = NSMenuItem(
            title: NSLocalizedString("Press ⌃⌥F to compose text", comment: ""),
            action: nil,
            keyEquivalent: ""
        )
        helpItem.isEnabled = false
        menu.addItem(helpItem)
        return menu
    }

    private func isStartShortcut(_ event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return Int(event.keyCode) == kVK_ANSI_F &&
            modifiers == [.control, .option]
    }

    private func refreshComposition() {
        updateComposition()

        let candidates = composition.candidates
        guard candidates.isEmpty == false else {
            candidatePanel?.hide()
            return
        }

        candidatePanel?.setCandidateData(candidates)
        candidatePanel?.show(kIMKLocateCandidatesBelowHint)
    }

    private func commit(_ text: String, to sender: Any) {
        guard let inputClient = sender as? IMKTextInput else {
            composition.cancel()
            candidatePanel?.hide()
            return
        }

        _ = composition.commit(candidate: text)
        candidatePanel?.hide()
        inputClient.insertText(
            text,
            replacementRange: NSRange(location: NSNotFound, length: NSNotFound)
        )
    }
}
