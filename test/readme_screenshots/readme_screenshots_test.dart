// Генератор скриншотов для README. Рендерит настоящий AppShell с демо-данными
// (фейковые туннели, подписка и Clash API) и реальными шрифтами приложения.
//
// Запуск:
//   VERGE_SCREENSHOTS=1 flutter test --update-goldens test/readme_screenshots
//
// Без VERGE_SCREENSHOTS тесты пропускаются, чтобы не мешать обычному прогону.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:singbox_client/app/app_controller.dart';
import 'package:singbox_client/app/tray_popover_controller.dart';
import 'package:singbox_client/app/window_control_channel.dart';
import 'package:singbox_client/models/node_config.dart';
import 'package:singbox_client/platform/platform_info.dart';
import 'package:singbox_client/services/clash_api_client.dart';
import 'package:singbox_client/services/config_builder.dart';
import 'package:singbox_client/services/deep_link.dart';
import 'package:singbox_client/services/ping_service.dart';
import 'package:singbox_client/services/subscription_service.dart';
import 'package:singbox_client/storage/state_repository.dart';
import 'package:singbox_client/theme/app_theme.dart';
import 'package:singbox_client/tunnel/tunnel_controller.dart';
import 'package:singbox_client/ui/app_shell.dart';
import 'package:singbox_client/ui/tray_popover.dart';

final _enabled = Platform.environment.containsKey('VERGE_SCREENSHOTS');

const _windowSize = Size(1100, 720);
const _pixelRatio = 2.0;

class _DemoTunnel extends TunnelController {
  @override
  Future<void> start(Map<String, dynamic> config,
      {required int port, required String service}) async {
    for (final l in _singboxLogs) {
      emitLog(l);
    }
    emit(TunnelStatus.connected);
  }

  @override
  Future<void> stop() async => emit(TunnelStatus.disconnected);
}

class _DemoPlatform extends PlatformInfo {
  @override
  Future<List<String>> listNetworkServices() async => ['Wi-Fi'];
  @override
  Future<String?> defaultService() async => 'Wi-Fi';
  @override
  Future<String> singboxVersion() async => '1.12.4';
  @override
  Future<String> xrayVersion() async => '25.8.3';
  @override
  Future<String> appVersion() async => '1.2.0';
}

/// Правдоподобные задержки без реальной сети.
class _DemoPing extends PingService {
  static const _ms = {
    'nl': 38, 'de': 44, 'fi': 57, 'se': 61, 'pl': 49,
    'us': 128, 'jp': 212, 'tr': 83, 'kz': 71,
  };
  @override
  Future<PingResult> ping(NodeConfig node,
      {Duration timeout = const Duration(seconds: 3),
      bool bypassTunnel = false}) async {
    final ms = _ms[node.host.split('.').first];
    return ms == null ? const PingResult.timeout() : PingResult.ok(ms);
  }
}

/// Отдаёт заранее записанные сообщения Clash API вместо WebSocket.
class _DemoSocket implements ClashSocket {
  _DemoSocket(this._msgs);
  final List<String> _msgs;
  @override
  Stream<String> get messages => Stream.fromIterable(_msgs);
  @override
  Future<void> close() async {}
}

Future<ClashSocket> _openDemoSocket(String url) async {
  if (url.contains('/traffic')) {
    return _DemoSocket([jsonEncode({'up': 184320, 'down': 3276800})]);
  }
  return _DemoSocket([jsonEncode(_connectionsSnapshot())]);
}

Map<String, dynamic> _connectionsSnapshot() {
  final now = DateTime.now().toUtc();
  var n = 0;
  Map<String, dynamic> conn(String host, String ip, int port, String app,
      String chain, String rule, int up, int down,
      {String network = 'tcp', int ageSec = 30}) {
    n++;
    return {
      'id': 'c$n',
      'start': now.subtract(Duration(seconds: ageSec)).toIso8601String(),
      'upload': up,
      'download': down,
      'chains': [chain],
      'rule': rule,
      'rulePayload': '',
      'metadata': {
        'network': network,
        'type': 'tun',
        'host': host,
        'destinationIP': ip,
        'destinationPort': '$port',
        'sourceIP': '172.19.0.1',
        'sourcePort': '${51000 + n * 7}',
        'processPath': app,
      },
    };
  }

  const chrome =
      '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
  const tg = '/Applications/Telegram.app/Contents/MacOS/Telegram';
  const spotify = '/Applications/Spotify.app/Contents/MacOS/Spotify';
  const slack = '/Applications/Slack.app/Contents/MacOS/Slack';
  const safari = '/Applications/Safari.app/Contents/MacOS/Safari';
  const code = '/Applications/Visual Studio Code.app/Contents/MacOS/Electron';
  return {
    'downloadTotal': 1288490188,
    'uploadTotal': 96468992,
    'connections': [
      conn('www.youtube.com', '142.250.74.14', 443, chrome, 'proxy',
          'rule_set=geosite-youtube', 48213, 187432960, ageSec: 412),
      conn('rr3---sn-4g5e6nzz.googlevideo.com', '173.194.182.8', 443, chrome,
          'proxy', 'rule_set=geosite-youtube', 91234, 402653184,
          network: 'udp', ageSec: 398),
      conn('api.telegram.org', '149.154.167.220', 443, tg, 'proxy',
          'rule_set=geosite-telegram', 1203456, 8421376, ageSec: 1805),
      conn('chatgpt.com', '104.18.32.47', 443, chrome, 'proxy',
          'rule_set=geosite-openai', 312456, 5123456, ageSec: 96),
      conn('spclient.wg.spotify.com', '35.186.224.25', 443, spotify, 'proxy',
          'final', 65536, 23068672, ageSec: 640),
      conn('github.com', '140.82.121.4', 443, code, 'proxy', 'final', 23456,
          1843200, ageSec: 54),
      conn('ya.ru', '5.255.255.242', 443, safari, 'direct',
          'rule_set=geosite-category-ru', 8123, 412345, ageSec: 12),
      conn('gosuslugi.ru', '213.59.253.7', 443, safari, 'direct',
          'rule_set=geosite-category-ru', 15360, 921600, ageSec: 230),
      conn('wss-primary.slack.com', '3.120.42.11', 443, slack, 'proxy',
          'final', 204800, 1536000, ageSec: 3120),
      conn('doubleclick.net', '0.0.0.0', 443, chrome, 'block',
          'rule_set=geosite-category-ads-all', 0, 0, ageSec: 3),
      conn('mc.yandex.ru', '87.250.251.119', 443, chrome, 'block',
          'rule_set=geosite-category-ads-all', 0, 0, ageSec: 8),
    ],
  };
}

String _node(String proto, String host, String name) {
  final frag = Uri.encodeComponent(name);
  return switch (proto) {
    'hy2' => 'hysteria2://secret@$host:443?sni=$host#$frag',
    _ => 'vless://6b0f2a4e-1c55-4f3e-9b61-2f2b3e6d7a10@$host:443'
        '?security=reality&sni=www.microsoft.com&fp=chrome&pbk=demo'
        '&type=tcp&flow=xtls-rprx-vision#$frag',
  };
}

final _mainSub = [
  _node('vless', 'nl.vrg.example', '🇳🇱 Нидерланды · Амстердам'),
  _node('vless', 'de.vrg.example', '🇩🇪 Германия · Франкфурт'),
  _node('hy2', 'fi.vrg.example', '🇫🇮 Финляндия · Хельсинки'),
  _node('vless', 'se.vrg.example', '🇸🇪 Швеция · Стокгольм'),
  _node('vless', 'pl.vrg.example', '🇵🇱 Польша · Варшава'),
  _node('vless', 'us.vrg.example', '🇺🇸 США · Нью-Йорк'),
  _node('hy2', 'jp.vrg.example', '🇯🇵 Япония · Токио'),
].join('\n');

final _workSub = [
  _node('vless', 'tr.work.example', '🇹🇷 Турция · Стамбул'),
  _node('vless', 'kz.work.example', '🇰🇿 Казахстан · Алматы'),
].join('\n');

Future<FetchResult> _fetch(String url) async {
  final expire =
      DateTime.now().add(const Duration(days: 23)).millisecondsSinceEpoch ~/
          1000;
  if (url.contains('work')) {
    return FetchResult(base64.encode(utf8.encode(_workSub)), {
      'profile-title': 'Work',
      'subscription-userinfo':
          'upload=0; download=5368709120; total=0; expire=0',
    });
  }
  return FetchResult(base64.encode(utf8.encode(_mainSub)), {
    'profile-title': 'Verge Premium',
    'profile-update-interval': '12',
    'subscription-userinfo':
        'upload=2147483648; download=41875931136; total=107374182400; expire=$expire',
  });
}

const _singboxLogs = [
  'INFO network: updated default interface en0, index 12',
  'INFO inbound/tun[tun-in]: started at utun6',
  'INFO router: loaded rule-set geosite-category-ru',
  'INFO router: loaded rule-set geosite-category-ads-all',
  'INFO router: loaded rule-set geoip-ru',
  'INFO dns: using server dns-remote (https://1.1.1.1/dns-query)',
  'INFO sing-box started (0.41s)',
  'INFO [2981412034 0ms] inbound/tun[tun-in]: inbound connection to www.youtube.com:443',
  'INFO [2981412034 38ms] outbound/vless[proxy]: outbound connection to www.youtube.com:443',
  'INFO [1840022177 0ms] inbound/tun[tun-in]: inbound connection to ya.ru:443',
  'INFO [1840022177 4ms] outbound/direct[direct]: outbound connection to ya.ru:443',
  'WARN dns: exchange failed for ipv6.msftconnecttest.com. AAAA: context deadline exceeded',
  'INFO [3310087120 0ms] inbound/tun[tun-in]: inbound connection to doubleclick.net:443',
  'INFO [3310087120 0ms] router: match[3] rule_set=geosite-category-ads-all => reject',
  'INFO [2217794301 0ms] inbound/tun[tun-in]: inbound connection to api.telegram.org:443',
  'INFO [2217794301 41ms] outbound/vless[proxy]: outbound connection to api.telegram.org:443',
];

/// Шрифты приложения и пакетов (Lucide-иконки, Geist) из FontManifest —
/// без этого flutter_test рисует всё тестовым шрифтом-квадратиками.
Future<void> _loadFonts() async {
  final manifest = jsonDecode(
          await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final f in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(Uri.decodeFull(f['asset'] as String)));
    }
    await loader.load();
  }
}

Future<AppController> _controller(WidgetTester tester) async {
  late AppController c;
  await tester.runAsync(() async {
    c = AppController(
      subscription: SubscriptionService(fetcher: _fetch),
      builder: const ConfigBuilder(),
      proxyTunnel: _DemoTunnel(),
      tunTunnel: _DemoTunnel(),
      repo: InMemoryStateRepository(),
      platform: _DemoPlatform(),
      timerFactory: (d, cb) => Timer(Duration.zero, () {}),
      resolveHost: (_) async => '203.0.113.10',
      pingService: _DemoPing(),
      clashApi: ClashApiClient(open: _openDemoSocket),
      gstaticProbe: (url, port, {timeout = const Duration(seconds: 3)}) async =>
          112,
      bypassProbe: (host, port, {timeout = const Duration(seconds: 3)}) async =>
          38,
    );
    await c.init();
    await c.addProfile('Verge Premium', 'https://sub.example/verge');
    await c.addProfile('Work', 'https://sub.example/work');
    await c.selectRoutingProfile('preset-bypass-ru');
    await c.pingAll();
    await c.connect();
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
  return c;
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  while (tester.takeException() != null) {}
}

Widget _app(AppController c, Widget home, ThemeMode mode) => ShadApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      materialThemeBuilder: (context, theme) => theme.copyWith(
        textTheme: theme.textTheme.apply(
          fontFamily: kUiFontFamily,
          fontFamilyFallback: kEmojiFontFallback,
        ),
      ),
      home: RepaintBoundary(key: _shotKey, child: home),
    );

final _shotKey = GlobalKey();

Future<void> _shoot(String name) async {
  await expectLater(
      find.byKey(_shotKey), matchesGoldenFile('../../docs/screenshots/$name.png'));
}

void main() {
  setUpAll(() async {
    if (_enabled) await _loadFonts();
  });

  // index — пункт сайдбара: 0 Главная, 1 Настройки, 2 Логи, 3 Соединения,
  // 4 Роутинг.
  final shots = <(String, int, ThemeMode)>[
    ('home-light', 0, ThemeMode.light),
    ('home-dark', 0, ThemeMode.dark),
    ('connections', 3, ThemeMode.light),
    ('routing', 4, ThemeMode.light),
    ('settings', 1, ThemeMode.light),
    ('logs', 2, ThemeMode.dark),
  ];

  for (final (name, index, mode) in shots) {
    testWidgets('скриншот $name', (tester) async {
      debugDisableShadows = false;
      tester.view.physicalSize = _windowSize * _pixelRatio;
      tester.view.devicePixelRatio = _pixelRatio;
      addTearDown(tester.view.reset);

      final c = await _controller(tester);
      final deepLink = DeepLinkService();
      await tester.pumpWidget(_app(
        c,
        AppShell(
            controller: c,
            deepLink: deepLink,
            navIndex: ValueNotifier(index)),
        mode,
      ));
      await _pumpFrames(tester);
      await _shoot(name);

      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await c.disconnect();
        c.dispose();
        deepLink.dispose();
      });
      debugDisableShadows = true;
    }, skip: !_enabled);
  }

  testWidgets('скриншот tray', (tester) async {
    debugDisableShadows = false;
    const channel = MethodChannel('window/control');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);

    final c = await _controller(tester);
    final popover = TrayPopoverController(WindowControlChannel(channel),
        waitForFrame: () async {});
    await popover.toggle(TrayPopover.heightFor(c));
    tester.view.physicalSize =
        Size(TrayPopoverController.width, TrayPopover.heightFor(c)) *
            _pixelRatio;
    tester.view.devicePixelRatio = _pixelRatio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(
        c, TrayPopover(controller: c, popover: popover), ThemeMode.dark));
    await _pumpFrames(tester);
    await _shoot('tray');

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await c.disconnect();
      c.dispose();
    });
    debugDisableShadows = true;
  }, skip: !_enabled);
}
