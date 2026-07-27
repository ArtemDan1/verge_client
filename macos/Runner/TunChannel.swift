import FlutterMacOS
import Foundation
import AppKit

/// MethodChannel singbox/tun + EventChannel singbox/tun/events.
/// Проксирует start/stop привилегированному helper по XPC.
final class TunChannel: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?
  private var connection: NSXPCConnection?
  private var pollTimer: Timer?
  /// Сетевой сервис, на котором переопределён DNS, — чтобы восстановить на стопе.
  private var dnsService: String?

  func register(with registrar: FlutterPluginRegistrar) {
    let method = FlutterMethodChannel(
      name: "singbox/tun", binaryMessenger: registrar.messenger)
    let events = FlutterEventChannel(
      name: "singbox/tun/events", binaryMessenger: registrar.messenger)
    events.setStreamHandler(self)

    method.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "start":
        guard let args = call.arguments as? [String: Any],
              let cfg = args["config"] as? String else {
          result(FlutterError(code: "ARG", message: "no config", details: nil))
          return
        }
        let service = args["service"] as? String ?? ""
        self.start(configJSON: cfg, service: service, result: result)
      case "stop":
        self.stop(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func connect() -> NSXPCConnection {
    if let c = connection { return c }
    let c = NSXPCConnection(machServiceName: kHelperMachServiceName,
                            options: .privileged)
    c.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
    c.invalidationHandler = { [weak self] in self?.connection = nil }
    c.resume()
    connection = c
    return c
  }

  /// Прокси с обработчиком ошибок XPC. Если helper недоступен (не установлен,
  /// не подтверждён, упал), вызывается onError — без него reply-блок мог бы
  /// никогда не сработать и Dart-вызов завис бы навсегда.
  private func helper(onError: @escaping (Error) -> Void) -> HelperProtocol? {
    return connect().remoteObjectProxyWithErrorHandler { err in
      DispatchQueue.main.async { onError(err) }
    } as? HelperProtocol
  }

  private func singboxPath() -> String? {
    Bundle.main.url(forResource: "sing-box", withExtension: nil)?.path
  }

  private func start(configJSON: String, service: String,
                     result: @escaping FlutterResult) {
    guard let path = singboxPath() else {
      result(FlutterError(code: "BIN", message: "sing-box not bundled", details: nil))
      return
    }
    // Гарантируем ровно один вызов result (успех/ошибка/XPC-сбой).
    var replied = false
    let reply: (FlutterError?) -> Void = { [weak self] err in
      guard !replied else { return }
      replied = true
      if let err = err {
        self?.sink?(["type": "log", "line": err.message ?? "tun start failed"])
        self?.sink?(["type": "status", "value": "error"])
        result(err)
      } else {
        // Переопределяем системный DNS, чтобы запросы вошли в туннель и их
        // перехватил hijack-dns (иначе DNS к LAN-роутеру минует tun → цензура).
        if !service.isEmpty {
          self?.dnsService = service
          SystemDNS.enable(service: service)
        }
        self?.sink?(["type": "status", "value": "connected"])
        self?.startPolling()
        result(nil)
      }
    }
    guard let h = helper(onError: { e in
      reply(FlutterError(code: "XPC", message: e.localizedDescription, details: nil))
    }) else {
      reply(FlutterError(code: "XPC", message: "helper unavailable", details: nil))
      return
    }
    h.startTun(configJSON: configJSON, singboxPath: path) { ok, err in
      DispatchQueue.main.async {
        reply(ok ? nil : FlutterError(code: "START", message: err ?? "start failed", details: nil))
      }
    }
  }

  /// Возвращает системный DNS сервиса в исходное состояние (идемпотентно).
  private func restoreDNS() {
    if let s = dnsService {
      SystemDNS.disable(service: s)
      dnsService = nil
    }
  }

  private func stop(result: @escaping FlutterResult) {
    pollTimer?.invalidate()
    restoreDNS()
    var replied = false
    let done: () -> Void = { [weak self] in
      guard !replied else { return }
      replied = true
      self?.sink?(["type": "status", "value": "disconnected"])
      result(nil)
    }
    guard let h = helper(onError: { _ in done() }) else {
      done()
      return
    }
    h.stopTun { DispatchQueue.main.async { done() } }
  }

  private func startPolling() {
    pollTimer?.invalidate()
    pollTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
      guard let self = self else { return }
      let h = self.helper(onError: { _ in
        // Соединение с helper потеряно → считаем туннель упавшим.
        self.sink?(["type": "status", "value": "error"])
        self.pollTimer?.invalidate()
        self.restoreDNS()
      })
      // Логи sing-box helper копит у себя — забираем их тем же тиком.
      h?.fetchLogs { lines in
        guard !lines.isEmpty else { return }
        DispatchQueue.main.async {
          for line in lines { self.sink?(["type": "log", "line": line]) }
        }
      }
      h?.status { st in
        DispatchQueue.main.async {
          if st.hasPrefix("stopped") {
            let err = String(st.dropFirst("stopped:".count))
            if !err.isEmpty { self.sink?(["type": "log", "line": err]) }
            self.sink?(["type": "status", "value": "error"])
            self.pollTimer?.invalidate()
            self.restoreDNS()
          }
        }
      }
    }
  }

  func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink)
      -> FlutterError? { sink = events; return nil }
  func onCancel(withArguments _: Any?) -> FlutterError? { sink = nil; return nil }
}
