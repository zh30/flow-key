import Foundation
import SwiftUI
import Combine

public class VoiceCommandManager: ObservableObject {
    public static let shared = VoiceCommandManager()
    
    @Published public var isOverlayVisible = false
    @Published public var isMiniViewVisible = false
    
    private init() {}
    
    public func toggleVoiceCommand() {
        if isOverlayVisible {
            stopVoiceCommand()
        } else {
            startVoiceCommand()
        }
    }
    
    public func startVoiceCommand() {
        isOverlayVisible = true
        isMiniViewVisible = false
    }
    
    public func stopVoiceCommand() {
        isOverlayVisible = false
        isMiniViewVisible = false
    }
    
    public func showMiniView() {
        isMiniViewVisible = true
        isOverlayVisible = false
    }
}