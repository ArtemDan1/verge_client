#ifndef VERGE_PIPE_PROTOCOL_H_
#define VERGE_PIPE_PROTOCOL_H_

#include <windows.h>

#include <cstdint>
#include <string>

// Протокол общения приложения со службой VergeTunnel — аналог XPC-контракта
// HelperProtocol.swift на macOS.
//
// Кадр: [4 байта длины payload, little-endian][1 байт тега][payload].
// Длина не включает сам себя и тег. JSON здесь намеренно не используется:
// служба работает под LocalSystem и принимает данные от любого пользователя,
// а собственный разбор JSON — это лишняя поверхность атаки. Конфиг проходит
// насквозь строкой, разбирать его службе не нужно.

namespace verge {

constexpr wchar_t kPipeName[] = L"\\\\.\\pipe\\verge-tunnel";

// Полный доступ системе и администраторам, чтение-запись обычным пользователям:
// приложение работает без прав администратора и обязано достучаться.
constexpr wchar_t kPipeSddl[] = L"D:(A;;GA;;;SY)(A;;GA;;;BA)(A;;GRGW;;;BU)";

// Больше конфига sing-box не бывает; всё, что больше, — мусор или атака.
constexpr uint32_t kMaxPayload = 8 * 1024 * 1024;

enum class Cmd : uint8_t {
  kVersion = 1,  // payload пуст → Rep::kOk с версией службы
  kStart = 2,    // payload — конфиг sing-box → kOk или kError с текстом
  kStop = 3,     // payload пуст → kOk
  kStatus = 4,   // payload пуст → kOk с "running" либо "stopped:<текст>"
  kLogs = 5,     // payload пуст → kOk со строками лога через '\n', буфер чистится
};

enum class Rep : uint8_t {
  kOk = 1,
  kError = 2,
};

// Обе функции блокирующие и возвращают false на любой ошибке ввода-вывода,
// включая обрыв канала. Частично прочитанный кадр — это ошибка: докачивать
// нечего, соединение всё равно рвётся.
inline bool WriteFrame(HANDLE pipe, uint8_t tag, const std::string& payload) {
  if (payload.size() > kMaxPayload) return false;
  uint32_t len = static_cast<uint32_t>(payload.size());
  DWORD written = 0;
  if (!::WriteFile(pipe, &len, sizeof(len), &written, nullptr) ||
      written != sizeof(len)) {
    return false;
  }
  if (!::WriteFile(pipe, &tag, 1, &written, nullptr) || written != 1) {
    return false;
  }
  if (payload.empty()) return true;
  if (!::WriteFile(pipe, payload.data(), len, &written, nullptr) ||
      written != len) {
    return false;
  }
  return true;
}

inline bool ReadExactly(HANDLE pipe, void* buf, DWORD size) {
  DWORD total = 0;
  while (total < size) {
    DWORD got = 0;
    if (!::ReadFile(pipe, static_cast<char*>(buf) + total, size - total, &got,
                    nullptr) ||
        got == 0) {
      return false;
    }
    total += got;
  }
  return true;
}

inline bool ReadFrame(HANDLE pipe, uint8_t* tag, std::string* payload) {
  uint32_t len = 0;
  if (!ReadExactly(pipe, &len, sizeof(len))) return false;
  if (len > kMaxPayload) return false;
  if (!ReadExactly(pipe, tag, 1)) return false;
  payload->assign(len, '\0');
  if (len == 0) return true;
  return ReadExactly(pipe, payload->data(), len);
}

}  // namespace verge

#endif  // VERGE_PIPE_PROTOCOL_H_
