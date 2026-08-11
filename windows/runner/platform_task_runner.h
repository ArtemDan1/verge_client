#ifndef RUNNER_PLATFORM_TASK_RUNNER_H_
#define RUNNER_PLATFORM_TASK_RUNNER_H_

#include <functional>

// Перенос работы на platform thread.
//
// EventSink и MethodResult движка Flutter не потокобезопасны: вызывать их можно
// только с того потока, на котором создан движок. Логи sing-box/xray приходят
// из потока чтения пайпа, замер пинга — из своего потока, и без маршалинга оба
// пути дёргали бы движок откуда попало. На macOS ту же роль играл
// DispatchQueue.main.async.
//
// Реализовано message-only окном: Post кладёт задачу в очередь и будит цикл
// сообщений, обработчик разбирает очередь уже на platform thread.
namespace PlatformTaskRunner {

// Вызывать один раз с platform thread до регистрации каналов.
void Init();

// Потокобезопасно. Задача выполнится на platform thread.
void Post(std::function<void()> task);

}  // namespace PlatformTaskRunner

#endif  // RUNNER_PLATFORM_TASK_RUNNER_H_
