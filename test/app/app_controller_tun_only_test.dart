// AppController в режиме tunOnly (Android): только VPN, приложение исключено
// из туннеля, VPN может пережить интерфейс.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/app/app_controller.dart';
import 'package:singbox_client/models/app_settings.dart';
import 'package:singbox_client/models/node_engine.dart';
import 'package:singbox_client/models/persisted_state.dart';
import 'package:singbox_client/services/clash_api_client.dart';
import 'package:singbox_client/services/config_builder.dart';
import 'package:singbox_client/services/subscription_service.dart';
import 'package:singbox_client/storage/state_repository.dart';
import 'package:singbox_client/tunnel/android_vpn_tunnel.dart';
import 'package:singbox_client/tunnel/tunnel_controller.dart';

import 'app_controller_test.dart' show FakePlatformInfo, FakeTunnel, fakeSub;

/// VPN, который может быть уже поднят к старту UI.
class FakeVpn extends TunnelController
    implements AttachableTunnel, DetailedTunnel {
  FakeVpn({this.running});

  /// Конфиг «уже работающего» туннеля; null — VPN не поднят.
  Map<String, dynamic>? running;
  int startCalls = 0;
  Map<String, dynamic>? lastConfig;
  final details = <String?>[];

  @override
  Future<void> setDetails(String? text) async => details.add(text);

  /// VPN поднялся сам (плитка быстрых настроек), а не через start().
  void startedOutside(Map<String, dynamic> config) {
    running = config;
    emit(TunnelStatus.connected);
  }

  @override
  Future<void> start(Map<String, dynamic> config,
      {required int port, required String service}) async {
    startCalls++;
    lastConfig = config;
    emit(TunnelStatus.connected);
  }

  @override
  Future<void> stop() async {
    running = null;
    emit(TunnelStatus.disconnected);
  }

  @override
  Future<Map<String, dynamic>?> attach() async {
    final cfg = running;
    if (cfg == null) return null;
    emit(TunnelStatus.connected);
    return cfg;
  }
}

class _NullSocket implements ClashSocket {
  @override
  Stream<String> get messages => const Stream.empty();
  @override
  Future<void> close() async {}
}

void main() {
  late List<String> openedUrls;

  AppController make({
    required TunnelController vpn,
    TunnelController? proxy,
    StateRepository? repo,
  }) =>
      AppController(
        subscription: SubscriptionService(
            fetcher: (_) async => FetchResult(fakeSub, const {})),
        builder: const ConfigBuilder(),
        proxyTunnel: proxy ?? FakeTunnel(),
        tunTunnel: vpn,
        repo: repo ?? InMemoryStateRepository(),
        platform: FakePlatformInfo(),
        resolveHost: (_) async => '9.9.9.9',
        timerFactory: (d, cb) => Timer(const Duration(days: 1), () {}),
        gstaticProbe: (url, port, {timeout = const Duration(seconds: 3)}) async =>
            null,
        bypassProbe: (host, port, {timeout = const Duration(seconds: 3)}) async =>
            null,
        clashApi: ClashApiClient(open: (url) async {
          openedUrls.add(url);
          return _NullSocket();
        }),
        tunOnly: true,
      );

  setUp(() => openedUrls = []);

  test('подключается через VPN, даже если в настройках системный прокси',
      () async {
    final vpn = FakeVpn();
    final proxy = FakeTunnel();
    final c = make(vpn: vpn, proxy: proxy);
    await c.init();
    await c.addProfile('Sub', 'https://x');
    expect(c.settings.tunnelMode, TunnelMode.systemProxy);
    expect(c.tunnelMode, TunnelMode.tun);

    await c.connect();

    expect(vpn.startCalls, 1);
    expect(proxy.startCallCount, 0);
    expect(c.status, TunnelStatus.connected);
    final inbounds = (vpn.lastConfig!['inbounds'] as List).cast<Map>();
    expect(inbounds.map((i) => i['type']), ['tun', 'mixed']);
    // Mixed-инбаунд — для собственного трафика приложения (гео-наборы):
    // само приложение в VPN не попадает.
    expect(inbounds.last['listen'], '127.0.0.1');
    expect(inbounds.last['listen_port'], c.settings.localPort);
  });

  test('подхватывает уже работающий VPN и его Clash API', () async {
    final vpn = FakeVpn(running: {
      'outbounds': [
        {'type': 'vless', 'tag': 'proxy'},
        {'type': 'direct', 'tag': 'direct'},
      ],
      'experimental': {
        'clash_api': {
          'external_controller': '127.0.0.1:45678',
          'secret': 's3cr3t',
        },
      },
    });
    final c = make(vpn: vpn);
    await c.init();
    await Future<void>.delayed(Duration.zero);

    expect(vpn.startCalls, 0);
    expect(c.status, TunnelStatus.connected);
    expect(c.connectedAt, isNotNull);
    expect(c.activeEngine, NodeEngine.singbox);
    expect(openedUrls, contains('ws://127.0.0.1:45678/traffic?token=s3cr3t'));
    await c.disconnect();
  });

  test('Xray-подключение узнаётся по socks-outbound на loopback', () async {
    final vpn = FakeVpn(running: {
      'outbounds': [
        {
          'type': 'socks',
          'tag': 'proxy',
          'server': '127.0.0.1',
          'server_port': 10808,
        },
      ],
    });
    final c = make(vpn: vpn);
    await c.init();
    expect(c.activeEngine, NodeEngine.xray);
    await c.disconnect();
  });

  test('автозапуск не поднимает второй туннель поверх подхваченного',
      () async {
    final repo = InMemoryStateRepository();
    // Профиль с выбранной нодой и включённым автозапуском.
    final seed = make(vpn: FakeVpn(), repo: repo);
    await seed.init();
    await seed.addProfile('Sub', 'https://x');
    await seed.updateSettings(seed.settings.copyWith(autostart: true));
    seed.dispose();

    final vpn = FakeVpn(running: const {'outbounds': []});
    final c = make(vpn: vpn, repo: repo);
    await c.init();
    expect(vpn.startCalls, 0);
    expect(c.status, TunnelStatus.connected);
    await c.disconnect();
  });

  test('без работающего VPN автозапуск подключает как обычно', () async {
    final repo = InMemoryStateRepository(const PersistedState());
    final seed = make(vpn: FakeVpn(), repo: repo);
    await seed.init();
    await seed.addProfile('Sub', 'https://x');
    await seed.updateSettings(seed.settings.copyWith(autostart: true));
    seed.dispose();

    final vpn = FakeVpn();
    final c = make(vpn: vpn, repo: repo);
    await c.init();
    expect(vpn.startCalls, 1);
    await c.disconnect();
  });

  test('VPN, включённый плиткой при открытом приложении, подхватывается',
      () async {
    final vpn = FakeVpn();
    final c = make(vpn: vpn);
    await c.init();
    expect(c.status, TunnelStatus.disconnected);

    vpn.startedOutside({
      'outbounds': [
        {'type': 'vless', 'tag': 'proxy'},
      ],
      'experimental': {
        'clash_api': {'external_controller': '127.0.0.1:40001', 'secret': 'k'},
      },
    });
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(c.status, TunnelStatus.connected);
    expect(c.activeEngine, NodeEngine.singbox);
    expect(openedUrls, contains('ws://127.0.0.1:40001/traffic?token=k'));
    await c.disconnect();
  });

  test('в уведомление уходят сервер и пинг активной ноды', () async {
    final vpn = FakeVpn();
    final c = make(vpn: vpn);
    await c.init();
    await c.addProfile('Sub', 'https://x');
    await c.connect();
    await Future<void>.delayed(Duration.zero);
    expect(vpn.details.last, 'A');

    await c.pingNode(c.selectedNode!);
    // Пинг в тестовой среде не проходит — строка остаётся без мс, но
    // отправляется заново после каждого замера активной ноды.
    expect(vpn.details.length, greaterThanOrEqualTo(2));
    await c.disconnect();
  });
}
