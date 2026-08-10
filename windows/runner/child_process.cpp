#include "child_process.h"

#include <algorithm>
#include <regex>
#include <vector>

namespace {

constexpr size_t kTailLimit = 40;
// Столько ждём после старта, прежде чем считать запуск успешным: за это время
// вылезает FATAL битого конфига. Совпадает с macOS (startupGrace = 0.8).
constexpr DWORD kStartupGraceMs = 800;

std::string StripAnsi(const std::string& s) {
  static const std::regex re("\x1B\\[[0-9;]*m");
  return std::regex_replace(s, re, "");
}

std::string Trim(const std::string& s) {
  size_t b = s.find_first_not_of(" \t\r\n");
  if (b == std::string::npos) return "";
  size_t e = s.find_last_not_of(" \t\r\n");
  return s.substr(b, e - b + 1);
}

// Сужение wchar_t → char через конструктор std::string от итераторов даёт
// C4244, а в сборке Flutter предупреждения трактуются как ошибки. Да и по сути
// оно неверно: имя файла вне ASCII превратилось бы в мусор.
std::string Narrow(const std::wstring& s) {
  if (s.empty()) return "";
  int len = ::WideCharToMultiByte(CP_UTF8, 0, s.c_str(),
                                  static_cast<int>(s.size()), nullptr, 0,
                                  nullptr, nullptr);
  std::string out(static_cast<size_t>(len), '\0');
  ::WideCharToMultiByte(CP_UTF8, 0, s.c_str(), static_cast<int>(s.size()),
                        out.data(), len, nullptr, nullptr);
  return out;
}

// Обработчик-заглушка на время рассылки Ctrl+Break.
//
// Вернуть TRUE значит «событие обработано» — система не применяет к нам
// действие по умолчанию, то есть не завершает процесс. Настоящая функция здесь
// обязательна: SetConsoleCtrlHandler(nullptr, TRUE) подавляет ТОЛЬКО Ctrl+C, а
// Ctrl+Break этим способом не заглушить, и процесс всё равно будет убит.
BOOL WINAPI IgnoreConsoleCtrl(DWORD type) {
  return type == CTRL_BREAK_EVENT || type == CTRL_C_EVENT;
}

bool ContainsNoCase(const std::string& hay, const std::string& needle) {
  auto it = std::search(hay.begin(), hay.end(), needle.begin(), needle.end(),
                        [](char a, char b) {
                          return ::toupper(a) == ::toupper(b);
                        });
  return it != hay.end();
}

}  // namespace

ChildProcess::ChildProcess() {}

ChildProcess::~ChildProcess() { Stop(); }

std::wstring ChildProcess::ExeDir() {
  wchar_t path[MAX_PATH] = {};
  ::GetModuleFileNameW(nullptr, path, MAX_PATH);
  std::wstring s(path);
  size_t slash = s.find_last_of(L'\\');
  return slash == std::wstring::npos ? L"." : s.substr(0, slash);
}

std::wstring ChildProcess::WriteTempConfig(const std::string& json,
                                           const std::wstring& name) {
  wchar_t temp[MAX_PATH] = {};
  ::GetTempPathW(MAX_PATH, temp);
  std::wstring path = std::wstring(temp) + name;
  HANDLE f = ::CreateFileW(path.c_str(), GENERIC_WRITE, 0, nullptr,
                           CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (f == INVALID_HANDLE_VALUE) return L"";
  DWORD written = 0;
  ::WriteFile(f, json.data(), static_cast<DWORD>(json.size()), &written,
              nullptr);
  ::CloseHandle(f);
  return path;
}

std::string ChildProcess::RunAndCapture(const std::wstring& exe_name,
                                        const std::wstring& args) {
  SECURITY_ATTRIBUTES sa{sizeof(sa), nullptr, TRUE};
  HANDLE read_end = nullptr, write_end = nullptr;
  if (!::CreatePipe(&read_end, &write_end, &sa, 0)) return "";
  ::SetHandleInformation(read_end, HANDLE_FLAG_INHERIT, 0);

  std::wstring exe = ExeDir() + L"\\" + exe_name;
  std::wstring cmd = L"\"" + exe + L"\" " + args;
  std::vector<wchar_t> mutable_cmd(cmd.begin(), cmd.end());
  mutable_cmd.push_back(L'\0');

  STARTUPINFOW si{};
  si.cb = sizeof(si);
  si.dwFlags = STARTF_USESTDHANDLES;
  si.hStdOutput = write_end;
  si.hStdError = write_end;
  PROCESS_INFORMATION pi{};
  BOOL ok = ::CreateProcessW(exe.c_str(), mutable_cmd.data(), nullptr, nullptr,
                             TRUE, CREATE_NO_WINDOW, nullptr, nullptr, &si, &pi);
  ::CloseHandle(write_end);
  if (!ok) {
    ::CloseHandle(read_end);
    return "";
  }
  // Читаем ДО ожидания выхода: на заполненном пайпе процесс иначе блокируется
  // (та же грабля, что описана в macOS-версии xrayVersion).
  std::string out;
  char buf[4096];
  DWORD read = 0;
  while (::ReadFile(read_end, buf, sizeof(buf), &read, nullptr) && read > 0) {
    out.append(buf, read);
  }
  ::WaitForSingleObject(pi.hProcess, 5000);
  ::CloseHandle(read_end);
  ::CloseHandle(pi.hProcess);
  ::CloseHandle(pi.hThread);
  return out;
}

std::string ChildProcess::Start(const std::wstring& exe_name,
                                const std::wstring& args) {
  Stop();
  stopping_ = false;
  {
    std::lock_guard<std::mutex> lock(tail_mutex_);
    tail_.clear();
  }

  SECURITY_ATTRIBUTES sa{sizeof(sa), nullptr, TRUE};
  HANDLE read_end = nullptr, write_end = nullptr;
  if (!::CreatePipe(&read_end, &write_end, &sa, 0)) {
    return "не удалось создать пайп";
  }
  ::SetHandleInformation(read_end, HANDLE_FLAG_INHERIT, 0);

  std::wstring exe = ExeDir() + L"\\" + exe_name;
  std::wstring cmd = L"\"" + exe + L"\" " + args;
  std::vector<wchar_t> mutable_cmd(cmd.begin(), cmd.end());
  mutable_cmd.push_back(L'\0');

  STARTUPINFOW si{};
  si.cb = sizeof(si);
  si.dwFlags = STARTF_USESTDHANDLES;
  si.hStdOutput = write_end;
  si.hStdError = write_end;
  PROCESS_INFORMATION pi{};
  // CREATE_NEW_PROCESS_GROUP — чтобы процессу можно было адресно послать
  // Ctrl+Break (см. StopGracefully). Ctrl+C в такой группе отключён, но нам он
  // и не нужен. CREATE_NO_WINDOW оставляет процессу консоль, просто без окна, —
  // именно к ней мы потом и цепляемся.
  BOOL ok = ::CreateProcessW(
      exe.c_str(), mutable_cmd.data(), nullptr, nullptr, TRUE,
      CREATE_NO_WINDOW | CREATE_SUSPENDED | CREATE_NEW_PROCESS_GROUP, nullptr,
      nullptr, &si, &pi);
  ::CloseHandle(write_end);
  if (!ok) {
    ::CloseHandle(read_end);
    return "не удалось запустить " + Narrow(exe_name);
  }

  // Job Object: процесс умрёт вместе с нами, даже если нас убьют.
  job_ = ::CreateJobObjectW(nullptr, nullptr);
  JOBOBJECT_EXTENDED_LIMIT_INFORMATION limits{};
  limits.BasicLimitInformation.LimitFlags =
      JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
  ::SetInformationJobObject(job_, JobObjectExtendedLimitInformation, &limits,
                            sizeof(limits));
  ::AssignProcessToJobObject(job_, pi.hProcess);
  ::ResumeThread(pi.hThread);
  ::CloseHandle(pi.hThread);

  process_ = pi.hProcess;
  pid_ = pi.dwProcessId;
  log_thread_ = std::thread(&ChildProcess::PumpLogs, this, read_end);

  // Проверка живости: если конфиг битый, процесс успеет упасть за grace.
  if (::WaitForSingleObject(process_, kStartupGraceMs) == WAIT_OBJECT_0) {
    DWORD code = 0;
    ::GetExitCodeProcess(process_, &code);
    std::string reason = CrashReason(code);
    Stop();
    return reason;
  }
  HANDLE watch_handle = nullptr;
  ::DuplicateHandle(::GetCurrentProcess(), process_, ::GetCurrentProcess(),
                    &watch_handle, 0, FALSE, DUPLICATE_SAME_ACCESS);
  watch_thread_ = std::thread(&ChildProcess::WatchExit, this, watch_handle);
  return "";
}

void ChildProcess::PumpLogs(HANDLE read_end) {
  char buf[4096];
  DWORD read = 0;
  while (::ReadFile(read_end, buf, sizeof(buf), &read, nullptr) && read > 0) {
    std::string chunk(buf, read);
    AppendTail(chunk);
    if (on_log_) on_log_(chunk);
  }
  ::CloseHandle(read_end);
}

void ChildProcess::WatchExit(HANDLE process) {
  if (process == nullptr) return;
  ::WaitForSingleObject(process, INFINITE);
  DWORD code = 0;
  ::GetExitCodeProcess(process, &code);
  ::CloseHandle(process);
  if (stopping_) return;  // штатная остановка — не краш
  if (on_crash_) on_crash_(CrashReason(code));
}

// Просит процесс завершиться самому.
//
// Единственный способ послать консольному процессу без окна сигнал завершения
// на Windows: подцепиться к ЕГО консоли (при CREATE_NO_WINDOW она есть, нет
// только окна) и разослать по ней Ctrl+Break. Go, на котором написаны sing-box
// и xray, доставляет это в программу как os.Interrupt, и sing-box успевает
// закрыть wintun-адаптер — ради чего всё и делается.
bool ChildProcess::StopGracefully(DWORD timeout_ms) {
  if (process_ == nullptr || pid_ == 0) return false;

  // Своя консоль, если была, мешает: AttachConsole работает только когда
  // процесс ни к какой консоли не привязан.
  ::FreeConsole();
  if (!::AttachConsole(pid_)) return false;

  // Событие рассылается всем на этой консоли, включая нас, а по умолчанию оно
  // означает «завершить процесс». Без своего обработчика служба убивала бы себя
  // при каждой остановке туннеля.
  if (!::SetConsoleCtrlHandler(IgnoreConsoleCtrl, TRUE)) {
    ::FreeConsole();
    return false;
  }
  BOOL sent = ::GenerateConsoleCtrlEvent(CTRL_BREAK_EVENT, 0);
  bool exited =
      sent && ::WaitForSingleObject(process_, timeout_ms) == WAIT_OBJECT_0;
  ::FreeConsole();
  ::SetConsoleCtrlHandler(IgnoreConsoleCtrl, FALSE);
  return exited;
}

void ChildProcess::Stop() {
  stopping_ = true;
  if (process_ != nullptr) {
    // Восемь секунд: в логах освобождение tun-интерфейса занимает секунды, и
    // обрывать его на полпути — значит вернуться к тому же конфликту адаптера.
    if (!graceful_ || !StopGracefully(8000)) {
      ::TerminateProcess(process_, 0);
      ::WaitForSingleObject(process_, 3000);
    }
  }
  if (log_thread_.joinable()) log_thread_.join();
  if (watch_thread_.joinable()) watch_thread_.detach();
  if (process_ != nullptr) {
    ::CloseHandle(process_);
    process_ = nullptr;
    pid_ = 0;
  }
  if (job_ != nullptr) {
    ::CloseHandle(job_);
    job_ = nullptr;
  }
}

void ChildProcess::AppendTail(const std::string& chunk) {
  std::lock_guard<std::mutex> lock(tail_mutex_);
  size_t start = 0;
  while (start <= chunk.size()) {
    size_t nl = chunk.find('\n', start);
    std::string line = chunk.substr(
        start, nl == std::string::npos ? std::string::npos : nl - start);
    if (!Trim(line).empty()) {
      tail_.push_back(line);
      if (tail_.size() > kTailLimit) tail_.pop_front();
    }
    if (nl == std::string::npos) break;
    start = nl + 1;
  }
}

std::string ChildProcess::CrashReason(DWORD exit_code) {
  std::lock_guard<std::mutex> lock(tail_mutex_);
  for (auto it = tail_.rbegin(); it != tail_.rend(); ++it) {
    if (ContainsNoCase(*it, "FATAL") || ContainsNoCase(*it, "ERROR")) {
      return Trim(StripAnsi(*it));
    }
  }
  return "процесс завершился (код " + std::to_string(exit_code) + ")";
}
