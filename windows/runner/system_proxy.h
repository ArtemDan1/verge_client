#ifndef RUNNER_SYSTEM_PROXY_H_
#define RUNNER_SYSTEM_PROXY_H_

// Системный HTTP/HTTPS прокси Windows: ключи HKCU Internet Settings плюс
// уведомление WinINET. Прокси общесистемный (на пользователя), привязки к
// сетевому адаптеру нет — в отличие от macOS, где он ставится на сервис.
namespace SystemProxy {

// Включает прокси на 127.0.0.1:port. false — не удалось записать реестр.
bool Enable(int port);

// Снимает прокси. Идемпотентно: повторный вызов ничего не делает.
void DisableAll();

// Сбрасывает прокси, оставшийся от прошлого запуска.
//
// Главный риск Windows: если приложение убили (Task Manager, синий экран),
// ProxyEnable=1 остаётся и весь HTTP-трафик пользователя идёт в мёртвый
// loopback-порт. Вызывается один раз на старте: если ProxyServer указывает на
// 127.0.0.1, значит его поставили мы — снимаем.
void ClearIfOrphaned();

}  // namespace SystemProxy

#endif  // RUNNER_SYSTEM_PROXY_H_
