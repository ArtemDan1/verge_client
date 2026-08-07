#include "tunnel_worker.h"

#include <windows.h>

#include <shlobj.h>

#include <thread>

namespace {

// Конфиг пишем в ProgramData, а не в %TEMP%: у LocalSystem свой временный
// каталог, и лезть в него потом для диагностики неудобно. Каталог создаётся
// службой, права наследуются от ProgramData.
std::wstring ConfigPath() {
  wchar_t* base = nullptr;
  if (::SHGetKnownFolderPath(FOLDERID_ProgramData, 0, nullptr, &base) != S_OK) {
    return L"";
  }
  std::wstring dir = std::wstring(base) + L"\\Verge";
  ::CoTaskMemFree(base);
  ::CreateDirectoryW(dir.c_str(), nullptr);
  return dir + L"\\tun-config.json";
}

constexpr size_t kLogLimit = 500;

}  // namespace

TunnelWorker& TunnelWorker::Instance() {
  static TunnelWorker instance;
  return instance;
}

std::string TunnelWorker::Start(const std::string& config_json) {
  {
    std::lock_guard<std::mutex> lock(mutex_);
    last_config_ = config_json;
    // Бюджет автоматических перезапусков сбрасывается только здесь, на явном
    // запуске от пользователя.
    adapter_retries_left_ = 3;
    generation_++;
  }
  return Launch(config_json);
}

// Обработчик падения sing-box.
//
// «Cannot create a file when that file already exists» на configure tun
// interface означает, что wintun-адаптер от прошлого запуска ещё жив.
// Останавливаем мы sing-box через TerminateProcess — послать консольному
// процессу без консоли Ctrl+C на Windows штатно нельзя, — и убитый процесс
// снять адаптер не успевает. Драйвер убирает его сам, но не сразу.
//
// Ловить это по коду возврата Launch бесполезно: sing-box поднимается, живёт
// секунд пятнадцать («open interface take too much time to finish!») и только
// потом валится с FATAL. Стартовый грейс в 800 мс к этому моменту давно прошёл
// и запуск уже засчитан успешным. Поэтому перезапуск живёт именно здесь.
void TunnelWorker::OnCrash(const std::string& reason) {
  std::string config;
  uint64_t generation = 0;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    running_ = false;
    stopped_reason_ = reason;
    if (reason.find("already exists") == std::string::npos ||
        adapter_retries_left_ <= 0) {
      return;
    }
    adapter_retries_left_--;
    config = last_config_;
    generation = generation_;
  }
  // Отдельный поток обязателен: сюда нас позвал поток наблюдения ChildProcess,
  // а Launch внутри делает Stop(), который этот же поток джойнит.
  std::thread([this, config, generation]() {
    // Дать драйверу убрать адаптер: в логах его освобождение занимает секунды.
    ::Sleep(5000);
    {
      std::lock_guard<std::mutex> lock(mutex_);
      // Пока ждали, туннель успели остановить или запустить заново — тогда
      // перезапускать нечего.
      if (generation_ != generation) return;
    }
    Launch(config);
  }).detach();
}

std::string TunnelWorker::Launch(const std::string& config_json) {
  // Мьютекс НЕЛЬЗЯ держать на время singbox_.Start(): при битом конфиге
  // sing-box печатает FATAL и умирает внутри стартового грейса, поток чтения
  // логов зовёт AppendLogs и встаёт на этом же мьютексе, а ChildProcess::Start
  // в ответ на смерть процесса делает join этого потока — служба зависает
  // намертво. Поэтому под замком только правка состояния, а запуск снаружи.
  {
    std::lock_guard<std::mutex> lock(mutex_);
    stopped_reason_.clear();
    running_ = false;
  }
  singbox_.Stop();

  std::wstring path = ConfigPath();
  if (path.empty()) return "не удалось определить каталог для конфига";

  HANDLE f = ::CreateFileW(path.c_str(), GENERIC_WRITE, 0, nullptr,
                           CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (f == INVALID_HANDLE_VALUE) return "не удалось записать конфиг";
  DWORD written = 0;
  BOOL ok = ::WriteFile(f, config_json.data(),
                        static_cast<DWORD>(config_json.size()), &written,
                        nullptr);
  ::CloseHandle(f);
  if (!ok || written != config_json.size()) return "не удалось записать конфиг";

  singbox_.SetOnLog([this](const std::string& chunk) { AppendLogs(chunk); });
  singbox_.SetOnCrash([this](const std::string& reason) { OnCrash(reason); });

  // Путь к бинарю берём свой, а не клиентский: служба под LocalSystem не
  // должна запускать то, что ей назвал непривилегированный процесс.
  std::string err = singbox_.Start(L"sing-box.exe", L"run -c \"" + path + L"\"");

  std::lock_guard<std::mutex> lock(mutex_);
  if (!err.empty()) {
    stopped_reason_ = err;
    return err;
  }
  // Процесс мог успеть упасть уже после возврата из Start: тогда обработчик
  // краха выставил stopped_reason_, и перетирать его на running_ нельзя.
  if (stopped_reason_.empty()) running_ = true;
  return "";
}

void TunnelWorker::Stop() {
  // Мьютекс не держим по той же причине, что и в Start: singbox_.Stop() джойнит
  // поток чтения логов, а тот может стоять на этом мьютексе в AppendLogs.
  singbox_.Stop();
  std::lock_guard<std::mutex> lock(mutex_);
  running_ = false;
  stopped_reason_.clear();
  // Отменяем отложенный перезапуск, если он был запланирован.
  adapter_retries_left_ = 0;
  generation_++;
}

std::string TunnelWorker::Status() {
  std::lock_guard<std::mutex> lock(mutex_);
  if (running_) return "running";
  return "stopped:" + stopped_reason_;
}

std::string TunnelWorker::TakeLogs() {
  std::lock_guard<std::mutex> lock(mutex_);
  std::string out;
  for (const auto& line : logs_) {
    out += line;
    out += '\n';
  }
  logs_.clear();
  return out;
}

void TunnelWorker::AppendLogs(const std::string& chunk) {
  std::lock_guard<std::mutex> lock(mutex_);
  size_t start = 0;
  while (start <= chunk.size()) {
    size_t nl = chunk.find('\n', start);
    std::string line = chunk.substr(
        start, nl == std::string::npos ? std::string::npos : nl - start);
    if (!line.empty() && line != "\r") {
      logs_.push_back(line);
      // Клиент не подключён (приложение закрыли) — буфер иначе рос бы вечно.
      if (logs_.size() > kLogLimit) logs_.pop_front();
    }
    if (nl == std::string::npos) break;
    start = nl + 1;
  }
}
