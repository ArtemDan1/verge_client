import Foundation

// HelperProtocol.swift включается в оба таргета (Runner + Helper)
// через Target Membership в Xcode (Task 11).

final class HelperService: NSObject, HelperProtocol, NSXPCListenerDelegate {
  private var process: Process?
  private var lastError: String?
  /// Кольцевой буфер строк лога sing-box: клиент забирает их через fetchLogs.
  private var pending: [String] = []
  private let pendingLimit = 500
  private let pendingLock = NSLock()

  private func append(_ line: String) {
    pendingLock.lock()
    pending.append(line)
    if pending.count > pendingLimit { pending.removeFirst(pending.count - pendingLimit) }
    pendingLock.unlock()
  }

  func fetchLogs(reply: @escaping ([String]) -> Void) {
    pendingLock.lock()
    let out = pending
    pending.removeAll()
    pendingLock.unlock()
    reply(out)
  }

  func version(reply: @escaping (String) -> Void) { reply("1.0.0") }

  func startTun(configJSON: String, singboxPath: String,
                reply: @escaping (Bool, String?) -> Void) {
    stopProcess() // на всякий случай
    pendingLock.lock(); pending.removeAll(); pendingLock.unlock()
    // Безопасность: запускаем только бинарник из app bundle, переданный клиентом.
    guard FileManager.default.isExecutableFile(atPath: singboxPath) else {
      reply(false, "binary not executable: \(singboxPath)")
      return
    }
    let dir = FileManager.default.temporaryDirectory
    let cfg = dir.appendingPathComponent("singbox-tun.json")
    do {
      try configJSON.write(to: cfg, atomically: true, encoding: .utf8)
    } catch {
      reply(false, "write config: \(error.localizedDescription)")
      return
    }
    let p = Process()
    p.executableURL = URL(fileURLWithPath: singboxPath)
    p.arguments = ["run", "-c", cfg.path]
    let pipe = Pipe()
    p.standardError = pipe
    p.standardOutput = pipe
    pipe.fileHandleForReading.readabilityHandler = { [weak self] h in
      let s = String(data: h.availableData, encoding: .utf8) ?? ""
      // Запоминаем только строки, похожие на ошибку/фатал, чтобы обычный
      // info-лог не перетирал реальную причину падения.
      for line in s.split(separator: "\n") {
        self?.append(String(line))
        let l = line.lowercased()
        if l.contains("error") || l.contains("fatal") || l.contains("panic") {
          self?.lastError = String(line)
        }
      }
    }
    p.terminationHandler = { [weak self] proc in
      if proc.terminationStatus != 0 {
        self?.lastError = "sing-box exited \(proc.terminationStatus)"
        self?.append("sing-box exited \(proc.terminationStatus)")
      }
      self?.process = nil
    }
    do {
      try p.run()
      process = p
      lastError = nil
      reply(true, nil)
    } catch {
      reply(false, "spawn: \(error.localizedDescription)")
    }
  }

  func stopTun(reply: @escaping () -> Void) {
    stopProcess()
    reply()
  }

  func status(reply: @escaping (String) -> Void) {
    if process?.isRunning == true {
      reply("running")
    } else {
      reply("stopped:\(lastError ?? "")")
    }
  }

  func stopProcess() {
    guard let p = process else { return }
    p.terminate() // SIGTERM
    // Эскалация: если sing-box не вышел за 2с, добиваем SIGKILL,
    // иначе utun и маршруты останутся висеть.
    let deadline = Date().addingTimeInterval(2)
    while p.isRunning && Date() < deadline {
      usleep(50_000)
    }
    if p.isRunning {
      kill(p.processIdentifier, SIGKILL)
    }
    process = nil
  }

  // MARK: NSXPCListenerDelegate
  func listener(_ listener: NSXPCListener,
                shouldAcceptNewConnection conn: NSXPCConnection) -> Bool {
    conn.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
    conn.exportedObject = self
    conn.invalidationHandler = { [weak self] in self?.stopProcess() }
    conn.resume()
    return true
  }
}

// Failsafe (уровень 2): при остановке/выгрузке демона launchd шлёт SIGTERM —
// перед выходом обязательно убиваем дочерний sing-box, иначе utun и маршруты
// останутся, и пользователь застрянет в туннеле.
let service = HelperService()
let listener = NSXPCListener(machServiceName: kHelperMachServiceName)
listener.delegate = service

// Игнорируем дефолтную обработку и снимаем процесс через безопасный
// DispatchSource (обработчики сигналов не могут вызывать произвольный код).
signal(SIGTERM, SIG_IGN)
let sigSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
sigSource.setEventHandler {
  service.stopProcess()
  exit(0)
}
sigSource.resume()

listener.resume()
RunLoop.current.run()
