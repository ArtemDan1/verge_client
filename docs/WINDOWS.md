# Windows-клиент Verge

## Требования

- Windows 10 версии 1809 (build 17763) или новее, x64. Windows on ARM не
  поддерживается.
- Для сборки из исходников: Flutter 3.x с включённой поддержкой Windows
  desktop (`flutter config --enable-windows-desktop`), Visual Studio 2022 с
  workload «Desktop development with C++».

## Сборка из исходников

```powershell
flutter pub get
flutter build windows --release
```

Собранное приложение и все вендоренные бинарники окажутся рядом в
`build\windows\x64\runner\Release\`.

## Вендоренные бинарники

`windows/runner/resources/` должен содержать перед сборкой:

| Файл | Источник |
|---|---|
| `sing-box.exe` | [SagerNet/sing-box](https://github.com/SagerNet/sing-box) releases, `sing-box-<ver>-windows-amd64.zip` |
| `sing-box-test.exe` | побайтовая копия `sing-box.exe` под другим именем |
| `xray.exe` | [XTLS/Xray-core](https://github.com/XTLS/Xray-core) releases, `Xray-windows-64.zip` |
| `wintun.dll` | [wintun.net](https://www.wintun.net/), `bin/amd64/wintun.dll` |

Версии sing-box и xray должны совпадать с теми, что используются в
macOS-сборке (см. `macos/Runner/Resources`). Подробности и текущие версии —
в `windows/runner/resources/README.md`.

`sing-box-test.exe` обязан быть отдельным файлом, а не симлинком: правило
`find_process` в конфиге различает боевой и тестовый процесс только по имени
исполняемого файла, а симлинки на Windows требуют прав администратора.

## Ручной чек-лист перед релизом

1. Импорт подписки по ссылке; счётчики трафика и срока отображаются.
2. Подключение в proxy-режиме; браузер ходит через прокси.
3. Отключение снимает прокси — проверить «Параметры → Сеть и Интернет → Прокси».
4. Убить `verge_client.exe` через Task Manager при активном подключении →
   `sing-box.exe` тоже исчезает (Job Object), интернет остаётся рабочим после
   перезапуска приложения (сброс осиротевшего прокси).
5. Битый конфиг (испортить ноду вручную) → внятная ошибка со строкой FATAL,
   прокси не включается.
6. Замер пинга нод, автоподбор ноды.
7. Мониторинг трафика и соединений (Clash API), экран логов.
8. Deep link при закрытом и запущенном приложении.
9. Трей: скрытие, «Открыть», «Выход».
10. Проверка обновлений (без установки — только что баннер появляется и ассет
    находится).

## Известные ограничения

- **TUN-режим не реализован.** Канал `singbox/helper` — заглушка, всегда
  отвечает `notRegistered`, UI показывает TUN недоступным. Требует отдельного
  плана: служба `VergeTunnel`, named pipe, канал `singbox/tun` + `/events`.
- **Нет инсталлятора.** Приложение запускается из собранной папки; схема
  `verge://` регистрируется вручную через `reg add` (см. план разработки).
  Поставка через Inno Setup и автообновление `-setup.exe` — отдельный план.
- Сборка не подписана.
