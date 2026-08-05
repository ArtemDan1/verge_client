import FlutterMacOS
import Foundation

/// Канал `xray/test` — отдельный процесс Xray для замера задержки нод,
/// которые sing-box не поднимает (hysteria2, vless+xhttp).
final class XrayTestChannel: NSObject, FlutterStreamHandler {
  private let xray = XrayProcess()

  private var sink: FlutterEventSink?

  func register(with registrar: FlutterPluginRegistrar) {
    let method = FlutterMethodChannel(
      name: "xray/test", binaryMessenger: registrar.messenger)
    // Лог тестового процесса уходит в общий лог приложения: без него провал
    // замера неотличим от «ноды медленные» — видно только «HTTP не прошёл».
    let events = FlutterEventChannel(
      name: "xray/test/events", binaryMessenger: registrar.messenger)
    events.setStreamHandler(self)

    xray.onLog = { [weak self] line in self?.sink?(line) }
    xray.onCrash = { [weak self] reason in
      self?.sink?("xray-test crashed: \(reason)\n")
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
          try self.xray.start(configJSON: cfg)
          result(nil)
        } catch {
          self.xray.stop()
          result(FlutterError(code: "START",
                  message: error.localizedDescription, details: nil))
        }
      case "stop":
        self.xray.stop()
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
