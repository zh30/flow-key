import AppKit
import InputMethodKit

@main
enum FlowKeyInputMethodMain {
    private static var server: IMKServer?

    static func main() {
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)

        guard
            let connectionName = Bundle.main.object(
                forInfoDictionaryKey: "InputMethodConnectionName"
            ) as? String,
            let bundleIdentifier = Bundle.main.bundleIdentifier
        else {
            NSLog("FlowKey Compose could not read its bundle configuration.")
            return
        }

        server = IMKServer(
            name: connectionName,
            bundleIdentifier: bundleIdentifier
        )
        application.run()
    }
}
