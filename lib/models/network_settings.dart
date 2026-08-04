import 'package:flutter/foundation.dart';

/// Сетевой стек TUN-интерфейса sing-box.
enum TunStack { gvisor, system, mixed }

/// Параметры сборки конфига движка. Отдельно от AppSettings: та описывает UI
/// и запуск приложения, эта — то, что уходит в sing-box и Xray.
///
/// Дефолты обязаны в точности повторять значения, которые до появления этой
/// модели были захардкожены в ConfigBuilder: появление настроек не должно
/// менять поведение, пока пользователь их не тронул.
@immutable
class NetworkSettings {
  /// Весь IPv6 отклоняется правилом route, а DNS работает в ipv4_only.
  /// Upstream (naive и т.п.) ходят только по IPv4, а браузер по
  /// Happy-Eyeballs/HTTPS-подсказкам (ipv6hint) лезет в IPv6 даже при
  /// ipv4_only DNS — такие соединения зависают, и сайты не грузятся.
  final bool ipv6Enabled;

  /// Адрес TUN — из диапазона RFC 2544 (198.18.0.0/15, benchmarking), а НЕ из
  /// 172.16.0.0/12. Docker раздаёт bridge-сети именно в 172.16.0.0/12, и адрес
  /// шлюза docker-сети = первый IP подсети. Прежний '172.19.0.1/30' совпадал с
  /// этим шлюзом → при поднятии TUN хост забирал адреса контейнерной сети на
  /// utun и ломал маршрутизацию контейнеров. 198.18.x не используется ни
  /// Docker, ни LAN, ни VPN — коллизий нет.
  final String tunAddressV4;

  /// Безвреден и нужен, чтобы интерфейс поднимался одинаково независимо от
  /// [ipv6Enabled].
  final String tunAddressV6;

  /// MTU 4064, а НЕ дефолтные 9000. При 9000 server-first протоколы (SSH,
  /// MySQL) вставали: TCP-хендшейк проходил, но как только шёл крупный пакет
  /// (SSH KEX, MySQL handshake), соединение стопорилось — сервер закрывал,
  /// DBeaver ловил link failure. Мелкие запросы (веб) проскакивали.
  final int tunMtu;

  final TunStack tunStack;
  final bool tunStrictRoute;
  final bool tunAutoRoute;

  /// В TUN ОС резолвит через системный DNS, и запрос к LAN-роутеру (приватный
  /// IP) иначе ушёл бы по ip_is_private → direct, на цензурируемый DNS
  /// провайдера. Перехват заворачивает весь :53 в DNS-движок sing-box.
  final bool dnsHijack;

  final String proxyDnsServer;

  /// Bootstrap-DNS: резолвит RU-домены и адрес прокси-сервера напрямую, без
  /// прохода через прокси.
  final String directDnsServer;

  // FakeIP и TTL кэша DNS здесь намеренно отсутствуют: секция dns.fakeip в
  // sing-box 1.12+ объявлена legacy и роняет запуск (нужна запись типа fakeip
  // в dns.servers), а поля dns.ttl не существует вовсе — конфиг с ним не
  // парсится. Настройки убраны до отдельной задачи.

  final bool tlsSkipCertVerify;

  /// sing-box outbound TLS 'fragment': режет TLS-хендшейк на несколько
  /// пакетов, чтобы обойти файрволы с плоским matching по байтам ClientHello.
  /// Доступно с sing-box 1.12.0. Xray этот outbound-параметр не читает —
  /// фрагментация действует только пока активен движок sing-box.
  final bool tlsFragmentEnabled;

  /// sing-box 'record_fragment': фрагментирует на уровне TLS-записей, а не
  /// сырых пакетов. Документация sing-box рекомендует пробовать сначала этот
  /// вариант — он дешевле по перформансу.
  final bool tlsRecordFragment;

  /// sing-box 'fragment_fallback_delay' — задержка в Go duration формате
  /// ('500ms', '1s'), используется, когда автоопределение тайминга
  /// недоступно (не Linux/Apple/Windows-с-привилегиями).
  final String tlsFragmentFallbackDelay;

  const NetworkSettings({
    this.ipv6Enabled = false,
    this.tunAddressV4 = '198.18.0.1/30',
    this.tunAddressV6 = 'fdfe:dcba:9876::1/126',
    this.tunMtu = 4064,
    this.tunStack = TunStack.gvisor,
    this.tunStrictRoute = false,
    this.tunAutoRoute = true,
    this.dnsHijack = true,
    this.proxyDnsServer = '1.1.1.1',
    this.directDnsServer = '77.88.8.8',
    this.tlsSkipCertVerify = false,
    this.tlsFragmentEnabled = false,
    this.tlsRecordFragment = false,
    this.tlsFragmentFallbackDelay = '500ms',
  });

  NetworkSettings copyWith({
    bool? ipv6Enabled,
    String? tunAddressV4,
    String? tunAddressV6,
    int? tunMtu,
    TunStack? tunStack,
    bool? tunStrictRoute,
    bool? tunAutoRoute,
    bool? dnsHijack,
    String? proxyDnsServer,
    String? directDnsServer,
    bool? tlsSkipCertVerify,
    bool? tlsFragmentEnabled,
    bool? tlsRecordFragment,
    String? tlsFragmentFallbackDelay,
  }) =>
      NetworkSettings(
        ipv6Enabled: ipv6Enabled ?? this.ipv6Enabled,
        tunAddressV4: tunAddressV4 ?? this.tunAddressV4,
        tunAddressV6: tunAddressV6 ?? this.tunAddressV6,
        tunMtu: tunMtu ?? this.tunMtu,
        tunStack: tunStack ?? this.tunStack,
        tunStrictRoute: tunStrictRoute ?? this.tunStrictRoute,
        tunAutoRoute: tunAutoRoute ?? this.tunAutoRoute,
        dnsHijack: dnsHijack ?? this.dnsHijack,
        proxyDnsServer: proxyDnsServer ?? this.proxyDnsServer,
        directDnsServer: directDnsServer ?? this.directDnsServer,
        tlsSkipCertVerify: tlsSkipCertVerify ?? this.tlsSkipCertVerify,
        tlsFragmentEnabled: tlsFragmentEnabled ?? this.tlsFragmentEnabled,
        tlsRecordFragment: tlsRecordFragment ?? this.tlsRecordFragment,
        tlsFragmentFallbackDelay:
            tlsFragmentFallbackDelay ?? this.tlsFragmentFallbackDelay,
      );

  Map<String, dynamic> toJson() => {
        'ipv6Enabled': ipv6Enabled,
        'tunAddressV4': tunAddressV4,
        'tunAddressV6': tunAddressV6,
        'tunMtu': tunMtu,
        'tunStack': tunStack.name,
        'tunStrictRoute': tunStrictRoute,
        'tunAutoRoute': tunAutoRoute,
        'dnsHijack': dnsHijack,
        'proxyDnsServer': proxyDnsServer,
        'directDnsServer': directDnsServer,
        'tlsSkipCertVerify': tlsSkipCertVerify,
        'tlsFragmentEnabled': tlsFragmentEnabled,
        'tlsRecordFragment': tlsRecordFragment,
        'tlsFragmentFallbackDelay': tlsFragmentFallbackDelay,
      };

  /// Неизвестное имя enum откатывается на дефолт: конфиг, записанный более
  /// новой версией приложения, не должен ронять старую.
  static T _enumOrDefault<T extends Enum>(
      List<T> values, Object? raw, T fallback) {
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return fallback;
  }

  factory NetworkSettings.fromJson(Map<String, dynamic> json) =>
      NetworkSettings(
        ipv6Enabled: json['ipv6Enabled'] as bool? ?? false,
        tunAddressV4: json['tunAddressV4'] as String? ?? '198.18.0.1/30',
        tunAddressV6:
            json['tunAddressV6'] as String? ?? 'fdfe:dcba:9876::1/126',
        tunMtu: (json['tunMtu'] as num?)?.toInt() ?? 4064,
        tunStack: _enumOrDefault(
            TunStack.values, json['tunStack'], TunStack.gvisor),
        tunStrictRoute: json['tunStrictRoute'] as bool? ?? false,
        tunAutoRoute: json['tunAutoRoute'] as bool? ?? true,
        dnsHijack: json['dnsHijack'] as bool? ?? true,
        proxyDnsServer: json['proxyDnsServer'] as String? ?? '1.1.1.1',
        directDnsServer: json['directDnsServer'] as String? ?? '77.88.8.8',
        tlsSkipCertVerify: json['tlsSkipCertVerify'] as bool? ?? false,
        tlsFragmentEnabled: json['tlsFragmentEnabled'] as bool? ?? false,
        tlsRecordFragment: json['tlsRecordFragment'] as bool? ?? false,
        tlsFragmentFallbackDelay:
            json['tlsFragmentFallbackDelay'] as String? ?? '500ms',
      );

  @override
  bool operator ==(Object other) =>
      other is NetworkSettings &&
      other.ipv6Enabled == ipv6Enabled &&
      other.tunAddressV4 == tunAddressV4 &&
      other.tunAddressV6 == tunAddressV6 &&
      other.tunMtu == tunMtu &&
      other.tunStack == tunStack &&
      other.tunStrictRoute == tunStrictRoute &&
      other.tunAutoRoute == tunAutoRoute &&
      other.dnsHijack == dnsHijack &&
      other.proxyDnsServer == proxyDnsServer &&
      other.directDnsServer == directDnsServer &&
      other.tlsSkipCertVerify == tlsSkipCertVerify &&
      other.tlsFragmentEnabled == tlsFragmentEnabled &&
      other.tlsRecordFragment == tlsRecordFragment &&
      other.tlsFragmentFallbackDelay == tlsFragmentFallbackDelay;

  @override
  int get hashCode => Object.hash(
        ipv6Enabled, tunAddressV4, tunAddressV6, tunMtu, tunStack,
        tunStrictRoute, tunAutoRoute, dnsHijack, proxyDnsServer,
        directDnsServer, tlsSkipCertVerify,
        tlsFragmentEnabled, tlsRecordFragment, tlsFragmentFallbackDelay,
      );
}
