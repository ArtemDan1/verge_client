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
  TunnelWorker();

  void AppendLogs(const std::string& chunk);
  // Запуск процесса без сброса бюджета повторов — им пользуются и Start, и
  // автоматический перезапуск после конфликта wintun-адаптера.
  std::string Launch(const std::string& config_json);
  void OnCrash(const std::string& reason);

  ChildProcess singbox_;
  std::mutex mutex_;
  std::deque<std::string> logs_;   // накопленные с прошлого TakeLogs
  std::string stopped_reason_;     // причина последнего падения
  bool running_ = false;
  std::string last_config_;        // для автоматического перезапуска
  int adapter_retries_left_ = 0;
  // Растёт на каждом Start и Stop. Отложенный перезапуск сверяется с ним и
  // отменяется, если за время паузы туннель успели остановить или запустить
  // заново — иначе он воскресил бы выключенный пользователем туннель.
  uint64_t generation_ = 0;
};

#endif  // VERGE_TUNNEL_WORKER_H_
