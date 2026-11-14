// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get renameProfile => 'Переименовать профиль';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get subscriptionsUpdated => 'Подписки обновлены';

  @override
  String get unitB => 'Б';

  @override
  String get unitKB => 'КБ';

  @override
  String get unitMB => 'МБ';

  @override
  String get unitGB => 'ГБ';

  @override
  String get unitTB => 'ТБ';

  @override
  String usedNoLimit(Object used) {
    return 'использовано $used · без лимита';
  }

  @override
  String validUntil(Object date) {
    return 'до $date';
  }

  @override
  String get timeout => 'таймаут';

  @override
  String get error => 'ошибка';

  @override
  String get pingAll => 'Пинг всех';

  @override
  String get refreshSubscriptions => 'Обновить подписки';

  @override
  String get addSubscription => 'Добавить подписку';

  @override
  String get servers => 'Серверы';

  @override
  String get pickingNode => 'Подбираем ноду…';

  @override
  String get noSubscriptions => 'Нет подписок. Добавьте первую.';

  @override
  String get subscriptionHasNoServers => 'В подписке нет серверов';

  @override
  String get active => 'активен';

  @override
  String get columnServer => 'Сервер';

  @override
  String get columnProtocol => 'Протокол';

  @override
  String get columnEngine => 'Движок';

  @override
  String get columnLatency => 'Задержка';

  @override
  String ms(Object ms) {
    return '$ms мс';
  }

  @override
  String engineAuto(Object engine) {
    return 'Авто ($engine)';
  }

  @override
  String get edit => 'Редактировать';

  @override
  String get ping => 'Пинг';

  @override
  String get refresh => 'Обновить';

  @override
  String get subscriptionLinkCopied => 'Ссылка на подписку скопирована';

  @override
  String get subscription => 'Подписка';

  @override
  String get accountPage => 'Личный кабинет';

  @override
  String get support => 'Поддержка';

  @override
  String get autoRefresh => 'Автообновление';

  @override
  String get rename => 'Переименовать';

  @override
  String get delete => 'Удалить';

  @override
  String get autoSelectOn => 'Автовыбор: вкл';

  @override
  String get autoSelect => 'Автовыбор';

  @override
  String refreshOwn(Object hours) {
    return 'Своё: $hours ч';
  }

  @override
  String refreshBySubscription(Object hours) {
    return 'По подписке: $hours ч';
  }

  @override
  String get off => 'Выключено';

  @override
  String get autoRefreshInterval => 'Интервал автообновления';

  @override
  String get hours => 'Часы';

  @override
  String emptyUseSubscriptionInterval(Object hours) {
    return 'Пусто — использовать интервал из подписки ($hours ч)';
  }

  @override
  String get emptyNoAutoRefresh => 'Пусто — не обновлять автоматически';

  @override
  String serverCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сервера',
      many: '$count серверов',
      few: '$count сервера',
      one: '$count сервер',
    );
    return '$_temp0';
  }

  @override
  String usedOfTotal(Object used, Object total) {
    return '$used из $total';
  }

  @override
  String remaining(Object amount) {
    return 'осталось $amount';
  }

  @override
  String get limitExhausted => 'лимит исчерпан';

  @override
  String get newProfile => 'Новый профиль';

  @override
  String get routing => 'Роутинг';

  @override
  String get updateGeo => 'Обновить гео';

  @override
  String get profile => 'Профиль';

  @override
  String get routingSubtitle =>
      'Что идёт через VPN, что напрямую, а что блокируется';

  @override
  String get geoNeverUpdated => 'ещё не обновлялись — вшитые версии';

  @override
  String geoUpdated(Object ago) {
    return 'обновлены $ago';
  }

  @override
  String geoSets(Object status) {
    return 'Гео-наборы (.srs): $status';
  }

  @override
  String get justNow => 'только что';

  @override
  String minutesAgo(Object n) {
    return '$n мин назад';
  }

  @override
  String hoursAgo(Object n) {
    return '$n ч назад';
  }

  @override
  String daysAgo(Object n) {
    return '$n дн назад';
  }

  @override
  String get restDirect => 'остальное напрямую';

  @override
  String get restViaVpn => 'остальное через VPN';

  @override
  String get builtIn => 'Встроенный';

  @override
  String get custom => 'Свой';

  @override
  String get allDirect => 'всё через прямое соединение';

  @override
  String get allViaVpn => 'всё через VPN';

  @override
  String ruleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count правила',
      many: '$count правил',
      few: '$count правила',
      one: '$count правило',
    );
    return '$_temp0';
  }

  @override
  String get groupViaVpn => 'Через VPN';

  @override
  String get groupDirect => 'Напрямую';

  @override
  String get groupBlock => 'Блокировать';

  @override
  String get groupExceptions => 'Исключения (важнее блока)';

  @override
  String get exceptionsGo => 'Исключения идут';

  @override
  String get viaVpn => 'через VPN';

  @override
  String get direct => 'напрямую';

  @override
  String get duplicate => 'Дублировать';

  @override
  String get use => 'Использовать';

  @override
  String get builtInProfileReadOnly =>
      'Встроенный профиль не меняется — дублируйте его, чтобы настроить правила под себя.';

  @override
  String get everythingElse => 'Всё, что не попало в правила';

  @override
  String get empty => 'Пусто';

  @override
  String get chooseCategory => 'Выбрать категорию';

  @override
  String get domainOrCidr => 'Домен или IP/CIDR';

  @override
  String get add => 'Добавить';

  @override
  String get domainOrCidrHint => 'example.com или 1.2.3.0/24';

  @override
  String get geoCategory => 'Гео-категория';

  @override
  String get domainOrIp => 'Домен или IP';

  @override
  String get addRule => 'Добавить правило';

  @override
  String get kindProxy => 'Прокси';

  @override
  String get kindBlock => 'Блок';

  @override
  String get otherApps => 'Другие';

  @override
  String get noActiveConnections => 'Нет активных соединений';

  @override
  String get vpnDisconnected => 'VPN отключён';

  @override
  String get nothingFound => 'Ничего не найдено';

  @override
  String get connections => 'Соединения';

  @override
  String get byApp => 'По приложениям';

  @override
  String get asList => 'Списком';

  @override
  String get connectionsSearchHint => 'Домен, IP или приложение';

  @override
  String get all => 'Все';

  @override
  String get close => 'Закрыть';

  @override
  String get kindProxyShort => 'прокси';

  @override
  String get kindBlockShort => 'блок';

  @override
  String connectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count соединения',
      many: '$count соединений',
      few: '$count соединения',
      one: '$count соединение',
    );
    return '$_temp0';
  }

  @override
  String get fieldApp => 'Приложение';

  @override
  String get fieldProcessPath => 'Путь процесса';

  @override
  String get fieldNetwork => 'Сеть';

  @override
  String get fieldSource => 'Источник';

  @override
  String get fieldDestination => 'Назначение';

  @override
  String get fieldDomain => 'Домен';

  @override
  String get fieldChain => 'Цепочка';

  @override
  String get fieldRule => 'Правило';

  @override
  String get fieldDuration => 'Длительность';

  @override
  String get fieldStart => 'Начало';

  @override
  String get connectionClosed => 'соединение закрыто';

  @override
  String get sent => 'Отправлено';

  @override
  String get received => 'Получено';

  @override
  String get advanced => 'Расширенные';

  @override
  String get tunAdvancedDescription =>
      'Адрес интерфейса, MTU, сетевой стек и маршруты. Подобраны под большинство сетей — трогать, только если TUN работает с проблемами';

  @override
  String get reset => 'Сбросить';

  @override
  String get tunAdvancedWarning =>
      'Менять эти значения стоит, только если понимаете последствия. MTU 9000 обрывает SSH и MySQL, адрес из 172.16.0.0/12 ломает docker-сети, строгий маршрут перехватывает трафик локальной сети.';

  @override
  String get interfaceAddress => 'Адрес интерфейса';

  @override
  String rangeFromTo(Object min, Object max) {
    return 'От $min до $max';
  }

  @override
  String get networkStack => 'Сетевой стек';

  @override
  String get networkStackDescription =>
      'gvisor — совместимость, system — скорость, mixed — баланс';

  @override
  String get strictRoute => 'Строгий маршрут';

  @override
  String get strictRouteDescription => 'Не даёт трафику уйти мимо туннеля';

  @override
  String get autoRoute => 'Маршрут по умолчанию';

  @override
  String get autoRouteDescription => 'Весь трафик системы идёт в туннель';

  @override
  String daysShort(Object n) {
    return '$nд';
  }

  @override
  String get connected => 'Подключено';

  @override
  String get connecting => 'Подключаемся…';

  @override
  String get notConnected => 'Не подключено';

  @override
  String get chooseServerBelow => 'Выберите сервер ниже';

  @override
  String get time => 'Время';

  @override
  String get noInternet => 'нет интернета';

  @override
  String get routingRules => 'Правила роутинга';

  @override
  String get disconnect => 'Отключиться';

  @override
  String get connect => 'Подключиться';

  @override
  String get checkingServer => 'Проверяем сервер';

  @override
  String get clickToConnect => 'Нажмите, чтобы подключиться';

  @override
  String get quitVerge => 'Выйти из Verge';

  @override
  String get noSubscriptionsTray => 'Нет подписок — добавьте их в главном окне';

  @override
  String get openVerge => 'Открыть Verge';

  @override
  String get noResponse => 'нет ответа';

  @override
  String get skipCertVerify => 'Пропустить проверку сертификата';

  @override
  String get skipCertVerifyDescription =>
      'Понижает безопасность: соединение перестаёт защищать от подмены сервера. Включать только для отладки';

  @override
  String get tlsFragment => 'Фрагментация TLS';

  @override
  String get tlsFragmentDescription =>
      'Режет TLS-хендшейк на части, чтобы обойти файрволы с плоским matching по ClientHello. Работает только под sing-box';

  @override
  String get tlsFragmentUnsupported =>
      'Текущий движок фрагментацию не поддерживает';

  @override
  String get tlsRecordFragment => 'Фрагментация по TLS-записям';

  @override
  String get tlsRecordFragmentDescription =>
      'Дешевле по производительности — стоит пробовать первым';

  @override
  String get fallbackDelay => 'Задержка резервного варианта';

  @override
  String get fallbackDelayDescription =>
      'Сколько ждать ответа, прежде чем пробовать без фрагментации';

  @override
  String versionAvailable(Object version) {
    return 'Доступна версия $version';
  }

  @override
  String get launchingInstaller =>
      'Запускаем установщик — Verge закроется и обновится';

  @override
  String get downloadingUpdate => 'Загружаем обновление…';

  @override
  String get updateReady => 'Новая версия Verge готова к установке';

  @override
  String downloadFailed(Object error) {
    return 'Не удалось скачать: $error';
  }

  @override
  String get retry => 'Повторить';

  @override
  String get update => 'Обновить';

  @override
  String get later => 'Позже';

  @override
  String get whatsNew => 'Что нового';

  @override
  String get skipVersion => 'Пропустить версию';

  @override
  String get installing => 'Устанавливаем…';

  @override
  String get downloading => 'Скачиваем';

  @override
  String get activeConnectionPing => 'Пинг активного соединения';

  @override
  String get showPing => 'Показывать пинг';

  @override
  String get showPingDescription =>
      'Задержка до сервера на главной, рядом с таймером подключения';

  @override
  String get pingIntervalSeconds => 'Интервал обновления, с';

  @override
  String pingIntervalDescription(Object min, Object max, Object def) {
    return 'От $min до $max с, по умолчанию $def';
  }

  @override
  String get probeUrl => 'Адрес проверки';

  @override
  String get probeUrlDescription =>
      'В TUN-режиме до этого адреса проверяется наличие интернета мимо туннеля; в Proxy — задержка через локальный прокси';

  @override
  String get autoSelectNode => 'Автовыбор ноды';

  @override
  String get pickBestNode => 'Подбирать лучшую ноду';

  @override
  String healthCheckInterval(Object min, Object max) {
    return 'Интервал фоновой проверки, секунды ($min…$max)';
  }

  @override
  String get profiles => 'Профили';

  @override
  String get checkNow => 'Проверить сейчас';

  @override
  String lastCheck(Object time, Object result) {
    return 'Последняя проверка: $time — $result';
  }

  @override
  String get nodeResponds => 'нода отвечает';

  @override
  String lastPick(Object result) {
    return 'Последний подбор: $result';
  }

  @override
  String get emptyLink => 'Пустая ссылка';

  @override
  String get clipboardEmpty => 'Буфер обмена пуст';

  @override
  String get addSubscriptionDescription =>
      'URL подписки, share-ссылка (vless://, ss://…) или JSON-конфиг';

  @override
  String get pasteFromClipboardHint =>
      'Скопировали ссылку? Добавим прямо из буфера обмена';

  @override
  String get paste => 'Вставить';

  @override
  String get or => 'или';

  @override
  String get subscriptionUrlHint => 'https://… или vless://…';

  @override
  String get themeSystem => 'Как в системе';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get theme => 'Тема';

  @override
  String get startup => 'Запуск';

  @override
  String get autostart => 'Автозапуск';

  @override
  String get autostartDescription => 'Подключать последнюю ноду при старте';

  @override
  String get localProxyPort => 'Локальный порт прокси';

  @override
  String get localProxyPortDescription => 'HTTP + SOCKS на 127.0.0.1';

  @override
  String get home => 'Главная';

  @override
  String get settings => 'Настройки';

  @override
  String get logs => 'Логи';

  @override
  String get about => 'О приложении';

  @override
  String get newBadge => 'новое';

  @override
  String get copy => 'Копировать';

  @override
  String get clear => 'Очистить';

  @override
  String get searchLogs => 'Поиск по логам';

  @override
  String get noLogsYet => 'Логов пока нет';

  @override
  String get nothingMatchesFilter => 'Ничего не найдено по фильтру';

  @override
  String get editNode => 'Редактировать ноду';

  @override
  String get name => 'Имя';

  @override
  String schema(Object engine) {
    return 'Схема: $engine';
  }

  @override
  String get format => 'Форматировать';

  @override
  String get changesOverwrittenOnRefresh =>
      'Изменения будут перезаписаны при обновлении подписки';

  @override
  String get dnsHijack => 'Перехват DNS в TUN';

  @override
  String get dnsHijackDescription =>
      'Заворачивает весь трафик на порт 53 в DNS-движок. Без него запросы уходят на DNS провайдера и цензурируются';

  @override
  String get dnsProxy => 'DNS для прокси';

  @override
  String get dnsProxyDescription =>
      'Разрешает адреса сайтов, которые идут через VPN';

  @override
  String get dnsDirect => 'DNS для прямых соединений';

  @override
  String get dnsDirectDescription => 'Для сайтов, которые открываются напрямую';

  @override
  String get aboutTagline =>
      'Прокси-клиент для macOS и Windows на базе sing-box и Xray.';

  @override
  String get appVersion => 'Версия приложения';

  @override
  String get checking => 'Проверка…';

  @override
  String get checkForUpdates => 'Проверить обновления';

  @override
  String get upToDate => 'У вас последняя версия';

  @override
  String get general => 'Общие';

  @override
  String get network => 'Сеть';

  @override
  String get changesApplyAfterReconnect =>
      'Изменения применятся после переподключения';

  @override
  String get reconnect => 'Переподключить';

  @override
  String get ipv6Description =>
      'Выключен по умолчанию: многие серверы ходят только по IPv4, и IPv6-соединения зависают вместо отката';

  @override
  String get presetAllProxy => 'Всё через прокси';

  @override
  String get presetBypassRu => 'Обход РФ';

  @override
  String get presetBlockAds => 'Только блок рекламы';

  @override
  String get geoRuSites => 'Россия (сайты)';

  @override
  String get geoRuIp => 'Россия (IP)';

  @override
  String get geoAds => 'Реклама и трекеры';

  @override
  String get geoPrivate => 'Приватные домены';

  @override
  String get geoAdult => 'Взрослый контент';

  @override
  String get geoCnIp => 'Китай (IP)';

  @override
  String get geoCnSites => 'Китай (сайты)';

  @override
  String get singboxCrashed => 'sing-box завершился аварийно';

  @override
  String vpnDisconnectedWithReason(Object reason) {
    return 'VPN отключён: $reason';
  }

  @override
  String geoSetsNotUpdated(Object count) {
    return 'Не обновились: $count наб. (проверьте подключение)';
  }

  @override
  String refreshFailed(Object names) {
    return 'Не удалось обновить: $names';
  }

  @override
  String copyOf(Object name) {
    return '$name (копия)';
  }

  @override
  String healthCheckOk(Object node) {
    return 'проверка $node — ok';
  }

  @override
  String healthCheckFailed(Object node, Object failures, Object limit) {
    return '$node не ответила ($failures из $limit)';
  }

  @override
  String nodeNotRespondingSwitching(Object node) {
    return 'Нода $node не отвечает — подбираем другую';
  }

  @override
  String get helperNotInstalled =>
      'Системный сервис не установлен. Переустановите приложение через установщик (.pkg).';

  @override
  String updateCheckFailed(Object error) {
    return 'Не удалось проверить обновления: $error';
  }

  @override
  String get updateCheckLatest =>
      'Проверка обновлений: установлена последняя версия';

  @override
  String updateCheckAvailable(Object version) {
    return 'Проверка обновлений: доступна $version';
  }

  @override
  String updateDownloadFailed(Object error) {
    return 'Не удалось загрузить обновление: $error';
  }

  @override
  String get noLiveNodes => 'живых нод не найдено, выбор не изменён';

  @override
  String tcpOnlyResult(Object ms) {
    return 'TCP $ms мс (HTTP не прошёл ни у одной ноды)';
  }

  @override
  String get xrayFailedFallback => 'Xray не запустился, откат на sing-box';

  @override
  String get xrayFailedManual =>
      'Xray не запустился, движок выбран вручную — отката нет';

  @override
  String get xrayFailed => 'Xray не запустился';

  @override
  String get vpnNotConnectedXray => 'VPN не подключён: Xray не запустился';

  @override
  String get xrayConfigUnsupported => 'для этой ноды Xray-конфиг не собирается';

  @override
  String xrayStartFailed(Object error) {
    return 'Xray не стартовал: $error';
  }

  @override
  String get xrayUnavailable => 'Xray недоступен на этой платформе';

  @override
  String xraySocksNotResponding(Object port) {
    return 'Xray стартовал, но socks-порт $port не отвечает';
  }

  @override
  String get xrayFailedRunningSingbox =>
      'Xray не запустился, работаем на sing-box';

  @override
  String get engineChosenManually => 'Движок выбран вручную';

  @override
  String get engineChosenAutomatically => 'Движок выбран автоматически';

  @override
  String invalidJson(Object message) {
    return 'Некорректный JSON: $message';
  }

  @override
  String invalidJsonAt(Object message, Object offset) {
    return 'Некорректный JSON: $message (символ $offset)';
  }

  @override
  String get tooManyRedirects => 'слишком много редиректов';

  @override
  String get subscriptionNoValidNodes => 'подписка не содержит валидных нод';

  @override
  String get subscriptionStubNodes => 'подписка вернула ноды-заглушки';

  @override
  String get invalidJsonConfig => 'невалидный JSON-конфиг';

  @override
  String get expectedOutboundObject => 'Ожидается JSON-объект outbound';

  @override
  String get port => 'порт';

  @override
  String testProcessFailed(Object error) {
    return 'тестовый процесс не запустился: $error';
  }

  @override
  String get language => 'Язык';

  @override
  String get interfaceLanguage => 'Язык интерфейса';

  @override
  String get languageSystem => 'Как в системе';

  @override
  String get hotkeys => 'Горячие клавиши';

  @override
  String get toggleHotkey => 'Подключить / отключить';

  @override
  String get toggleHotkeyDescription =>
      'Глобальное сочетание — работает, даже когда окно Verge скрыто';

  @override
  String get hotkeyTaken =>
      'Сочетание занято другим приложением — выберите другое';

  @override
  String get hotkeyNotSet => 'Не задано';

  @override
  String get hotkeyPress => 'Нажмите сочетание…';

  @override
  String get hotkeyNeedsModifier => 'Добавьте Ctrl, Alt или ⌘/Win';

  @override
  String get hotkeyClear => 'Убрать сочетание';
}
