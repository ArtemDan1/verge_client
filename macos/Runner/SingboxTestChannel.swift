import FlutterMacOS
import Foundation

/// Канал `singbox/test` — отдельный процесс sing-box для замера задержки нод.
/// Боевой туннель (`singbox/tunnel`) он не трогает: системный прокси и DNS
/// здесь не переключаются, процесс живёт секунды.
final class SingboxTestChannel: NSObject, FlutterStreamHandler {
  private let singbox = SingboxProcess()

  private var sink: FlutterEventSink?

  func register(with registrar: FlutterPluginRegistrar) {
    let method = FlutterMethodChannel(
      name: "singbox/test", binaryMessenger: registrar.messenger)
    // Лог тестового процесса уходит в общий лог приложения: без него провал
    // замера неотличим от «ноды медленные» — видно только «HTTP не прошёл».
    let events = FlutterEventChannel(
      name: "singbox/test/events", binaryMessenger: registrar.messenger)
    events.setStreamHandler(self)

    singbox.onLog = { [weak self] line in self?.sink?(line) }
    singbox.onCrash = { [weak self] reason in
      self?.sink?("sing-box-test crashed: \(reason)\n")
    }

    method.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "start":
        guard let args = call.arguments as? [String: Any],
              let cfg = args["config"] as? String else {
          result(FlutterError(code: "ARG", message: "bad args", details: nil))
          return
        }
        do {
          try self.singbox.start(configJSON: cfg, processName: "sing-box-test")
          result(nil)
        } catch {
          self.singbox.stop()
          result(FlutterError(code: "START",
                  message: error.localizedDescription, details: nil))
        }
      case "stop":
        self.singbox.stop()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink)
      -> FlutterError? { sink = events; return nil }
  func onCancel(withArguments _: Any?) -> FlutterError? { sink = nil; return nil }
}
