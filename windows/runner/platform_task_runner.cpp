#include "platform_task_runner.h"

#include <windows.h>

#include <deque>
#include <mutex>

namespace {

constexpr wchar_t kClassName[] = L"VergePlatformTaskRunner";
constexpr UINT kRunTasks = WM_APP + 1;

HWND g_window = nullptr;
std::mutex g_mutex;
std::deque<std::function<void()>> g_tasks;

// Задача выполняется вне блокировки: она может звать Post повторно (например,
// краш-обработчик, который шлёт и лог, и статус), а рекурсивный захват мьютекса
// здесь означал бы взаимоблокировку.
void Drain() {
  for (;;) {
    std::function<void()> task;
    {
      std::lock_guard<std::mutex> lock(g_mutex);
      if (g_tasks.empty()) return;
      task = std::move(g_tasks.front());
      g_tasks.pop_front();
    }
    task();
  }
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wparam,
                         LPARAM lparam) {
  if (message == kRunTasks) {
    Drain();
    return 0;
  }
  return ::DefWindowProcW(hwnd, message, wparam, lparam);
}

}  // namespace

void PlatformTaskRunner::Init() {
  if (g_window != nullptr) return;
  WNDCLASSW wc{};
  wc.lpfnWndProc = WndProc;
  wc.hInstance = ::GetModuleHandleW(nullptr);
  wc.lpszClassName = kClassName;
  ::RegisterClassW(&wc);
  // HWND_MESSAGE — окно только для сообщений: не рисуется и не попадает в
  // перечисление окон, но получает PostMessage.
  g_window = ::CreateWindowExW(0, kClassName, L"", 0, 0, 0, 0, 0, HWND_MESSAGE,
                               nullptr, wc.hInstance, nullptr);
}

void PlatformTaskRunner::Post(std::function<void()> task) {
  {
    std::lock_guard<std::mutex> lock(g_mutex);
    g_tasks.push_back(std::move(task));
  }
  // До Init задачи копятся в очереди: разберёт их первый же Post после него.
  if (g_window != nullptr) ::PostMessageW(g_window, kRunTasks, 0, 0);
}
