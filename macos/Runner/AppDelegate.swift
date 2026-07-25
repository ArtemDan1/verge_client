import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private let tunnel = TunnelChannel()
  private let tunChannel = TunChannel()
  private let helperChannel = HelperChannel()
  private let deepLinkChannel = DeepLinkChannel()

  override func applicationDidFinishLaunching(_ notification: Notification) {
    let controller = mainFlutterWindow?.contentViewController
        as! FlutterViewController
    tunnel.register(with: controller.registrar(forPlugin: "TunnelChannel"))
    tunChannel.register(with: controller.registrar(forPlugin: "TunChannel"))
    helperChannel.register(with: controller.registrar(forPlugin: "HelperChannel"))
    deepLinkChannel.register(with: controller.registrar(forPlugin: "DeepLinkChannel"))
    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(
      _ sender: NSApplication) -> Bool { true }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationWillTerminate(_ notification: Notification) {
    SystemProxy.disableAll()
  }
}
