import Foundation

/// Жизненный цикл дочернего процесса Xray-core.
///
/// Xray работает «глупым» нижним звеном: у него один socks-inbound на loopback и
/// один outbound. Роутинг, DNS и системный прокси контролирует sing-box.
final class XrayProcess {
  private var process: Process?
  var onLog: ((String) -> Void)?
  var onCrash: ((String) -> Void)?

  private var stopping = false
  private var logTail: [String] = []
  private let logTailLimit = 40
  private let logLock = NSLock()

  /// Даём процессу время на FATAL некорректного конфига, прежде чем считать
  /// старт успешным.
  private let startupGrace: TimeInterval = 0.8

  func start(configJSON: String) throws {
    let dir = FileManager.default.temporaryDirectory
    let cfg = dir.appendingPathComponent("xray-config.json")
    try configJSON.write(to: cfg, atomically: true, encoding: .utf8)

    guard let bin = Bundle.main.url(forResource: "xray", withExtension: nil)
    else {
      throw NSError(domain: "Xray", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "xray binary not bundled"])
    }

    stopping = false
    logLock.lock(); logTail.removeAll(); logLock.unlock()

    let p = Process()
    p.executableURL = bin
    p.arguments = ["run", "-config", cfg.path]
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = pipe
    pipe.fileHandleForReading.readabilityHandler = { [weak self] h in
      let data = h.availableData
      guard let self = self,
            let s = String(data: data, encoding: .utf8), !s.isEmpty else { return }
      self.appendLog(s)
      self.onLog?(s)
    }

    p.terminationHandler = { [weak self] proc in
      guard let self = self, !self.stopping else { return }
      let reason = self.crashReason(code: proc.terminationStatus)
      DispatchQueue.main.async { self.onCrash?(reason) }
    }

    try p.run()
    process = p

    Thread.sleep(forTimeInterval: startupGrace)
    if !p.isRunning {
      let reason = crashReason(code: p.terminationStatus)
      process = nil
      throw NSError(domain: "Xray", code: 2,
                    userInfo: [NSLocalizedDescriptionKey: reason])
    }
  }

  func stop() {
    stopping = true
    if let p = process {
      p.terminationHandler = nil
      p.terminate()
    }
    process = nil
  }

  private func appendLog(_ s: String) {
    logLock.lock(); defer { logLock.unlock() }
    for line in s.split(separator: "\n") {
      logTail.append(String(line))
      if logTail.count > logTailLimit { logTail.removeFirst() }
    }
  }

  private func crashReason(code: Int32) -> String {
    logLock.lock()
    let tail = logTail
    logLock.unlock()
    if let fatal = tail.last(where: {
      $0.localizedCaseInsensitiveContains("FATAL") ||
      $0.localizedCaseInsensitiveContains("ERROR")
    }) {
      return stripAnsi(fatal)
    }
    return "xray завершился (код \(code))"
  }

  private func stripAnsi(_ s: String) -> String {
    let pattern = "\u{001B}\\[[0-9;]*m"
    guard let re = try? NSRegularExpression(pattern: pattern) else { return s }
    let range = NSRange(s.startIndex..., in: s)
    return re.stringByReplacingMatches(in: s, range: range, withTemplate: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
