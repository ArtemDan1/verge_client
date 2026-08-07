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
  BOOL ok = ::CreateProcessW(exe.c_str(), mutable_cmd.data(), nullptr, nullptr,
                             TRUE, CREATE_NO_WINDOW | CREATE_SUSPENDED, nullptr,
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

void ChildProcess::Stop() {
  stopping_ = true;
  if (process_ != nullptr) {
    ::TerminateProcess(process_, 0);
    ::WaitForSingleObject(process_, 3000);
  }
  if (log_thread_.joinable()) log_thread_.join();
  if (watch_thread_.joinable()) watch_thread_.detach();
  if (process_ != nullptr) {
    ::CloseHandle(process_);
    process_ = nullptr;
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
