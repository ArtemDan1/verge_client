// Служба VergeTunnel — привилегированная часть TUN-режима.
//
// Аналог LaunchDaemon на macOS: ставится инсталлятором, работает под
// LocalSystem, приложение только шлёт ей команды. Само приложение прав
// администратора не требует и не получает.

#include <windows.h>

#include <sddl.h>

#include <string>

#include "pipe_protocol.h"
#include "tunnel_worker.h"

namespace {

constexpr wchar_t kServiceName[] = L"VergeTunnel";
constexpr char kServiceVersion[] = "1";

SERVICE_STATUS_HANDLE g_status_handle = nullptr;
SERVICE_STATUS g_status{};
HANDLE g_stop_event = nullptr;

void WakeAcceptLoop();

void SetState(DWORD state, DWORD exit_code = NO_ERROR) {
  g_status.dwServiceType = SERVICE_WIN32_OWN_PROCESS;
  g_status.dwCurrentState = state;
  g_status.dwControlsAccepted =
      state == SERVICE_RUNNING ? SERVICE_ACCEPT_STOP | SERVICE_ACCEPT_SHUTDOWN
                               : 0;
  g_status.dwWin32ExitCode = exit_code;
  g_status.dwWaitHint = 3000;
  ::SetServiceStatus(g_status_handle, &g_status);
}

void WINAPI HandlerEx(DWORD control, DWORD, LPVOID, LPVOID) {
  if (control == SERVICE_CONTROL_STOP || control == SERVICE_CONTROL_SHUTDOWN) {
    SetState(SERVICE_STOP_PENDING);
    // Туннель гасим сами: осиротевший sing-box под LocalSystem продолжил бы
    // держать wintun-адаптер и весь трафик системы после остановки службы.
    TunnelWorker::Instance().Stop();
    ::SetEvent(g_stop_event);
    // Событие само по себе цикл приёма не разбудит: он стоит в блокирующем
    // ConnectNamedPipe. Подключаемся к себе, чтобы вызов вернулся.
    WakeAcceptLoop();
  }
}

// Обслуживает одно подключение до обрыва: клиент может слать несколько команд
// подряд (опрос статуса и логов раз в две секунды).
void ServeClient(HANDLE pipe) {
  for (;;) {
    uint8_t tag = 0;
    std::string payload;
    if (!verge::ReadFrame(pipe, &tag, &payload)) return;

    auto& worker = TunnelWorker::Instance();
    switch (static_cast<verge::Cmd>(tag)) {
      case verge::Cmd::kVersion:
        verge::WriteFrame(pipe, static_cast<uint8_t>(verge::Rep::kOk),
                          kServiceVersion);
        break;
      case verge::Cmd::kStart: {
        std::string err = worker.Start(payload);
        if (err.empty()) {
          verge::WriteFrame(pipe, static_cast<uint8_t>(verge::Rep::kOk), "");
        } else {
          verge::WriteFrame(pipe, static_cast<uint8_t>(verge::Rep::kError), err);
        }
        break;
      }
      case verge::Cmd::kStop:
        worker.Stop();
        verge::WriteFrame(pipe, static_cast<uint8_t>(verge::Rep::kOk), "");
        break;
      case verge::Cmd::kStatus:
        verge::WriteFrame(pipe, static_cast<uint8_t>(verge::Rep::kOk),
                          worker.Status());
        break;
      case verge::Cmd::kLogs:
        verge::WriteFrame(pipe, static_cast<uint8_t>(verge::Rep::kOk),
                          worker.TakeLogs());
        break;
      default:
        verge::WriteFrame(pipe, static_cast<uint8_t>(verge::Rep::kError),
                          "неизвестная команда");
        return;
    }
  }
}

HANDLE CreateInstance(SECURITY_ATTRIBUTES* sa) {
  // Пайп синхронный: чтение и запись кадров в pipe_protocol.h блокирующие, а
  // с FILE_FLAG_OVERLAPPED вызов ReadFile без OVERLAPPED сразу вернул бы
  // ERROR_INVALID_PARAMETER.
  return ::CreateNamedPipeW(verge::kPipeName, PIPE_ACCESS_DUPLEX,
                            PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT,
                            PIPE_UNLIMITED_INSTANCES, 64 * 1024, 64 * 1024, 0,
                            sa);
}

// Приём подключений.
//
// Экземпляр пайпа обязан существовать непрерывно: закрой текущий до создания
// следующего — и в зазор попадёт клиентский CreateFileW, получив
// ERROR_FILE_NOT_FOUND. Приложение считает такую ошибку недоступностью службы
// и роняет живой туннель в состояние ошибки. Поэтому следующий экземпляр
// создаётся до закрытия текущего.
//
// ConnectNamedPipe здесь блокирующий и события остановки сам не видит.
// Будит его WakeAcceptLoop: подключается к собственному пайпу как клиент и
// сразу отключается. Без этого `sc stop` на простаивающей службе висел бы до
// таймаута SCM, а инсталлятор не смог бы заменить файлы при обновлении.
void AcceptLoop(SECURITY_ATTRIBUTES* sa) {
  HANDLE pipe = CreateInstance(sa);
  if (pipe == INVALID_HANDLE_VALUE) return;

  for (;;) {
    // ERROR_PIPE_CONNECTED — клиент успел подключиться между созданием
    // экземпляра и этим вызовом; это успех, а не ошибка.
    BOOL connected = ::ConnectNamedPipe(pipe, nullptr) ||
                     ::GetLastError() == ERROR_PIPE_CONNECTED;

    if (::WaitForSingleObject(g_stop_event, 0) == WAIT_OBJECT_0) {
      ::DisconnectNamedPipe(pipe);
      break;
    }

    if (connected) ServeClient(pipe);

    // Повторная проверка обязательна: остановка могла прийти, пока мы были
    // внутри ServeClient. Будильник в этот момент упёрся бы в ERROR_PIPE_BUSY
    // и ничего не разбудил, а следующий ConnectNamedPipe заблокировался бы
    // навсегда.
    if (::WaitForSingleObject(g_stop_event, 0) == WAIT_OBJECT_0) {
      ::DisconnectNamedPipe(pipe);
      break;
    }

    HANDLE next = CreateInstance(sa);
    ::FlushFileBuffers(pipe);
    ::DisconnectNamedPipe(pipe);
    ::CloseHandle(pipe);
    if (next == INVALID_HANDLE_VALUE) return;
    pipe = next;
  }

  ::CloseHandle(pipe);
}

// Разблокирует ConnectNamedPipe в AcceptLoop. Вызывается из обработчика
// остановки, уже после того как выставлен g_stop_event.
void WakeAcceptLoop() {
  HANDLE client = ::CreateFileW(verge::kPipeName, GENERIC_READ | GENERIC_WRITE,
                                0, nullptr, OPEN_EXISTING, 0, nullptr);
  if (client != INVALID_HANDLE_VALUE) ::CloseHandle(client);
}

void WINAPI ServiceMain(DWORD, LPWSTR*) {
  g_status_handle = ::RegisterServiceCtrlHandlerExW(kServiceName, HandlerEx,
                                                    nullptr);
  if (g_status_handle == nullptr) return;
  g_stop_event = ::CreateEventW(nullptr, TRUE, FALSE, nullptr);
  SetState(SERVICE_RUNNING);

  SECURITY_ATTRIBUTES sa{};
  sa.nLength = sizeof(sa);
  sa.bInheritHandle = FALSE;
  if (!::ConvertStringSecurityDescriptorToSecurityDescriptorW(
          verge::kPipeSddl, SDDL_REVISION_1, &sa.lpSecurityDescriptor,
          nullptr)) {
    SetState(SERVICE_STOPPED, ERROR_ACCESS_DENIED);
    return;
  }

  AcceptLoop(&sa);

  ::LocalFree(sa.lpSecurityDescriptor);
  TunnelWorker::Instance().Stop();
  SetState(SERVICE_STOPPED);
}

}  // namespace

int wmain() {
  SERVICE_TABLE_ENTRYW table[] = {
      {const_cast<wchar_t*>(kServiceName), ServiceMain},
      {nullptr, nullptr},
  };
  if (!::StartServiceCtrlDispatcherW(table)) return 1;
  return 0;
}
