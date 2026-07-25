import Foundation

/// Переопределяет системный DNS выбранного сервиса на время TUN.
///
/// В TUN ОС резолвит через системный DNS. Если это адрес LAN-роутера (типичный
/// случай через DHCP), запросы к нему уходят на en0 НАПРЯМУЮ, минуя туннель, и
/// hijack-dns в sing-box их не видит — отравленный DNS провайдера (РФ) ломает
/// заблокированные домены (instagram → 127.0.0.1). Подменяя DNS на публичный
/// адрес, мы заставляем ОС слать запросы в туннель, где их перехватывает sing-box
/// и резолвит через прокси без цензуры. На остановке восстанавливаем исходный DNS.
enum SystemDNS {
  /// Публичный резолвер — важен лишь сам факт «не локальный», чтобы запрос вошёл
  /// в tun; реальным резолвом всё равно занимается hijack-dns внутри sing-box.
  private static let overrideServer = "1.1.1.1"
  private static var saved: [String: [String]] = [:]

  static func enable(service: String) {
    guard !service.isEmpty, saved[service] == nil else { return }
    saved[service] = currentServers(service)
    _ = try? run(["-setdnsservers", service, overrideServer])
  }

  static func disable(service: String) {
    guard let old = saved.removeValue(forKey: service) else { return }
    // networksetup сбрасывает DNS ключевым словом "empty"; иначе перечисляем IP.
    _ = try? run(["-setdnsservers", service] + (old.isEmpty ? ["empty"] : old))
  }

  static func disableAll() {
    for s in Array(saved.keys) { disable(service: s) }
  }

  private static func currentServers(_ service: String) -> [String] {
    let out = (try? run(["-getdnsservers", service])) ?? ""
    // "There aren't any DNS Servers set on <service>." → пусто.
    if out.contains("aren't any") { return [] }
    return out
      .split(separator: "\n")
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }
  }

  @discardableResult
  private static func run(_ args: [String]) throws -> String {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
    p.arguments = args
    let pipe = Pipe()
    p.standardOutput = pipe
    try p.run()
    p.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if p.terminationStatus != 0 {
      throw NSError(domain: "SystemDNS", code: Int(p.terminationStatus))
    }
    return String(data: data, encoding: .utf8) ?? ""
  }
}
