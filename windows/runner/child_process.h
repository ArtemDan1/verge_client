#ifndef RUNNER_CHILD_PROCESS_H_
#define RUNNER_CHILD_PROCESS_H_

#include <windows.h>

#include <atomic>
#include <deque>
#include <functional>
#include <mutex>
#include <string>
#include <thread>

// Жизненный цикл дочернего процесса (sing-box, xray).
//
// Зеркало macos/Runner/SingboxProcess.swift. Отличия от macOS:
//  * Job Object с JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE — гарантия, что процесс
//    умрёт вместе с приложением даже при аварийном завершении UI. На macOS
//    осиротевший sing-box просто держал бы прокси, здесь это критичнее.
//  * Вместо readabilityHandler — фоновый поток на ReadFile из пайпа.
class ChildProcess {
 public:
  ChildProcess();
  ~ChildProcess();

  void SetOnLog(std::function<void(const std::string&)> cb) { on_log_ = cb; }
  void SetOnCrash(std::function<void(const std::string&)> cb) { on_crash_ = cb; }

  // Пустая строка — успех, иначе причина ошибки (уже человекочитаемая).
  std::string Start(const std::wstring& exe_name, const std::wstring& args);
  void Stop();

  // Каталог, в котором лежит runner.exe (там же вендоренные бинарники).
  static std::wstring ExeDir();
  // Пишет конфиг в %TEMP%\<name> и возвращает полный путь.
  static std::wstring WriteTempConfig(const std::string& json,
                                      const std::wstring& name);
  // Разовый запуск с чтением stdout до конца (для `version`).
  static std::string RunAndCapture(const std::wstring& exe_name,
                                   const std::wstring& args);

 private:
  void PumpLogs(HANDLE read_end);
  // Получает СВОЮ копию хэндла процесса и закрывает её сам: Stop() закрывает
  // process_ не дожидаясь этого потока, и общий хэндл система успела бы отдать
  // под другой объект.
  void WatchExit(HANDLE process);
  void AppendTail(const std::string& chunk);
  std::string CrashReason(DWORD exit_code);

  HANDLE job_ = nullptr;
  HANDLE process_ = nullptr;
  std::thread log_thread_;
  std::thread watch_thread_;
  std::atomic<bool> stopping_{false};

  std::mutex tail_mutex_;
  std::deque<std::string> tail_;  // последние 40 строк для диагностики краха

  std::function<void(const std::string&)> on_log_;
  std::function<void(const std::string&)> on_crash_;
};

#endif  // RUNNER_CHILD_PROCESS_H_
