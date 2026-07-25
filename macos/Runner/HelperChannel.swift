import FlutterMacOS
import Foundation

/// MethodChannel singbox/helper — проверка доступности привилегированного демона.
/// Демон ставится отдельным .pkg (классический LaunchDaemon в /Library/LaunchDaemons).
/// Приложение его НЕ регистрирует, только пингует по XPC: достучались = 'enabled'.
final class HelperChannel {
  func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "singbox/helper", binaryMessenger: registrar.messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "status":
        HelperChannel.ping { reachable in
          result(reachable ? "enabled" : "notRegistered")
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Пингует helper по XPC (version()). Если демон не установлен/не запущен,
  /// сработает error-handler соединения → reachable=false. Ровно один вызов done.
  private static func ping(_ done: @escaping (Bool) -> Void) {
    let conn = NSXPCConnection(machServiceName: kHelperMachServiceName,
                              options: .privileged)
    conn.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
    conn.resume()
    var replied = false
    let finish: (Bool) -> Void = { ok in
      guard !replied else { return }
      replied = true
      conn.invalidate()
      DispatchQueue.main.async { done(ok) }
    }
    let proxy = conn.remoteObjectProxyWithErrorHandler { _ in finish(false) }
      as? HelperProtocol
    guard let proxy = proxy else { finish(false); return }
    proxy.version { _ in finish(true) }
    // Страховка от зависания, если ни reply, ни error не пришли за 3с.
    DispatchQueue.global().asyncAfter(deadline: .now() + 3) { finish(false) }
  }
}
