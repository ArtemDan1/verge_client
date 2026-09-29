import Cocoa
import FlutterMacOS

/// Управление главным окном из Dart:
///   show                      — показать главное окно (пункт меню трея);
///   showPopover{width,height} — мини-окно трея под значком;
///   hidePopover{openMain}     — закрыть мини-окно, при openMain — открыть
///                               главное.
/// Обратно в Dart идёт popoverDismissed, когда мини-окно закрылось само.
///
/// Скрытие при закрытии окна крестиком делает сам MainFlutterWindow
/// (windowShouldClose) — нативно, без похода в Dart: пробовали через
/// window_manager, его делегат ненадёжно побеждал гонку установки (см. коммит,
/// добавивший этот файл), и «последнее окно закрыто» срабатывало раньше, чем
/// срабатывал prevent-close.
class WindowControlChannel: NSObject, FlutterPlugin {
  private let channel: FlutterMethodChannel

  init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "window/control", binaryMessenger: registrar.messenger)
    let instance = WindowControlChannel(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
    if let window = mainWindow() {
      window.onPopoverDismissed = { [weak instance] in
        instance?.channel.invokeMethod("popoverDismissed", arguments: nil)
      }
    }
    // Экземпляр держит регистратор, но колбэк окна ссылается на него слабо —
    // сохраняем ещё и здесь, чтобы канал жил столько же, сколько приложение.
    retained = instance
  }

  private static var retained: WindowControlChannel?

  private static func mainWindow() -> MainFlutterWindow? {
    NSApp.windows.compactMap { $0 as? MainFlutterWindow }.first
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let window = Self.mainWindow() else {
      result(FlutterError(code: "NO_WINDOW", message: "Главное окно не найдено", details: nil))
      return
    }
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "show":
      window.showMainWindow()
      result(nil)
    case "showPopover":
      let width = (args["width"] as? NSNumber)?.doubleValue ?? 340
      let height = (args["height"] as? NSNumber)?.doubleValue ?? 420
      window.showPopover(size: NSSize(width: width, height: height))
      result(nil)
    case "hidePopover":
      let openMain = args["openMain"] as? Bool ?? false
      window.exitPopover(showMain: openMain, notify: false)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
