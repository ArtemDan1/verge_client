import Foundation

/// Управляет системным HTTP/HTTPS прокси через networksetup для выбранных сервисов.
enum SystemProxy {
  private static var enabledServices = Set<String>()

  static func enable(host: String, port: Int, service: String) throws {
    try run(["-setwebproxy", service, host, String(port)])
    try run(["-setsecurewebproxy", service, host, String(port)])
    try run(["-setwebproxystate", service, "on"])
    try run(["-setsecurewebproxystate", service, "on"])
    enabledServices.insert(service)
  }

  static func disable(service: String) {
    try? run(["-setwebproxystate", service, "off"])
    try? run(["-setsecurewebproxystate", service, "off"])
    enabledServices.remove(service)
  }

  /// Снимает прокси со всех сервисов, на которые ставили.
  static func disableAll() {
    for s in Array(enabledServices) { disable(service: s) }
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
      throw NSError(domain: "SystemProxy", code: Int(p.terminationStatus))
    }
    return String(data: data, encoding: .utf8) ?? ""
  }
}
