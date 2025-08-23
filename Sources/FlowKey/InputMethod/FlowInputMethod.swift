import AppKit

// Mock IMKInputMethod for development
// In production, this would be replaced with the actual InputMethodKit framework
public class FlowInputMethod: NSObject {
    
    private var server: Any?
    
    public init(forServerName serverName: String!) {
        super.init()
        setupServer()
    }
    
    private func setupServer() {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.flowkey.inputmethod"
        // Mock server setup
        print("Setting up server for: \(bundleIdentifier)")
    }
    
    public func activated(_ client: Any!) {
        NSLog("FlowKey input method activated")
    }
    
    public func deactivated(_ client: Any!) {
        NSLog("FlowKey input method deactivated")
    }
    
    public func controller(
        _ client: Any!,
        withName name: String!
    ) -> Any! {
        return FlowInputController(
            server: nil,
            delegate: self,
            client: client
        )
    }
    
    public func languages() -> [Any]! {
        return ["en-US", "zh-CN"]
    }
    
    public func primaryLanguage() -> String! {
        return "en-US"
    }
    
    public func showPreferences() {
        NotificationCenter.default.post(name: .openSettings, object: nil)
    }
}