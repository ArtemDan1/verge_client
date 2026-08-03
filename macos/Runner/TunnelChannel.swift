import FlutterMacOS
import Foundation
import AppKit

/// Связывает MethodChannel singbox/tunnel с процессом, системным прокси и инфо о платформе.
final class TunnelChannel: NSObject, FlutterStreamHandler {
  static let localHost = "127.0.0.1"

  private let singbox = SingboxProcess()
  private var sink: FlutterEventSink?
  private var currentService: String?

  func register(with registrar: FlutterPluginRegistrar) {
    let method = FlutterMethodChannel(
      name: "singbox/tunnel", binaryMessenger: registrar.messenger)
    let events = FlutterEventChannel(
      name: "singbox/tunnel/events", binaryMessenger: registrar.messenger)
    events.setStreamHandler(self)

    singbox.onLog = { [weak self] line in
      self?.sink?(["type": "log", "line": line])
    }

    // Процесс упал сам по себе: снимаем системный прокси (иначе остаётся
    // висячий прокси → ERR_PROXY_CONNECTION_FAILED) и уведомляем Flutter.
    singbox.onCrash = { [weak self] reason in
      guard let self = self else { return }
      SystemProxy.disableAll()
      self.currentService = nil
      self.sink?(["type": "log", "line": "sing-box crashed: \(reason)\n"])
      self.sink?(["type": "status", "value": "error", "message": reason])
    }

    method.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "start":
        self.handleStart(call, result)
      case "stop":
        SystemProxy.disableAll()
        self.currentService = nil
        self.singbox.stop()
        result(nil)
      case "singboxVersion":
        result(self.singboxVersion())
      case "xrayVersion":
        result(self.xrayVersion())
      case "listNetworkServices":
        result(self.listNetworkServices())
      case "defaultService":
        result(self.defaultService())
      case "installUpdate":
        guard let path = call.arguments as? String else {
          result(FlutterError(code: "ARG", message: "no path", details: nil))
          return
        }
        self.installUpdate(path: path, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Открывает скачанный .pkg в Installer.app и выходит из приложения.
  ///
  /// Выйти обязательно: установщик перезаписывает бандл в /Applications под
  /// работающим процессом (ad-hoc подпись → SIGKILL по невалидной подписи), а
  /// postinstall выгружает демона. Если нас убьют вместо штатного выхода,
  /// системный прокси и DNS останутся переопределёнными.
  private func installUpdate(path: String, result: @escaping FlutterResult) {
    // Страховка на случай, если Dart-сторона не успела погасить туннель.
    SystemProxy.disableAll()
    currentService = nil
    singbox.stop()

    guard FileManager.default.fileExists(atPath: path) else {
      result(FlutterError(code: "OPEN", message: "файл не найден: \(path)",
                          details: nil))
      return
    }

    // Открываем дефолтным обработчиком .pkg. Путь к Installer.app не
    // захардкожен: он отличается между версиями macOS (в 15.x —
    // /System/Library/CoreServices, не /System/Applications/Utilities).
    NSWorkspace.shared.open(
      URL(fileURLWithPath: path),
      configuration: NSWorkspace.OpenConfiguration()
    ) { _, error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(code: "OPEN", message: error.localizedDescription,
                              details: nil))
          return
        }
        result(nil)
        // Installer уже запущен и держит файл сам — можно уходить. Небольшая
        // задержка, чтобы result успел уехать в Flutter до терминации.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          NSApp.terminate(nil)
        }
      }
    }
  }

  private func handleStart(_ call: FlutterMethodCall, _ result: FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let cfg = args["config"] as? String,
          let port = args["port"] as? Int,
          let service = args["service"] as? String else {
      result(FlutterError(code: "ARG", message: "bad args", details: nil))
      return
    }
    do {
      try singbox.start(configJSON: cfg)
      try SystemProxy.enable(host: Self.localHost, port: port, service: service)
      currentService = service
      result(nil)
    } catch {
      singbox.stop()
      SystemProxy.disableAll()
      result(FlutterError(code: "START",
              message: error.localizedDescription, details: nil))
    }
  }

  private func singboxVersion() -> String {
    guard let bin = Bundle.main.url(forResource: "sing-box", withExtension: nil)
    else { return "unknown" }
    let p = Process()
    p.executableURL = bin
    p.arguments = ["version"]
    let pipe = Pipe()
    p.standardOutput = pipe
    do { try p.run() } catch { return "unknown" }
    p.waitUntilExit()
    let out = String(
      data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    // первая строка вида "sing-box version 1.13.12"
    let first = out.split(separator: "\n").first.map(String.init) ?? out
    return first.replacingOccurrences(of: "sing-box version ", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// Версия бандленного Xray. Вывод вида
  /// "Xray 26.3.27 (Xray, Penetrates Everything.) d2758a0 (go1.26.1 darwin/arm64)" —
  /// берём второе слово первой строки.
  private func xrayVersion() -> String {
    guard let bin = Bundle.main.url(forResource: "xray", withExtension: nil)
    else { return "unknown" }
    let p = Process()
    p.executableURL = bin
    p.arguments = ["version"]
    let pipe = Pipe()
    p.standardOutput = pipe
    do { try p.run() } catch { return "unknown" }
    // Читаем ДО waitUntilExit: на заполненном пайпе процесс иначе блокируется.
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    let out = String(data: data, encoding: .utf8) ?? ""
    guard let first = out.split(separator: "\n").first else { return "unknown" }
    let parts = first.split(separator: " ")
    return parts.count >= 2 ? String(parts[1]) : "unknown"
  }

  private func runNetworksetup(_ args: [String]) -> String {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
    p.arguments = args
    let pipe = Pipe()
    p.standardOutput = pipe
    do { try p.run() } catch { return "" }
    p.waitUntilExit()
    return String(
      data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
  }

  private func listNetworkServices() -> [String] {
    let out = runNetworksetup(["-listallnetworkservices"])
    return out.split(separator: "\n").map(String.init)
      .filter { !$0.contains("denotes that") && !$0.isEmpty }
  }

  /// Сервис, обслуживающий маршрут по умолчанию (для режима «Авто»).
  private func defaultService() -> String? {
    let route = Process()
    route.executableURL = URL(fileURLWithPath: "/sbin/route")
    route.arguments = ["-n", "get", "default"]
    let rpipe = Pipe()
    route.standardOutput = rpipe
    do { try route.run() } catch { return nil }
    route.waitUntilExit()
    let routeOut = String(
      data: rpipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    guard let ifaceLine = routeOut.split(separator: "\n")
            .first(where: { $0.contains("interface:") }),
          let iface = ifaceLine.split(separator: ":").last?
            .trimmingCharacters(in: .whitespaces)
    else { return nil }

    let order = runNetworksetup(["-listnetworkserviceorder"])
    // Блоки вида: "(1) Wi-Fi\n(Hardware Port: Wi-Fi, Device: en0)"
    let lines = order.split(separator: "\n").map(String.init)
    for (i, line) in lines.enumerated() {
      if line.contains("Device: \(iface)"), i > 0 {
        let nameLine = lines[i - 1]
        if let range = nameLine.range(of: ") ") {
          return String(nameLine[range.upperBound...])
            .trimmingCharacters(in: .whitespaces)
        }
      }
    }
    return nil
  }

  func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink)
      -> FlutterError? { sink = events; return nil }
  func onCancel(withArguments _: Any?) -> FlutterError? { sink = nil; return nil }
}
