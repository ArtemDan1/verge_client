# Verge — sing-box клиент для macOS

Десктопный VPN-клиент на Flutter поверх [sing-box](https://github.com/SagerNet/sing-box).
Подхватывает подписки, строит конфиг sing-box, поднимает туннель и управляет
системным прокси / TUN-интерфейсом.

Платформа: **macOS** (Apple Silicon и Intel). Каталоги `ios/` и `windows/`
остались от шаблона Flutter и не поддерживаются.

## Возможности

- **Подписки** — импорт по ссылке, автообновление, счётчики трафика и срока из
  заголовка `subscription-userinfo`. Поддерживаются форматы: конфиг sing-box,
  конфиг Xray/V2Ray, base64-список share-ссылок (`vless://`, `vmess://`,
  `trojan://`, `ss://`).
- **Два режима туннеля**:
  - *System proxy* — sing-box запускается как обычный процесс, приложение
    прописывает системный прокси и DNS;
  - *TUN* — трафик всей системы через утилиту-хелпер с root-привилегиями
    (устанавливается .pkg-инсталлятором как LaunchDaemon).
- **Роутинг** — профили правил direct / proxy / block на базе geosite/geoip
  rule-set'ов (встроены в `assets/rule-sets/`, обновляются онлайн). Готовые
  пресеты: всё через прокси, обход РФ, блокировка рекламы и др.
- **Ноды** — выбор сервера, пинг, автоподбор.
- **Мониторинг** — живой трафик и список соединений через локальный Clash API
  sing-box (порт и секрет генерируются на каждый запуск, слушает только
  loopback), экран логов.
- **Deep links** — `verge://import/<url-encoded-url>?name=<name>` для импорта
  подписки одним кликом.
- **Автообновление** — проверка GitHub Releases и загрузка .pkg.

## Структура

```
lib/
  app/          AppController — состояние приложения
  models/       модели (профили, ноды, правила, настройки)
  services/     подписки, парсеры конфигов, сборка sing-box-конфига,
                роутинг, geo-ассеты, пинг, Clash API, обновления
  platform/     мосты к нативу (helper, инфо о платформе)
  tunnel/       реализации туннеля: process (proxy) и helper (TUN)
  storage/      персист состояния в JSON
  ui/           экраны и виджеты (shadcn_ui)
macos/
  Runner/       Swift-часть: запуск sing-box, системный прокси/DNS,
                каналы TUN/helper/deep-link
  Helper/       привилегированный helper-демон (XPC)
  Runner/Resources/sing-box   вендоренный бинарь sing-box
packaging/      plist LaunchDaemon и postinstall для .pkg
scripts/        сборка, упаковка, установка, удаление
assets/         rule-set'ы и брендинг
docs/           дизайн-документы, планы, инструкция по установке
```

## Разработка

```bash
flutter pub get
flutter run -d macos
flutter test            # весь пакет покрыт unit/widget-тестами
flutter analyze
```

Иконки после смены исходного PNG: `dart run flutter_launcher_icons`.

## Сборка релиза и .pkg

```bash
scripts/build_release.sh   # flutter build macos --release + ad-hoc подпись
scripts/make_pkg.sh        # dist/Verge-<версия>.pkg (app + helper-демон)
scripts/install_and_verify.sh
scripts/uninstall.sh
```

Сборка не нотаризована (ad-hoc подпись), поэтому при первом запуске нужен
«правый клик → Открыть». Подробности для пользователей — в
[docs/INSTALL.md](docs/INSTALL.md).

### Известные особенности

- Release-сборка после изменений в Swift-части: сначала `flutter clean`, иначе
  подхватывается старый бандл.
- TUN-режим держит собственный кеш `cache-tun.db`; он в `.gitignore`.
- Владелец репозитория для автообновления захардкожен в
  `lib/services/update_service.dart` (`owner` / `repo`) — поправьте при переносе.
