import Foundation

/// Жизненный цикл дочернего процесса sing-box.
final class SingboxProcess {
  private var process: Process?
  var onLog: ((String) -> Void)?

  /// Вызывается, когда процесс завершился САМ (не через stop()) — т.е. упал.
  /// Передаёт причину (обычно строку FATAL из лога).
  var onCrash: ((String) -> Void)?

  /// true, пока идёт намеренная остановка — чтобы не считать её крахом.
  private var stopping = false

  /// Кольцевой буфер последних строк лога для диагностики краха.
  private var logTail: [String] = []
  private let logTailLimit = 40
  private let logLock = NSLock()

  /// Сколько ждём после запуска, прежде чем считать старт успешным.
  /// За это время вылезает FATAL некорректного конфига.
  private let startupGrace: TimeInterval = 0.8

  func start(configJSON: String) throws {
    let dir = FileManager.default.temporaryDirectory
    let cfg = dir.appendingPathComponent("singbox-config.json")
    try configJSON.write(to: cfg, atomically: true, encoding: .utf8)

    guard let bin = Bundle.main.url(forResource: "sing-box", withExtension: nil)
    else { throw NSError(domain: "Singbox", code: 1,
            userInfo: [NSLocalizedDescriptionKey: "binary not bundled"]) }

    stopping = false
    logLock.lock(); logTail.removeAll(); logLock.unlock()

    let p = Process()
    p.executableURL = bin
    p.arguments = ["run", "-c", cfg.path]
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
      // Процесс умер сам по себе — это крах.
      let reason = self.crashReason(code: proc.terminationStatus)
      DispatchQueue.main.async { self.onCrash?(reason) }
    }

    try p.run()
    process = p

    // Проверка живости: даём процессу мгновение и убеждаемся, что он не упал
    // сразу (битый конфиг, FATAL и т.п.). Иначе системный прокси включится
    // поверх мёртвого sing-box → ERR_PROXY_CONNECTION_FAILED.
    Thread.sleep(forTimeInterval: startupGrace)
    if !p.isRunning {
      let reason = crashReason(code: p.terminationStatus)
      process = nil
      throw NSError(domain: "Singbox", code: 2,
              userInfo: [NSLocalizedDescriptionKey: reason])
    }
  }

  func stop() {
    stopping = true
    if let p = process {
      // Отвязываем обработчик завершения у ИМЕННО этого процесса: иначе его
      // асинхронная смерть после уже запущенного start() будет ошибочно
      // воспринята как краш (terminationHandler видит stopping == false).
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

  /// Достаёт человекочитаемую причину: строку FATAL/ERROR из лога, иначе код.
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
    return "sing-box завершился (код \(code))"
  }

  /// Убирает ANSI-коды цвета из строки лога.
  private func stripAnsi(_ s: String) -> String {
    let pattern = "\u{001B}\\[[0-9;]*m"
    guard let re = try? NSRegularExpression(pattern: pattern) else { return s }
    let range = NSRange(s.startIndex..., in: s)
    return re.stringByReplacingMatches(in: s, range: range, withTemplate: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
