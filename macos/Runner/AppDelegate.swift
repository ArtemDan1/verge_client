import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private let tunnel = TunnelChannel()
  private let tunChannel = TunChannel()
  private let helperChannel = HelperChannel()
  private let deepLinkChannel = DeepLinkChannel()
  private let xrayChannel = XrayChannel()
  private let singboxTestChannel = SingboxTestChannel()
  private let xrayTestChannel = XrayTestChannel()

  override func applicationDidFinishLaunching(_ notification: Notification) {
    let controller = mainFlutterWindow?.contentViewController
        as! FlutterViewController
    tunnel.register(with: controller.registrar(forPlugin: "TunnelChannel"))
    tunChannel.register(with: controller.registrar(forPlugin: "TunChannel"))
    helperChannel.register(with: controller.registrar(forPlugin: "HelperChannel"))
    deepLinkChannel.register(with: controller.registrar(forPlugin: "DeepLinkChannel"))
    xrayChannel.register(with: controller.registrar(forPlugin: "XrayChannel"))
    singboxTestChannel.register(with: controller.registrar(forPlugin: "SingboxTestChannel"))
    xrayTestChannel.register(with: controller.registrar(forPlugin: "XrayTestChannel"))
    WindowControlChannel.register(with: controller.registrar(forPlugin: "WindowControlChannel"))
    super.applicationDidFinishLaunching(notification)
  }

  // false: закрытие окна крестиком теперь перехватывает MainFlutterWindow
  // (windowShouldClose -> hide, не close), так что это делегатское срабатывание
  // означало бы, что окно ЗАКРЫЛОСЬ по-настоящему (наш обычный случай — Cmd+Q
  // или «Закрыть» из трея — завершает процесс через exit(0)/NSApp.terminate
  // напрямую, минуя этот путь).
  override func applicationShouldTerminateAfterLastWindowClosed(
      _ sender: NSApplication) -> Bool { false }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // Крестик прячет окно через orderOut (см. MainFlutterWindow.windowShouldClose),
  // а не закрывает его — но по умолчанию клик по иконке в Dock не поднимает
  // такое "скрытое, но не закрытое" окно обратно. Тот же makeKeyAndOrderFront +
  // activate, что уже делает пункт "Открыть" в трее (WindowControlChannel).
  override func applicationShouldHandleReopen(
      _ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    mainFlutterWindow?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    return true
  }

  override func applicationWillTerminate(_ notification: Notification) {
    SystemProxy.disableAll()
  }
}
