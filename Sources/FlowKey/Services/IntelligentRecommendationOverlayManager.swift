import Foundation
import SwiftUI
import Combine

public class IntelligentRecommendationOverlayManager: ObservableObject {
    public static let shared = IntelligentRecommendationOverlayManager()
    
    @Published public var isOverlayVisible = false
    
    private init() {}
    
    public func toggleRecommendationOverlay() {
        isOverlayVisible.toggle()
    }
    
    public func showRecommendationOverlay() {
        isOverlayVisible = true
    }
    
    public func hideRecommendationOverlay() {
        isOverlayVisible = false
    }
}