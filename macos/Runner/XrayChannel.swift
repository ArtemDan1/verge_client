import FlutterMacOS
import Foundation

/// MethodChannel/EventChannel для дочернего процесса Xray-core.
final class XrayChannel: NSObject, FlutterStreamHandler {
  private let xray = XrayProcess()
  private var sink: FlutterEventSink?

  func register(with registrar: FlutterPluginRegistrar) {
    let method = FlutterMethodChannel(
      name: "singbox/xray", binaryMessenger: registrar.messenger)
    let events = FlutterEventChannel(
      name: "singbox/xray/events", binaryMessenger: registrar.messenger)
    events.setStreamHandler(self)

    xray.onLog = { [weak self] line in
      self?.sink?(["type": "log", "line": line])
    }

    xray.onCrash = { [weak self] reason in
      guard let self = self else { return }
      self.sink?(["type": "log", "line": "xray crashed: \(reason)\n"])
    }

    method.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "start":
        self.handleStart(call, result)
      case "stop":
        self.xray.stop()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func handleStart(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let cfg = args["config"] as? String else {
      result(FlutterError(code: "ARG", message: "bad args", details: nil))
      return
    }
    do {
      try xray.start(configJSON: cfg)
      result(nil)
    } catch {
      xray.stop()
      result(FlutterError(code: "START",
              message: error.localizedDescription, details: nil))
    }
  }

  func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink)
      -> FlutterError? { sink = events; return nil }
  func onCancel(withArguments _: Any?) -> FlutterError? { sink = nil; return nil }
}
