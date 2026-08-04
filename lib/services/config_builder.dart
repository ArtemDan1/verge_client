import '../models/app_settings.dart';
import '../models/network_settings.dart';
import '../models/node_config.dart';
import '../models/routing_profile.dart';
import 'routing_builder.dart';
import 'singbox_outbound_converter.dart';

class ConfigBuilder {
  final int localPort;

  /// Папка на диске с распакованными .srs (gee-наборы). Если задана — rule-set
  /// подключаются локально (type: local), иначе качаются remote.
  final String? geoAssetDir;

  /// Порт и секрет локального Clash API. Задаются вместе; null — API выключен
  /// (так конфиги в тестах остаются детерминированными).
  final int? clashApiPort;
  final String? clashApiSecret;

  /// Параметры сборки конфига, настраиваемые пользователем. Дефолт в точности
  /// повторяет значения, которые раньше были захардкожены здесь же.
  final NetworkSettings network;

  const ConfigBuilder({
    this.localPort = 2080,
    this.geoAssetDir,
    this.clashApiPort,
    this.clashApiSecret,
    this.network = const NetworkSettings(),
  });

  static const _routing = RoutingBuilder();

  /// Правило, которое уводит соединение к самому direct-dns серверу в direct.
  /// Без него запрос к [NetworkSettings.directDnsServer] идёт по route.final →
  /// через ещё не поднятый прокси, и получается bootstrap-петля.
  Map<String, dynamic> get _directDnsRule => {
        'ip_cidr': ['${network.directDnsServer}/32'],
        'outbound': 'direct',
      };

  Map<String, dynamic> build(NodeConfig node,
      {TunnelMode mode = TunnelMode.systemProxy,
      String? serverIp,
      RoutingProfile? routing,
      int? xraySocksPort}) {
    // Без routing-профиля TUN-bypass'ы (серверный IP, приватные сети,
    // process_name: xray) собирать некому — RoutingBuilder не вызывается вовсе.
    // В TUN это не косметика, а защита от петли sing-box → Xray → sing-box,
    // поэтому подставляем пустой профиль вместо того, чтобы пропускать сборку.
    final effectiveRouting = routing ??
        (mode == TunnelMode.tun
            ? const RoutingProfile(
                id: '_implicit', name: '', isBuiltIn: true,
                directRules: [], proxyRules: [], blockRules: [],
                finalAction: RoutingFinal.proxy,
              )
            : null);
    final frag = effectiveRouting == null
        ? const RoutingFragment([], [], 'proxy')
        : _routing.build(effectiveRouting,
            serverIp: serverIp,
            tun: mode == TunnelMode.tun,
            geoAssetDir: geoAssetDir);
    final proxyOut = _proxyOutbound(node, xraySocksPort: xraySocksPort);
    if (mode == TunnelMode.tun) return _buildTun(node, serverIp, frag, proxyOut);
    return _withClashApi(_withRuleSets({
      'log': {'level': 'info', 'timestamp': true},
      'dns': _dns(frag),
      'inbounds': [
        {'type': 'mixed', 'tag': 'mixed-in', 'listen': '127.0.0.1', 'listen_port': localPort}
      ],
      'outbounds': [
        proxyOut,
        {'type': 'direct', 'tag': 'direct'},
      ],
      'route': {
        'rules': [_directDnsRule, ...frag.rules],
        'final': frag.finalTag,
        'default_domain_resolver': 'proxy-dns',
      },
    }, frag));
  }

  /// DNS в новом формате sing-box 1.12+. Резолв по умолчанию идёт через прокси
  /// (proxy-dns) — иначе провайдерский DNS в РФ отравляет заблокированные домены
  /// и они ошибочно матчатся в geoip-ru → уходят direct → не открываются.
  /// Домены из direct-корзины (RU) резолвятся напрямую (direct-dns).
  /// Адрес самого прокси-сервера резолвится direct, чтобы не было bootstrap-петли.
  Map<String, dynamic> _dns(RoutingFragment frag) => {
        'servers': [
          {
            'type': 'https',
            'tag': 'proxy-dns',
            'server': network.proxyDnsServer,
            'detour': 'proxy',
            'domain_resolver': 'direct-dns',
          },
          {
            // ВНИМАНИЕ: без detour. В sing-box 1.13 detour DNS-сервера на пустой
            // direct outbound — FATAL ("makes no sense"). Прямой маршрут к этому
            // серверу обеспечивает route-правило _directDnsRule.
            'type': 'https',
            'tag': 'direct-dns',
            'server': network.directDnsServer,
            'tls': {'server_name': 'common.dot.dns.yandex.net'},
          },
        ],
        if (frag.dnsRules.isNotEmpty) 'rules': frag.dnsRules,
        'final': 'proxy-dns',
        'strategy': network.ipv6Enabled ? 'prefer_ipv4' : 'ipv4_only',
      };

  /// Протоколы, которые не переносят UDP (только TCP). Для них в TUN нужно
  /// отклонять QUIC, иначе UDP-пакеты уходят в proxy-outbound и дропаются.
  static bool _isTcpOnly(NodeProtocol p) => p == NodeProtocol.naive;

  Map<String, dynamic> _buildTun(
      NodeConfig node, String? serverIp, RoutingFragment frag, Map<String, dynamic> proxyOut) {
    // naive — это HTTP/2 CONNECT, UDP он не умеет. В системном прокси браузер
    // сам шлёт в HTTP-прокси только TCP, а в TUN перехватываются сырые пакеты,
    // включая QUIC (UDP/443). Без reject QUIC уходит в naive и дропается, сайты
    // «не открываются» (особенно YouTube/Instagram — они QUIC-тяжёлые).
    // Матчим по network+port (L4), а НЕ по protocol: sing-box 1.11+ не сниффит
    // автоматически, sniff в конфиге не включён, поэтому правило protocol:quic
    // было бы мёртвым. Reject UDP/443 заставляет приложения откатиться на TCP.
    final quicReject = _isTcpOnly(node.protocol)
        ? [
            {'network': 'udp', 'port': 443, 'action': 'reject'}
          ]
        : const <Map<String, dynamic>>[];
    return _withClashApi(_withRuleSets({
      // Без 'output': лог должен идти в stdout, иначе helper его не видит и
      // экран «Логи» в TUN-режиме остаётся пустым.
      'log': {'level': 'info', 'timestamp': true},
      'dns': _dns(frag),
      'inbounds': [
        {
          'type': 'tun',
          'tag': 'tun-in',
          // На macOS имя интерфейса обязано быть формата utunN; произвольное
          // ('utun-singbox') ядро отвергает с "bad tun name". Не задаём —
          // sing-box сам берёт свободный utunN.
          //
          // Обоснование значений адреса, MTU и stack — в комментариях к полям
          // NetworkSettings. Менять их вслепую нельзя.
          'address': [network.tunAddressV4, network.tunAddressV6],
          'auto_route': network.tunAutoRoute,
          'strict_route': network.tunStrictRoute,
          'mtu': network.tunMtu,
          'stack': network.tunStack.name,
        }
      ],
      'outbounds': [
        proxyOut,
        {'type': 'direct', 'tag': 'direct'},
      ],
      'route': {
        // hijack-dns ПЕРВЫМ: в TUN ОС резолвит через системный DNS, и запрос к
        // LAN-роутеру (приватный IP) иначе ушёл бы по ip_is_private → direct, на
        // цензурируемый DNS провайдера (instagram→127.0.0.1). Перехват заворачивает
        // весь :53 в DNS-движок sing-box → резолв через прокси, без цензуры.
        // (Дополнительно приложение переопределяет системный DNS на TUN, иначе
        // запрос к роутеру вообще не входит в туннель и перехватывать нечего.)
        'rules': [
          if (network.dnsHijack) {'action': 'hijack-dns', 'port': 53},
          // Отклоняем весь IPv6: upstream (naive и т.п.) ходят только по IPv4, а
          // браузер по Happy-Eyeballs/HTTPS-подсказкам (ipv6hint) лезет в IPv6
          // даже при ipv4_only DNS — такие соединения зависают в naive, и сайты
          // (Instagram/Meta по IPv6) не грузятся. reject → откат браузера на IPv4.
          // ВАЖНО: до sniff. sniff удерживает соединение до TLS ClientHello; если
          // ipv6-reject стоит ПОСЛЕ sniff, IPv6-соединение держится открытым до
          // ClientHello, браузер по Happy-Eyeballs коммитится на IPv6 и шлёт
          // запрос — и только потом reject → ERR_CONNECTION_CLOSED без отката.
          if (!network.ipv6Enabled) {'ip_version': 6, 'action': 'reject'},
          // QUIC-reject тоже до sniff: рубим UDP/443 мгновенно, не дожидаясь sniff.
          ...quicReject,
          // sniff извлекает домен из TLS/HTTP для доменного роутинга (geosite/
          // domain_suffix): в TUN перехватываются сырые IP-пакеты, без sniff домен
          // неизвестен и доменные правила молча не матчатся (работает только geoip).
          // RU-сайт на не-RU IP (напр. 2ip.ru на Hetzner) без sniff уходил в proxy
          // (IP VPN), хотя по домену .ru должен идти direct (IP провайдера).
          //
          // ВАЖНО: только порты 80/443. sniff читает домен из ПЕРВОГО пакета
          // КЛИЕНТА (TLS ClientHello / HTTP-запрос) — это работает лишь для
          // client-first протоколов (веб). SSH, MySQL, Postgres, Redis, SMTP, RDP —
          // server-first: первым шлёт данные СЕРВЕР, клиент молчит. Глобальный sniff
          // держал такое соединение, ожидая пакет от клиента, клиент ждал сервер →
          // дедлок, коннект отваливался (MySQL «read 0 bytes, connection lost», SSH
          // висел). В system-proxy sniff нет — потому там эти протоколы работали.
          // Домен нужен только для веба, поэтому сниффим 80/443, остальное (в т.ч.
          // SSH/БД на любых портах) пропускаем без sniff — роутинг по IP/geoip.
          // Стоит после быстрых терминальных режектов — сниффим выжившие TCP/IPv4.
          {'port': [80, 443], 'action': 'sniff'},
          _directDnsRule,
          ...frag.rules,
        ],
        'final': frag.finalTag,
        'auto_detect_interface': true,
        'default_domain_resolver': 'proxy-dns',
      },
    }, frag, cacheFile: 'cache-tun.db'));
  }

  /// Clash API — единственный источник данных для экрана «Соединения» и
  /// счётчиков трафика. find_process нужен, чтобы sing-box заполнял
  /// metadata.processPath (имя приложения в карточке).
  Map<String, dynamic> _withClashApi(Map<String, dynamic> cfg) {
    final port = clashApiPort;
    final secret = clashApiSecret;
    if (port == null || secret == null) return cfg;
    // Дополняем, а не заменяем: тут уже может лежать cache_file.
    final exp = (cfg['experimental'] as Map<String, dynamic>?) ?? {};
    exp['clash_api'] = {
      'external_controller': '127.0.0.1:$port',
      'secret': secret,
    };
    cfg['experimental'] = exp;
    (cfg['route'] as Map<String, dynamic>)['find_process'] = true;
    return cfg;
  }

  /// Добавляет route.rule_set и experimental.cache_file, если есть geo-наборы.
  /// [cacheFile] разный для разных режимов: systemProxy-sing-box (от пользователя)
  /// и TUN-sing-box (от root через helper) могут работать одновременно, а bbolt
  /// берёт эксклюзивный flock на файл кэша — общий путь приводит к FATAL
  /// "initialize cache-file: timeout" у второго процесса. Разные файлы это
  /// исключают (и заодно root не перетирает владельца user-кэша).
  Map<String, dynamic> _withRuleSets(
      Map<String, dynamic> cfg, RoutingFragment frag,
      {String cacheFile = 'cache.db'}) {
    if (frag.ruleSets.isNotEmpty) {
      (cfg['route'] as Map<String, dynamic>)['rule_set'] = frag.ruleSets;
      // Путь обязан быть абсолютным: cwd процесса, запущенного из /Applications,
      // равен "/", и относительный cache.db падает с FATAL (read-only file
      // system). Пишем в geoAssetDir (та же writable-папка app support).
      final cachePath =
          geoAssetDir != null ? '$geoAssetDir/$cacheFile' : cacheFile;
      cfg['experimental'] = {
        'cache_file': {'enabled': true, 'path': cachePath}
      };
    }
    return cfg;
  }

  /// Outbound на прокси: либо socks5 в локальный Xray, либо из готового
  /// оригинала (конвертируя, если он в схеме Xray), либо собранный из params.
  Map<String, dynamic> _proxyOutbound(NodeConfig n, {int? xraySocksPort}) {
    if (xraySocksPort != null) {
      // sing-box заворачивает весь трафик в Xray-процесс через loopback socks.
      // udp_over_tcp выключен: hysteria2 поверх QUIC не должен упаковываться в TCP.
      return {
        'type': 'socks',
        'tag': 'proxy',
        'server': '127.0.0.1',
        'server_port': xraySocksPort,
        'version': '5',
        'udp_over_tcp': false,
      };
    }
    return _outboundFor(n);
  }

  /// Outbound: из готового оригинала (конвертируя, если он в схеме Xray) либо
  /// собранный из params.
  Map<String, dynamic> _outboundFor(NodeConfig n) {
    final raw = n.rawOutbound;
    final Map<String, dynamic> out;
    if (raw == null) {
      out = _outbound(n);
    } else if (n.rawSchema == RawSchema.xray) {
      // Оригинал в схеме Xray — конвертируем. Если протокол не поддержан
      // sing-box'ом, падать нельзя: собираем из params как обычную ноду.
      out = xrayOutboundToSingbox(raw) ?? _outbound(n);
    } else {
      out = {...raw, 'tag': 'proxy'};
    }
    // Адрес прокси-сервера резолвим напрямую — иначе bootstrap-петля
    // (proxy-dns ходит через ещё не поднятый прокси).
    out['domain_resolver'] = 'direct-dns';
    if (out['tls'] is Map) {
      final tls = out['tls'] as Map<String, dynamic>;
      // Пропуск проверки сертификата — осознанное понижение безопасности,
      // поэтому пишем ключ только когда он явно включён.
      if (network.tlsSkipCertVerify) tls['insecure'] = true;
      // sing-box outbound TLS fragment (с 1.12.0): режет хендшейк, чтобы
      // обойти файрволы с плоским matching по байтам ClientHello. Xray этот
      // параметр не читает — фрагментация работает только под sing-box.
      if (network.tlsFragmentEnabled) {
        tls['fragment'] = true;
        tls['fragment_fallback_delay'] = network.tlsFragmentFallbackDelay;
      }
      if (network.tlsRecordFragment) tls['record_fragment'] = true;
    }
    return out;
  }

  Map<String, dynamic> _outbound(NodeConfig n) {
    switch (n.protocol) {
      case NodeProtocol.vless:
        return _vless(n);
      case NodeProtocol.naive:
        return _naive(n);
      case NodeProtocol.hysteria2:
        return _hysteria2(n);
    }
  }

  Map<String, dynamic> _vless(NodeConfig n) {
    final tls = <String, dynamic>{'enabled': true, 'server_name': n.params['sni'] ?? n.host};
    if (n.params['fp'] != null) {
      tls['utls'] = {'enabled': true, 'fingerprint': n.params['fp']};
    }
    if (n.params['security'] == 'reality') {
      tls['reality'] = {'enabled': true, 'public_key': n.params['pbk'] ?? '', 'short_id': n.params['sid'] ?? ''};
    }
    final out = <String, dynamic>{
      'type': 'vless', 'tag': 'proxy', 'server': n.host, 'server_port': n.port,
      'uuid': n.params['uuid'] ?? '', 'tls': tls,
    };
    if ((n.params['flow'] ?? '').isNotEmpty) out['flow'] = n.params['flow'];
    return out;
  }

  Map<String, dynamic> _naive(NodeConfig n) => {
        'type': 'naive', 'tag': 'proxy', 'server': n.host, 'server_port': n.port,
        'username': n.params['username'] ?? '', 'password': n.params['password'] ?? '',
        'tls': {'enabled': true, 'server_name': n.host},
      };

  Map<String, dynamic> _hysteria2(NodeConfig n) => {
        'type': 'hysteria2', 'tag': 'proxy', 'server': n.host, 'server_port': n.port,
        'password': n.params['password'] ?? '',
        'tls': {'enabled': true, 'server_name': n.params['sni'] ?? n.host},
      };
}
