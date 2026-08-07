import Cocoa
import FlutterMacOS

/// Показ/скрытие главного окна из Dart (тап «Открыть» в меню трея). Скрытие
/// при закрытии окна крестиком делает сам MainFlutterWindow (windowShouldClose)
/// — нативно, без похода в Dart: пробовали через window_manager, его делегат
/// ненадёжно побеждал гонку установки (см. коммит, добавивший этот файл), и
/// «последнее окно закрыто» срабатывало раньше, чем срабатывал prevent-close.
class WindowControlChannel: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "window/control", binaryMessenger: registrar.messenger)
    registrar.addMethodCallDelegate(WindowControlChannel(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let window = NSApp.windows.first else {
      result(FlutterError(code: "NO_WINDOW", message: "Главное окно не найдено", details: nil))
      return
    }
    switch call.method {
    case "show":
      window.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
