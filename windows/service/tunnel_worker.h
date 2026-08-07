#ifndef VERGE_TUNNEL_WORKER_H_
#define VERGE_TUNNEL_WORKER_H_

#include <deque>
#include <mutex>
#include <string>

#include "child_process.h"

// Состояние туннеля внутри службы. Singleton: служба однопользовательская,
// туннель в системе может быть только один.
class TunnelWorker {
 public:
  static TunnelWorker& Instance();

  // Пустая строка — успех, иначе причина.
  std::string Start(const std::string& config_json);
  void Stop();
  // "running" либо "stopped:<причина>".
  std::string Status();
  // Накопленные строки лога через '\n'; буфер очищается.
  std::string TakeLogs();

 private:
  TunnelWorker() = default;

  void AppendLogs(const std::string& chunk);

  ChildProcess singbox_;
  std::mutex mutex_;
  std::deque<std::string> logs_;   // накопленные с прошлого TakeLogs
  std::string stopped_reason_;     // причина последнего падения
  bool running_ = false;
};

#endif  // VERGE_TUNNEL_WORKER_H_
