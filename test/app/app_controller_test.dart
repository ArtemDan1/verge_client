import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/app/app_controller.dart';
import 'package:singbox_client/services/update_service.dart';
import 'package:singbox_client/models/app_settings.dart';
import 'package:singbox_client/models/persisted_state.dart';
import 'package:singbox_client/models/routing_profile.dart';
import 'package:singbox_client/services/subscription_service.dart';
import 'package:singbox_client/services/config_builder.dart';
import 'package:singbox_client/storage/state_repository.dart';
import 'package:singbox_client/platform/platform_info.dart';
import 'package:singbox_client/platform/helper_service.dart';
import 'package:singbox_client/tunnel/tunnel_controller.dart';
import 'package:singbox_client/services/ping_service.dart';
import 'package:singbox_client/models/node_config.dart';
import 'package:singbox_client/services/clash_api_client.dart';

const fakeSub =
    'vless://uid@h:443?security=reality#A\nvless://uid@h2:443#B';

class FakeTunnel extends TunnelController {
  Map<String, dynamic>? lastConfig;
  int? lastPort;
  String? lastService;
  int startCallCount = 0;
  int stopCallCount = 0;
  @override
  Future<void> start(Map<String, dynamic> config,
      {required int port, required String service}) async {
    startCallCount++;
    lastConfig = config;
    lastPort = port;
    lastService = service;
    emit(TunnelStatus.connected);
  }
  @override
  Future<void> stop() async {
    stopCallCount++;
    emit(TunnelStatus.disconnected);
  }
}

class FakePlatformInfo extends PlatformInfo {
  final List<String> services;
  final String? defaultNetworkService;
  int listNetworkServicesCallCount = 0;
  int defaultServiceCallCount = 0;

  FakePlatformInfo({
    this.services = const ['Wi-Fi', 'Ethernet'],
    this.defaultNetworkService = 'Ethernet',
  });

  @override
  Future<List<String>> listNetworkServices() async {
    listNetworkServicesCallCount++;
    return services;
  }

  @override
  Future<String?> defaultService() async {
    defaultServiceCallCount++;
    return defaultNetworkService;
  }

  @override
  Future<String> singboxVersion() async => '1.13.12';

  @override
  Future<String> appVersion() async => '1.0.0+1';

  String? openedPath;
  /// Статус туннеля на момент запуска установщика — установщик перезапишет
  /// бандл и выгрузит демона, поэтому туннель должен быть уже погашен.
  bool tunnelActiveOnInstall = false;
  AppController? observed;
  @override
  Future<void> installUpdate(String path) async {
    openedPath = path;
    final s = observed?.status;
    tunnelActiveOnInstall =
        s == TunnelStatus.connected || s == TunnelStatus.connecting;
  }
}

class FakeUpdateService extends UpdateService {
  FakeUpdateService({this.info, this.checkError});
  final UpdateInfo? info;
  final Object? checkError;
  int checkCalls = 0;
  String? downloadedFrom;

  @override
  Future<UpdateInfo?> checkForUpdate(String currentVersion) async {
    checkCalls++;
    if (checkError != null) throw checkError!;
    return info;
  }

  @override
  Future<String> downloadPkg(String url,
      {void Function(double)? onProgress, Directory? targetDir}) async {
    downloadedFrom = url;
    onProgress?.call(1.0);
    return '/tmp/SingboxFlutter-update.pkg';
  }
}

class FakeTimer implements Timer {
  bool cancelled = false;
  @override
  void cancel() => cancelled = true;
  @override
  bool get isActive => !cancelled;
  @override
  int get tick => 0;
}

class ControlledTimerFactory {
  FakeTimer? _timer;
  void Function(Timer)? _callback;
  Duration? capturedDuration;
  int callCount = 0;

  Timer call(Duration duration, void Function(Timer) callback) {
    callCount++;
    capturedDuration = duration;
    _callback = callback;
    _timer = FakeTimer();
    return _timer!;
  }

  void fire() => _callback?.call(_timer!);
}

class _FakePing implements PingService {
  final PingResult Function(NodeConfig) handler;
  _FakePing(this.handler);
  @override
  Future<PingResult> ping(NodeConfig node, {Duration timeout = const Duration(seconds: 3)}) async =>
      handler(node);
}

class FakeHelper extends HelperService {
  FakeHelper(this._statuses);
  final List<String> _statuses; // последовательность ответов status()
  int statusCalls = 0;

  @override
  Future<String> status() async {
    final i = statusCalls < _statuses.length ? statusCalls : _statuses.length - 1;
    statusCalls++;
    return _statuses[i];
  }
}

late FakeTunnel proxyTunnel;
late FakeTunnel tunTunnel;

AppController build({
  SubscriptionService? sub,
  StateRepository? repo,
  FakeTunnel? proxy,
  FakeTunnel? tun,
  PlatformInfo? platform,
  PingService? pingService,
  HelperService? helper,
  UpdateService? updateService,
  ClashApiClient? clashApi,
}) =>
    AppController(
      subscription: sub ??
          SubscriptionService(fetcher: (_) async => FetchResult(fakeSub, const {})),
      builder: const ConfigBuilder(),
      proxyTunnel: proxy ?? proxyTunnel,
      tunTunnel: tun ?? tunTunnel,
      repo: repo ?? InMemoryStateRepository(),
      platform: platform ?? FakePlatformInfo(),
      resolveHost: (_) async => '9.9.9.9',
      pingService: pingService,
      helper: helper,
      updateService: updateService,
      clashApi: clashApi,
    );

void main() {
  setUp(() {
    proxyTunnel = FakeTunnel();
    tunTunnel = FakeTunnel();
  });

  test('статус неактивного туннеля не перетирает активный', () async {
    final app = build();
    await app.init(); // режим по умолчанию systemProxy → активен proxyTunnel
    await app.addProfile('Sub', 'https://x');
    await app.selectNode(app.profiles.first.id, 0);
    await app.connect();
    expect(app.status, TunnelStatus.connected);
    // Неактивный TUN-туннель эмитит error (как при опросе мёртвого хелпера).
    tunTunnel.emit(TunnelStatus.error);
    await Future<void>.delayed(Duration.zero);
    expect(app.status, TunnelStatus.connected); // не перетёрт
  });

  test('крах активного туннеля выставляет error и шлёт alert', () async {
    final app = build();
    await app.init();
    await app.addProfile('Sub', 'https://x');
    await app.selectNode(app.profiles.first.id, 0);
    await app.connect();

    final alerts = <String>[];
    final sub = app.alerts.listen(alerts.add);

    proxyTunnel.lastError = 'FATAL: detour to an empty direct outbound';
    proxyTunnel.emit(TunnelStatus.error);
    await Future<void>.delayed(Duration.zero);

    expect(app.status, TunnelStatus.error);
    expect(app.error, contains('detour to an empty direct'));
    expect(alerts.single, contains('detour to an empty direct'));
    await sub.cancel();
  });

  test('addProfile сохраняет профиль с нодами и выбирает первую', () async {
    final repo = InMemoryStateRepository();
    final app = build(repo: repo);
    await app.init();
    await app.addProfile('Sub', 'https://x');
    expect(app.profiles, hasLength(1));
    expect(app.profiles.first.nodes, hasLength(2));
    expect(app.profiles.first.selectedNodeIndex, 0);
    expect((await repo.load()).profiles, hasLength(1)); // persisted
  });

  test('addProfile при ошибке fetch пробрасывает и не создаёт профиль', () async {
    final app = build(
        sub: SubscriptionService(fetcher: (_) async => FetchResult('ss://bad', const {})));
    await app.init();
    await expectLater(
        app.addProfile('Bad', 'https://x'), throwsA(isA<Exception>()));
    expect(app.profiles, isEmpty);
  });

  test('selectNode делает профиль активным и меняет индекс', () async {
    final app = build();
    await app.init();
    await app.addProfile('Sub', 'https://x');
    final id = app.profiles.first.id;
    await app.selectNode(id, 1);
    expect(app.activeProfileId, id);
    expect(app.selectedNode!.name, 'B');
  });

  test('connect строит конфиг и передаёт порт+сервис из настроек', () async {
    final app = build();
    await app.init();
    await app.updateSettings(const AppSettings(localPort: 1080, networkService: 'auto'));
    await app.addProfile('Sub', 'https://x');
    await app.connect();
    expect(proxyTunnel.lastConfig!['inbounds'][0]['listen_port'], 1080);
    expect(proxyTunnel.lastPort, 1080);
    expect(proxyTunnel.lastService, 'Ethernet'); // auto → defaultService()
    expect(app.status, TunnelStatus.connected);
  });

  test('connect с явным networkService использует его без auto fallback', () async {
    final platform = FakePlatformInfo(
      services: const ['Wi-Fi', 'Ethernet'],
      defaultNetworkService: 'Ethernet',
    );
    final app = build(platform: platform);
    await app.init();
    await app.updateSettings(
      const AppSettings(localPort: 1080, networkService: 'Wi-Fi'),
    );
    await app.addProfile('Sub', 'https://x');
    await app.connect();

    expect(proxyTunnel.lastService, 'Wi-Fi');
    expect(platform.defaultServiceCallCount, 0);
    expect(platform.listNetworkServicesCallCount, 0);
  });

  test('connect auto выбирает Wi-Fi если defaultService не найден', () async {
    final app = build(
      platform: FakePlatformInfo(
        services: const [
          'Thunderbolt Bridge',
          'Wi-Fi',
          'Happ',
          'v2RayTun',
          'Karing (system)',
        ],
        defaultNetworkService: null,
      ),
    );
    await app.init();
    await app.updateSettings(
      const AppSettings(localPort: 1080, networkService: 'auto'),
    );
    await app.addProfile('Sub', 'https://x');
    await app.connect();

    expect(proxyTunnel.lastService, 'Wi-Fi');
  });

  test('connect auto без Wi-Fi выбирает первый non-disabled service', () async {
    final app = build(
      platform: FakePlatformInfo(
        services: const ['*Disabled VPN', 'Ethernet', 'USB 10/100/1000 LAN'],
        defaultNetworkService: '',
      ),
    );
    await app.init();
    await app.updateSettings(
      const AppSettings(localPort: 1080, networkService: 'auto'),
    );
    await app.addProfile('Sub', 'https://x');
    await app.connect();

    expect(proxyTunnel.lastService, 'Ethernet');
  });

  test('refreshProfile обновляет ноды и сохраняет валидный индекс', () async {
    final app = build();
    await app.init();
    await app.addProfile('Sub', 'https://x');
    final id = app.profiles.first.id;
    await app.selectNode(id, 1);
    await app.refreshProfile(id);
    expect(app.profiles.first.nodes, hasLength(2));
    expect(app.profiles.first.selectedNodeIndex, 1);
  });

  test('removeProfile удаляет и чистит активный', () async {
    final app = build();
    await app.init();
    await app.addProfile('Sub', 'https://x');
    final id = app.profiles.first.id;
    await app.selectNode(id, 0);
    await app.removeProfile(id);
    expect(app.profiles, isEmpty);
    expect(app.activeProfileId, isNull);
  });

  test('init с autostart коннектит выбранную ноду', () async {
    final repo = InMemoryStateRepository();
    final seed = build(repo: repo);
    await seed.init();
    await seed.updateSettings(const AppSettings(autostart: true));
    await seed.addProfile('Sub', 'https://x');
    await seed.selectNode(seed.profiles.first.id, 0);

    final proxy2 = FakeTunnel();
    final tun2 = FakeTunnel();
    final app2 = build(repo: repo, proxy: proxy2, tun: tun2);
    await app2.init();
    expect(app2.status, TunnelStatus.connected);
  });

  test('TUN-режим строит tun-конфиг и использует tunTunnel', () async {
    final app = build();
    await app.addProfile('p', 'https://x');
    await app.selectNode(app.profiles.first.id, 0);
    await app.updateSettings(app.settings.copyWith(tunnelMode: TunnelMode.tun));
    await app.connect();
    expect(tunTunnel.lastConfig, isNotNull);
    expect(tunTunnel.lastConfig!['inbounds'][0]['type'], 'tun');
    expect(proxyTunnel.lastConfig, isNull);
  });

  test('смена режима при активном туннеле гасит старый и поднимает новый', () async {
    final app = build();
    await app.addProfile('p', 'https://x');
    await app.selectNode(app.profiles.first.id, 0);
    await app.connect(); // systemProxy активен
    expect(proxyTunnel.startCallCount, 1);
    expect(app.status, TunnelStatus.connected);

    // Переключение на TUN на ходу: старый proxy-туннель должен быть остановлен,
    // иначе работают два sing-box одновременно (двойной роутинг, конфликт кэша).
    await app.updateSettings(app.settings.copyWith(tunnelMode: TunnelMode.tun));

    expect(proxyTunnel.stopCallCount, 1);
    expect(tunTunnel.startCallCount, 1);
    expect(app.status, TunnelStatus.connected);
  });

  test('смена режима без активного подключения не запускает туннель', () async {
    final app = build();
    await app.addProfile('p', 'https://x');
    await app.selectNode(app.profiles.first.id, 0);
    // Не подключены — простая смена настройки не должна сама коннектить.
    await app.updateSettings(app.settings.copyWith(tunnelMode: TunnelMode.tun));
    expect(proxyTunnel.startCallCount, 0);
    expect(tunTunnel.startCallCount, 0);
    expect(app.status, TunnelStatus.disconnected);
  });

  test('systemProxy-режим использует proxyTunnel с mixed-конфигом', () async {
    final app = build();
    await app.addProfile('p', 'https://x');
    await app.selectNode(app.profiles.first.id, 0);
    await app.connect();
    expect(proxyTunnel.lastConfig!['inbounds'][0]['type'], 'mixed');
    expect(tunTunnel.lastConfig, isNull);
  });

  group('auto-refresh', () {
    test('disabled по умолчанию — timerFactory не вызывается при init', () async {
      final tf = ControlledTimerFactory();
      final app = AppController(
        subscription: SubscriptionService(fetcher: (_) async => FetchResult(fakeSub, const {})),
        builder: const ConfigBuilder(),
        proxyTunnel: FakeTunnel(),
        tunTunnel: FakeTunnel(),
        repo: InMemoryStateRepository(),
        platform: FakePlatformInfo(),
        timerFactory: tf.call,
      );
      await app.init();
      expect(tf.callCount, 0);
      app.dispose();
    });

    test('enabled — timerFactory вызывается с правильным интервалом при init', () async {
      final tf = ControlledTimerFactory();
      final repo = InMemoryStateRepository();
      await repo.save(PersistedState(
        profiles: [],
        activeProfileId: null,
        settings: const AppSettings(autoRefreshEnabled: true, autoRefreshIntervalMinutes: 120),
      ));
      final app = AppController(
        subscription: SubscriptionService(fetcher: (_) async => FetchResult(fakeSub, const {})),
        builder: const ConfigBuilder(),
        proxyTunnel: FakeTunnel(),
        tunTunnel: FakeTunnel(),
        repo: repo,
        platform: FakePlatformInfo(),
        timerFactory: tf.call,
      );
      await app.init();
      expect(tf.callCount, 1);
      expect(tf.capturedDuration, const Duration(minutes: 120));
      app.dispose();
    });

    test('updateSettings с новым интервалом пересоздаёт таймер', () async {
      final tf = ControlledTimerFactory();
      final repo = InMemoryStateRepository();
      await repo.save(PersistedState(
        profiles: [],
        activeProfileId: null,
        settings: const AppSettings(autoRefreshEnabled: true, autoRefreshIntervalMinutes: 60),
      ));
      final app = AppController(
        subscription: SubscriptionService(fetcher: (_) async => FetchResult(fakeSub, const {})),
        builder: const ConfigBuilder(),
        proxyTunnel: FakeTunnel(),
        tunTunnel: FakeTunnel(),
        repo: repo,
        platform: FakePlatformInfo(),
        timerFactory: tf.call,
      );
      await app.init();
      expect(tf.callCount, 1);
      await app.updateSettings(app.settings.copyWith(autoRefreshIntervalMinutes: 30));
      expect(tf.callCount, 2);
      expect(tf.capturedDuration, const Duration(minutes: 30));
      app.dispose();
    });

    test('updateSettings отключает → таймер отменяется', () async {
      final tf = ControlledTimerFactory();
      final repo = InMemoryStateRepository();
      await repo.save(PersistedState(
        profiles: [],
        activeProfileId: null,
        settings: const AppSettings(autoRefreshEnabled: true, autoRefreshIntervalMinutes: 60),
      ));
      final app = AppController(
        subscription: SubscriptionService(fetcher: (_) async => FetchResult(fakeSub, const {})),
        builder: const ConfigBuilder(),
        proxyTunnel: FakeTunnel(),
        tunTunnel: FakeTunnel(),
        repo: repo,
        platform: FakePlatformInfo(),
        timerFactory: tf.call,
      );
      await app.init();
      final timer = tf._timer!;
      await app.updateSettings(app.settings.copyWith(autoRefreshEnabled: false));
      expect(timer.cancelled, true);
      app.dispose();
    });

    test('тик таймера вызывает refreshAllProfiles', () async {
      final tf = ControlledTimerFactory();
      final repo = InMemoryStateRepository();
      await repo.save(PersistedState(
        profiles: [],
        activeProfileId: null,
        settings: const AppSettings(autoRefreshEnabled: true, autoRefreshIntervalMinutes: 60),
      ));
      final app = AppController(
        subscription: SubscriptionService(fetcher: (_) async => FetchResult(fakeSub, const {})),
        builder: const ConfigBuilder(),
        proxyTunnel: FakeTunnel(),
        tunTunnel: FakeTunnel(),
        repo: repo,
        platform: FakePlatformInfo(),
        timerFactory: tf.call,
      );
      await app.init();
      await app.addProfile('Sub', 'https://x');
      tf.fire();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(app.profiles.first.lastRefreshedAt, isNotNull);
      app.dispose();
    });

    test('refreshAllProfiles — успех проставляет lastRefreshedAt', () async {
      final app = build();
      await app.init();
      await app.addProfile('Sub', 'https://x');
      await app.refreshAllProfiles();
      expect(app.profiles.first.lastRefreshedAt, isNotNull);
    });

    test('refreshAllProfiles — ошибка одного профиля → refreshError содержит имя', () async {
      int fetchCount = 0;
      final app = AppController(
        subscription: SubscriptionService(fetcher: (_) async {
          fetchCount++;
          if (fetchCount > 1) throw Exception('network error');
          return FetchResult(fakeSub, const {});
        }),
        builder: const ConfigBuilder(),
        proxyTunnel: FakeTunnel(),
        tunTunnel: FakeTunnel(),
        repo: InMemoryStateRepository(),
        platform: FakePlatformInfo(),
      );
      await app.init();
      await app.addProfile('MySub', 'https://x');
      await app.refreshAllProfiles();
      expect(app.refreshError, contains('MySub'));
    });

    test('clearRefreshError сбрасывает ошибку', () async {
      int fetchCount = 0;
      final app = AppController(
        subscription: SubscriptionService(fetcher: (_) async {
          fetchCount++;
          if (fetchCount > 1) throw Exception('fail');
          return FetchResult(fakeSub, const {});
        }),
        builder: const ConfigBuilder(),
        proxyTunnel: FakeTunnel(),
        tunTunnel: FakeTunnel(),
        repo: InMemoryStateRepository(),
        platform: FakePlatformInfo(),
      );
      await app.init();
      await app.addProfile('Sub', 'https://x');
      await app.refreshAllProfiles();
      expect(app.refreshError, isNotNull);
      app.clearRefreshError();
      expect(app.refreshError, isNull);
    });

    test('isRefreshingAll true во время, false после', () async {
      final repo2 = InMemoryStateRepository();
      final seed = build();
      await seed.init();
      await seed.addProfile('S', 'https://x');
      await repo2.save(PersistedState(
        profiles: seed.profiles,
        activeProfileId: seed.profiles.first.id,
        settings: const AppSettings(),
      ));
      final app2 = AppController(
        subscription: SubscriptionService(fetcher: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return FetchResult(fakeSub, const {});
        }),
        builder: const ConfigBuilder(),
        proxyTunnel: FakeTunnel(),
        tunTunnel: FakeTunnel(),
        repo: repo2,
        platform: FakePlatformInfo(),
      );
      await app2.init();
      expect(app2.isRefreshingAll, false);
      final future = app2.refreshAllProfiles();
      expect(app2.isRefreshingAll, true);
      await future;
      expect(app2.isRefreshingAll, false);
    });
  });

  group('routing profiles', () {
    test('init сидит пресеты роутинга и ставит активным all-proxy', () async {
      final c = build();
      await c.init();
      expect(c.routingProfiles.map((p) => p.id),
          containsAll(['preset-all-proxy', 'preset-bypass-ru', 'preset-block-ads']));
      expect(c.activeRoutingProfileId, 'preset-all-proxy');
    });

    test('init не пересоздаёт пресеты если уже есть', () async {
      final repo = InMemoryStateRepository();
      final c = build(repo: repo);
      await c.init();
      final firstCount = c.routingProfiles.length;
      final c2 = build(repo: repo);
      await c2.init();
      expect(c2.routingProfiles.length, firstCount);
    });

    test('selectRoutingProfile меняет активный', () async {
      final c = build();
      await c.init();
      await c.selectRoutingProfile('preset-bypass-ru');
      expect(c.activeRoutingProfileId, 'preset-bypass-ru');
    });

    test('cloneRoutingProfile создаёт редактируемую копию пресета', () async {
      final c = build();
      await c.init();
      final clone = await c.cloneRoutingProfile('preset-bypass-ru');
      expect(clone.isBuiltIn, isFalse);
      expect(clone.id, isNot('preset-bypass-ru'));
      expect(clone.directRules.isNotEmpty, isTrue);
      expect(c.routingProfiles.any((p) => p.id == clone.id), isTrue);
    });

    test('updateRoutingProfile игнорирует встроенные', () async {
      final c = build();
      await c.init();
      final preset = c.routingProfiles.firstWhere((p) => p.id == 'preset-all-proxy');
      await c.updateRoutingProfile(preset.copyWith(name: 'Взлом'));
      expect(c.routingProfiles.firstWhere((p) => p.id == 'preset-all-proxy').name,
          'Всё через прокси');
    });

    test('removeRoutingProfile активного переключает на all-proxy', () async {
      final c = build();
      await c.init();
      final clone = await c.cloneRoutingProfile('preset-bypass-ru');
      await c.selectRoutingProfile(clone.id);
      await c.removeRoutingProfile(clone.id);
      expect(c.routingProfiles.any((p) => p.id == clone.id), isFalse);
      expect(c.activeRoutingProfileId, 'preset-all-proxy');
    });
  });

  test('addProfile сохраняет subscriptionInfo из заголовков', () async {
    final sub = SubscriptionService(
      fetcher: (_) async => FetchResult(
        fakeSub,
        const {'subscription-userinfo': 'download=5; total=100; expire=0'},
      ),
    );
    final app = build(sub: sub);
    await app.init();
    await app.addProfile('Sub', 'https://x');
    expect(app.profiles.first.subscriptionInfo?.total, 100);
  });

  test('pingProfile заполняет результаты для всех нод профиля', () async {
    final app = build(pingService: _FakePing((node) => const PingResult.ok(42)));
    await app.init();
    await app.addProfile('Sub', 'https://x'); // fakeSub → 2 ноды h, h2
    final pid = app.profiles.first.id;
    await app.pingProfile(pid);
    final nodes = app.profiles.first.nodes;
    expect(app.pingFor(nodes[0])?.latencyMs, 42);
    expect(app.pingFor(nodes[1])?.latencyMs, 42);
  });

  group('auto-reconnect', () {
    test('selectNode во время connected → disconnect + reconnect', () async {
      final app = build();
      await app.init();
      await app.addProfile('Sub', 'https://x');
      final id = app.profiles.first.id;
      await app.selectNode(id, 0);
      await app.connect();
      expect(app.status, TunnelStatus.connected);
      final startCountBefore = proxyTunnel.startCallCount;

      // смена ноды → должен переподключиться
      await app.selectNode(id, 1);

      expect(app.status, TunnelStatus.connected);
      expect(proxyTunnel.startCallCount, greaterThan(startCountBefore));
      expect(app.selectedNode!.name, 'B');
    });

    test('selectNode во время disconnected → без реконнекта', () async {
      final app = build();
      await app.init();
      await app.addProfile('Sub', 'https://x');
      final id = app.profiles.first.id;
      await app.selectNode(id, 0);
      expect(app.status, TunnelStatus.disconnected);

      final startCountBefore = proxyTunnel.startCallCount;
      await app.selectNode(id, 1);

      expect(app.status, TunnelStatus.disconnected);
      expect(proxyTunnel.startCallCount, equals(startCountBefore));
    });

    test('removeProfile активного профиля во время connected → disconnect', () async {
      final app = build();
      await app.init();
      await app.addProfile('Sub', 'https://x');
      final id = app.profiles.first.id;
      await app.selectNode(id, 0);
      await app.connect();
      expect(app.status, TunnelStatus.connected);

      await app.removeProfile(id);

      expect(app.status, TunnelStatus.disconnected);
      expect(app.profiles, isEmpty);
    });

    test('removeProfile неактивного профиля во время connected → без disconnect', () async {
      final app = build();
      await app.init();
      await app.addProfile('Active', 'https://x');
      await app.addProfile('Other', 'https://x');
      final activeId = app.profiles.first.id;
      final otherId = app.profiles.last.id;
      await app.selectNode(activeId, 0);
      await app.connect();
      expect(app.status, TunnelStatus.connected);

      await app.removeProfile(otherId);

      expect(app.status, TunnelStatus.connected);
      expect(app.profiles, hasLength(1));
    });
  });

  group('log buffer', () {
    test('accumulates log lines from active tunnel and clears', () async {
      final app = build();
      proxyTunnel.emitLog('line 1');
      proxyTunnel.emitLog('line 2');
      await Future<void>.delayed(Duration.zero);
      expect(app.logs.map((e) => e.message), ['line 1', 'line 2']);

      app.clearLogs();
      expect(app.logs, isEmpty);
    });

    test('caps log buffer at 500 lines', () async {
      final app = build();
      for (var i = 0; i < 600; i++) {
        proxyTunnel.emitLog('l$i');
      }
      await Future<void>.delayed(Duration.zero);
      expect(app.logs.length, 500);
      expect(app.logs.first.message, 'l100');
      expect(app.logs.last.message, 'l599');
    });
  });

  group('requestTunMode', () {
    test('enabled -> switches to tun', () async {
      final helper = FakeHelper(['enabled']);
      final app = build(helper: helper);
      final r = await app.requestTunMode();
      expect(r, TunModeResult.enabled);
      expect(app.settings.tunnelMode, TunnelMode.tun);
    });

    test('notRegistered -> denied, mode stays proxy, alert fired', () async {
      final helper = FakeHelper(['notRegistered']);
      final app = build(helper: helper);
      final alerts = <String>[];
      final sub = app.alerts.listen(alerts.add);
      final r = await app.requestTunMode();
      await Future<void>.delayed(Duration.zero);
      expect(r, TunModeResult.denied);
      expect(app.settings.tunnelMode, TunnelMode.systemProxy);
      expect(alerts.single, contains('не установлен'));
      await sub.cancel();
    });
  });

  group('update', () {
    test('checkForUpdate заполняет availableUpdate', () async {
      final svc = FakeUpdateService(
          info: const UpdateInfo(
              version: 'v1.0.1', pkgUrl: 'https://gh/x.pkg', releaseUrl: 'r'));
      final app = build(updateService: svc);
      await app.checkForUpdate();
      expect(app.availableUpdate?.version, 'v1.0.1');
      expect(app.isCheckingUpdate, isFalse);
    });

    test('ошибка проверки → alert, availableUpdate=null', () async {
      final svc = FakeUpdateService(checkError: Exception('net'));
      final app = build(updateService: svc);
      final alerts = <String>[];
      final sub = app.alerts.listen(alerts.add);
      await app.checkForUpdate();
      await Future<void>.delayed(Duration.zero);
      expect(app.availableUpdate, isNull);
      expect(alerts, isNotEmpty);
      await sub.cancel();
    });

    test('downloadAndInstallUpdate открывает скачанный .pkg', () async {
      final platform = FakePlatformInfo();
      final svc = FakeUpdateService(
          info: const UpdateInfo(
              version: 'v1.0.1', pkgUrl: 'https://gh/x.pkg', releaseUrl: 'r'));
      final app = build(updateService: svc, platform: platform);
      await app.checkForUpdate();
      await app.downloadAndInstallUpdate();
      expect(svc.downloadedFrom, 'https://gh/x.pkg');
      expect(platform.openedPath, '/tmp/SingboxFlutter-update.pkg');
    });

    test('перед запуском установщика туннель гасится', () async {
      final platform = FakePlatformInfo();
      final svc = FakeUpdateService(
          info: const UpdateInfo(
              version: 'v1.0.1', pkgUrl: 'https://gh/x.pkg', releaseUrl: 'r'));
      final app = build(updateService: svc, platform: platform);
      platform.observed = app;
      await app.init();
      await app.addProfile('Sub', 'https://x');
      await app.selectNode(app.profiles.first.id, 0);
      await app.checkForUpdate();
      await app.connect();
      expect(app.status, TunnelStatus.connected);
      await app.downloadAndInstallUpdate();
      expect(platform.openedPath, isNotNull);
      expect(platform.tunnelActiveOnInstall, isFalse);
      expect(app.status, TunnelStatus.disconnected);
    });
  });

  test('clash-клиент стартует при подключении и останавливается при отключении',
      () async {
    final sockets = <String>[];
    final client = ClashApiClient(
      open: (url) async {
        sockets.add(url);
        throw const SocketException('нет сервера');
      },
      retryStep: const Duration(seconds: 30),
    );
    final app = build(clashApi: client);
    await app.init();
    await app.addProfile('Sub', 'https://x');
    await app.selectNode(app.profiles.first.id, 0);
    await app.connect();
    expect(client.isRunning, isTrue);
    await app.disconnect();
    expect(client.isRunning, isFalse);
  });
}
