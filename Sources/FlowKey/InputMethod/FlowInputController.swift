import AppKit
import SwiftUI

@MainActor
final class FlowInputController: ObservableObject {
    static let shared = FlowInputController()
    
    @Published private(set) var isActive = false
    
    private init() { }
    
    func activateInputMethod() {
        isActive = true
    }
    
    func deactivateInputMethod() {
        isActive = false
    }
    
    func toggle() {
        isActive.toggle()
    }
}
