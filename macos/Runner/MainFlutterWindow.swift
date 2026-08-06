import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Крестик сворачивает в трей вместо завершения процесса — VPN должен
    // продолжать работать в фоне. Делегат — сама MainFlutterWindow, а не
    // сторонний пакет: window_manager отдавал этот же результат ненадёжно
    // (гонка между установкой его делегата из Dart и реальным кликом).
    // Полностью завершает работу только «Закрыть» в трее или Cmd+Q — оба идут
    // в обход windowShouldClose (Cmd+Q — через applicationShouldTerminate).
    self.delegate = self

    super.awakeFromNib()
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    sender.orderOut(nil)
    return false
  }
}
