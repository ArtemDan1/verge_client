import Foundation

/// XPC-контракт между приложением и привилегированным helper-демоном.
/// Используется и в Runner (клиент), и в Helper (сервер).
@objc public protocol HelperProtocol {
  func version(reply: @escaping (String) -> Void)
  func startTun(configJSON: String, singboxPath: String,
                reply: @escaping (Bool, String?) -> Void)
  func stopTun(reply: @escaping () -> Void)
  func status(reply: @escaping (String) -> Void) // "running" | "stopped:<err>"
  /// Отдаёт накопленные с прошлого вызова строки лога sing-box и очищает буфер.
  /// Клиент опрашивает периодически — обратный XPC-канал не нужен.
  func fetchLogs(reply: @escaping ([String]) -> Void)
}

public let kHelperMachServiceName = "com.singboxclient.helper"
