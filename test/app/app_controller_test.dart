import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/app/app_controller.dart';
import 'package:singbox_client/models/auto_select_settings.dart';
import 'package:singbox_client/models/node_engine.dart';
import 'package:singbox_client/models/profile.dart';
import 'package:singbox_client/services/node_tester.dart';
import 'package:singbox_client/tunnel/xray_process.dart';
import 'package:singbox_client/services/update_service.dart';
import 'package:singbox_client/models/app_settings.dart';
import 'package:singbox_client/models/persisted_state.dart';
import 'package:singbox_client/models/subscription_meta.dart';
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
  /// Хук для проверки порядка остановки sing-box и Xray.
  void Function()? onStop;
  @override
  Future<void> stop() async {
    stopCallCount++;
    onStop?.call();
    emit(TunnelStatus.disconnected);
  }
}

class FakeXray implements XrayProcess {
  FakeXray({this.failStart = false, this.onStop});
  final bool failStart;
  final void Function()? onStop;
  int startCalls = 0;
  int stopCalls = 0;
  final _logs = StreamController<String>.broadcast();

  @override
  Stream<String> get logs => _logs.stream;

  @override
  Future<void> start(Map<String, dynamic> config) async {
    startCalls++;
    if (failStart) {
      throw PlatformException(code: 'START', message: 'не поднялся');
    }
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    onStop?.call();
  }

  @override
  void dispose() => _logs.close();
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
  Future<String> xrayVersion() async => '26.3.27';

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

/// FakeTimer с доступом к колбэку: health-check запускаем вручную.
class _RecordedTimer extends FakeTimer {
  _RecordedTimer(this.callback, this.onCancel);
  final void Function(Timer) callback;
  final void Function(_RecordedTimer) onCancel;
  @override
  void cancel() {
    super.cancel();
    onCancel(this);
  }
  void fire() {
    if (!cancelled) callback(this);
  }
}

/// Записывает, какие URL запрашивались, и умеет подвиснуть на [hold] —
/// так проверяется защита от параллельных обновлений одного профиля.
class RecordingSubscriptionService implements SubscriptionService {
  RecordingSubscriptionService({this.hold});
  final Future<void>? hold;
  final loadedUrls = <String>[];

  @override
  Future<LoadResult> loadWithInfo(String url) async {
    loadedUrls.add(url);
    if (hold != null) await hold;
    return const LoadResult([], null, null);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ControlledTimerFactory {
  FakeTimer? _timer;
  void Function(Timer)? _callback;
  Duration? capturedDuration;
  // Все запрошенные интервалы: _timerFactory используется и автообновлением
  // профилей, и health-check, и пингом gstatic — по одному последнему вызову
  // их не различить.
  final durations = <Duration>[];
  int callCount = 0;

  Timer call(Duration duration, void Function(Timer) callback) {
    callCount++;
    capturedDuration = duration;
    durations.add(duration);
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
  Future<PingResult> ping(NodeConfig node,
          {Duration timeout = const Duration(seconds: 3),
          bool bypassTunnel = false}) async =>
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
  NodeTester? nodeTester,
  Timer Function(Duration, void Function(Timer))? timerFactory,
  Future<int?> Function(String url, int? port, {Duration timeout})?
      gstaticProbe,
  Future<int?> Function(String host, int port, {Duration timeout})?
      bypassProbe,
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
      nodeTester: nodeTester,
      timerFactory: timerFactory,
      // По умолчанию — заглушка, чтобы тесты не ходили в реальную сеть.
      gstaticProbe: gstaticProbe ??
          (url, port, {timeout = const Duration(seconds: 3)}) async => null,
      // То же и для замера мимо туннеля: нативного канала в тестах нет.
      bypassProbe: bypassProbe ??
          (host, port, {timeout = const Duration(seconds: 3)}) async => null,
    );

/// Контроллер с профилем из fakeSub (две ноды A/h и B/h2) и подставным
/// NodeTester: `best` — индекс ноды, проходящей HTTP-пробу, `tcpBest` —
/// индекс ноды с лучшим TCP; null означает «все провалились».
/// `checkResults` — очередь ответов пробы (для health-check из Task 6).
Future<AppController> _controllerWithProfile({
  int? best,
  int? tcpBest,
  List<bool> checkResults = const [],
  Timer Function(Duration, void Function(Timer))? timerFactory,
}) async {
  var nextPort = 9000;
  var probeCalls = 0;
  // Нода с HTTP-ответом по определению жива и по TCP, иначе до HTTP-фазы
  // она просто не дойдёт.
  final tcpAlive = tcpBest ?? best;
  // Порты в HTTP-фазе выдаются не в порядке профиля, а по возрастанию
  // TCP-задержки: сначала лучшая по TCP нода.
  final portOrder =
      tcpAlive == null ? const <int>[] : (tcpAlive == 0 ? [0, 1] : [1, 0]);
  final tester = NodeTester(
    ping: _FakePing((node) {
      if (tcpAlive == null) return const PingResult.timeout();
      final i = node.name == 'A' ? 0 : 1;
      return PingResult.ok(tcpAlive == i ? 1 : 100);
    }),
    startSingbox: (_) async {},
    stopSingbox: () async {},
    startXray: (_) async {},
    stopXray: () async {},
    pickPort: () async => nextPort++,
    probe: (url, port, timeout) async {
      final call = probeCalls++;
      // Сначала расходуем очередь health-check, иначе отвечаем по best.
      if (call < checkResults.length) {
        return checkResults[call] ? 10 : null;
      }
      return best == portOrder[(port - 9000) % portOrder.length] ? 10 : null;
    },
  );
  final c = build(nodeTester: tester, timerFactory: timerFactory);
  await c.init();
  await c.addProfile('Sub', 'https://x');
  return c;
}

// --- health-check: записанные таймеры и их ручной запуск ---
final _activeTimers = <_RecordedTimer>[];

Timer _recordTimer(Duration d, void Function(Timer) cb) {
  final t = _RecordedTimer(cb, _activeTimers.remove);
  _activeTimers.add(t);
  return t;
}

void _fireTimer() => _activeTimers.last.fire();

/// Отмечает активный профиль в автовыборе: пул кандидатов пуст по умолчанию.
Future<void> _markActive(AppController c) => c.updateAutoSelectSettings(
    AutoSelectSettings(enabled: true, profileIds: {c.activeProfileId!}));

/// Контроллер с профилем, подключённый, с включённым автовыбором на нём.
Future<AppController> _controllerWithHealthCheck({
  required List<bool> checkResults,
  int? best,
}) async {
  final c = await _controllerWithProfile(
    best: best,
    checkResults: checkResults,
    timerFactory: _recordTimer,
  );
  // Пинг gstatic выключаем заранее: его таймер регистрировался бы после
  // health-check в _activeTimers и _fireTimer() бил бы не по тому тику.
  await c.updateSettings(c.settings.copyWith(gstaticPingEnabled: false));
  await c.connect();
  // Отбрасываем таймер автообновления профилей: дальше интересует только
  // таймер health-check.
  _activeTimers.clear();
  // Включаем после connect: иначе хук подключения съест очередь checkResults,
  // предназначенную фоновым тикам.
  await c.updateAutoSelectSettings(
      AutoSelectSettings(enabled: true, profileIds: {c.activeProfileId!}));
  return c;
}

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

  group('refreshAllProfiles', () {
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

  group('auto-refresh per profile', () {
    test('на тике обновляется только просроченный профиль', () async {
      void Function(Timer)? tick;
      final repo = InMemoryStateRepository();
      await repo.save(PersistedState(profiles: [
        Profile(
          id: 'stale', name: 'Stale', url: 'https://example.com/a',
          nodes: const [], selectedNodeIndex: null,
          refreshIntervalMinutesOverride: 60,
          lastRefreshedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Profile(
          id: 'fresh', name: 'Fresh', url: 'https://example.com/b',
          nodes: const [], selectedNodeIndex: null,
          refreshIntervalMinutesOverride: 60,
          lastRefreshedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        Profile(
          id: 'off', name: 'Off', url: 'https://example.com/c',
          nodes: const [], selectedNodeIndex: null,
        ),
      ]));
      final sub = RecordingSubscriptionService();
      final c = build(
        repo: repo,
        sub: sub,
        timerFactory: (d, cb) {
          expect(d, const Duration(minutes: 1));
          tick = cb;
          return Timer(const Duration(days: 1), () {});
        },
      );
      await c.init();

      tick!(FakeTimer());
      await pumpEventQueue();

      expect(sub.loadedUrls, ['https://example.com/a']);
    });

    test('профиль с идущим обновлением не запускается повторно', () async {
      void Function(Timer)? tick;
      final gate = Completer<void>();
      final sub = RecordingSubscriptionService(hold: gate.future);
      final repo = InMemoryStateRepository();
      await repo.save(PersistedState(profiles: [
        Profile(
          id: 'stale', name: 'Stale', url: 'https://example.com/a',
          nodes: const [], selectedNodeIndex: null,
          refreshIntervalMinutesOverride: 60,
          lastRefreshedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ]));
      final c = build(
        repo: repo, sub: sub,
        timerFactory: (d, cb) { tick = cb; return Timer(const Duration(days: 1), () {}); },
      );
      await c.init();

      tick!(FakeTimer());
      await pumpEventQueue();
      tick!(FakeTimer());
      await pumpEventQueue();
      gate.complete();
      await pumpEventQueue();

      expect(sub.loadedUrls.length, 1);
    });

    test('профиль без интервала не обновляется никогда', () async {
      void Function(Timer)? tick;
      final sub = RecordingSubscriptionService();
      final repo = InMemoryStateRepository();
      await repo.save(PersistedState(profiles: [
        Profile(
          id: 'off', name: 'Off', url: 'https://example.com/c',
          nodes: const [], selectedNodeIndex: null,
          lastRefreshedAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      ]));
      final c = build(
        repo: repo, sub: sub,
        timerFactory: (d, cb) { tick = cb; return Timer(const Duration(days: 1), () {}); },
      );
      await c.init();

      tick!(FakeTimer());
      await pumpEventQueue();

      expect(sub.loadedUrls, isEmpty);
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

  test('profile-title становится именем профиля при добавлении', () async {
    final app = build(
      sub: SubscriptionService(
        fetcher: (_) async =>
            FetchResult(fakeSub, const {'profile-title': 'Мой VPN'}),
      ),
    );
    await app.addProfile('sub.example.com', 'https://example.com/sub');
    expect(app.profiles.single.name, 'Мой VPN');
    expect(app.profiles.single.nameIsCustom, false);
    expect(app.profiles.single.subscriptionMeta?.title, 'Мой VPN');
  });

  test('без profile-title остаётся имя, выведенное из ссылки', () async {
    final app = build(
      sub: SubscriptionService(
        fetcher: (_) async => FetchResult(fakeSub, const {}),
      ),
    );
    await app.addProfile('sub.example.com', 'https://example.com/sub');
    expect(app.profiles.single.name, 'sub.example.com');
  });

  test('refresh обновляет автоматическое имя', () async {
    var title = 'Старое';
    final app = build(
      sub: SubscriptionService(
        fetcher: (_) async => FetchResult(fakeSub, {'profile-title': title}),
      ),
    );
    await app.addProfile('fallback', 'https://example.com/sub');
    title = 'Новое';
    await app.refreshProfile(app.profiles.single.id);
    expect(app.profiles.single.name, 'Новое');
  });

  test('refresh не трогает имя, заданное вручную', () async {
    final app = build(
      sub: SubscriptionService(
        fetcher: (_) async =>
            FetchResult(fakeSub, const {'profile-title': 'От провайдера'}),
      ),
    );
    await app.addProfile('fallback', 'https://example.com/sub');
    final id = app.profiles.single.id;
    await app.renameProfile(id, 'Как я хочу');
    expect(app.profiles.single.nameIsCustom, true);
    await app.refreshProfile(id);
    expect(app.profiles.single.name, 'Как я хочу');
  });

  test('мета обновляется при refresh даже когда имя ручное', () async {
    var announce = 'A1';
    final app = build(
      sub: SubscriptionService(
        fetcher: (_) async => FetchResult(fakeSub, {'announce': announce}),
      ),
    );
    await app.addProfile('fallback', 'https://example.com/sub');
    final id = app.profiles.single.id;
    await app.renameProfile(id, 'Своё');
    announce = 'A2';
    await app.refreshProfile(id);
    expect(app.profiles.single.subscriptionMeta?.announce, 'A2');
  });

  test('updateNode заменяет ноду и не сбрасывает выбор', () async {
    final app = build();
    await app.addProfile('P', 'https://example.com/sub');
    final p = app.profiles.single;
    await app.selectNode(p.id, 1);

    final old = p.nodes[0];
    final edited = NodeConfig(
      name: 'Переименованная', protocol: old.protocol, host: old.host,
      port: old.port, params: old.params,
      rawSchema: old.rawSchema, rawOutbound: old.rawOutbound,
    );
    await app.updateNode(p.id, 0, edited);

    expect(app.profiles.single.nodes[0].name, 'Переименованная');
    expect(app.profiles.single.nodes.length, p.nodes.length);
    expect(app.profiles.single.selectedNodeIndex, 1);
  });

  test('updateNode с индексом вне диапазона ничего не делает', () async {
    final app = build();
    await app.addProfile('P', 'https://example.com/sub');
    final p = app.profiles.single;
    await app.updateNode(p.id, 99, p.nodes[0]);
    expect(app.profiles.single.nodes.length, p.nodes.length);
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

    test('проверка обновлений не идёт сразу после предыдущей', () async {
      final svc = FakeUpdateService();
      final repo = InMemoryStateRepository(PersistedState(
        settings: const AppSettings().copyWith(
          lastUpdateCheckAt:
              DateTime.now().subtract(const Duration(minutes: 10)),
        ),
      ));
      final app = build(repo: repo, updateService: svc);
      await app.init();
      await Future<void>.delayed(Duration.zero);
      expect(svc.checkCalls, 0);
    });

    test('проверка обновлений идёт, когда период истёк', () async {
      final svc = FakeUpdateService();
      final repo = InMemoryStateRepository(PersistedState(
        settings: const AppSettings().copyWith(
          lastUpdateCheckAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ));
      final app = build(repo: repo, updateService: svc);
      await app.init();
      await Future<void>.delayed(Duration.zero);
      expect(svc.checkCalls, 1);
    });

    test('ошибка тихой проверки не всплывает и НЕ пишет отметку времени',
        () async {
      final svc = FakeUpdateService(checkError: Exception('net'));
      final repo = InMemoryStateRepository();
      final app = build(repo: repo, updateService: svc);
      final alerts = <String>[];
      final sub = app.alerts.listen(alerts.add);
      await app.init();
      await Future<void>.delayed(Duration.zero);

      expect(app.availableUpdate, isNull);
      expect(alerts, isEmpty);
      // Иначе неудача из-за отсутствия сети заткнула бы проверку на весь
      // период, и следующий запуск снова «не проверял бы».
      expect(app.settings.lastUpdateCheckAt, isNull);
      await sub.cancel();
    });

    test(
        'пропущенная версия не предлагается, а более новая предлагается',
        () async {
      final svc = FakeUpdateService(
          info: const UpdateInfo(
              version: 'v1.2.3', pkgUrl: 'https://e/x.pkg', releaseUrl: 'https://e'));
      final repo = InMemoryStateRepository(PersistedState(
        settings: const AppSettings().copyWith(skippedVersion: 'v1.2.3'),
      ));
      final app = build(repo: repo, updateService: svc);
      await app.init();
      await Future<void>.delayed(Duration.zero);
      expect(app.updateToOffer, isNull);

      // Пропущена другая версия — текущая снова предлагается.
      await app.updateSettings(app.settings.copyWith(skippedVersion: 'v1.0.0'));
      expect(app.updateToOffer?.version, 'v1.2.3');
    });

    test('dismissUpdateBanner скрывает предложение до перезапуска', () async {
      final svc = FakeUpdateService(
          info: const UpdateInfo(
              version: 'v9.9.9', pkgUrl: 'https://e/x.pkg', releaseUrl: 'https://e'));
      final app = build(updateService: svc);
      await app.init();
      await Future<void>.delayed(Duration.zero);
      expect(app.updateToOffer, isNotNull);

      app.dismissUpdateBanner();
      expect(app.updateToOffer, isNull);
      // availableUpdate остаётся — бейдж в сайдбаре строится по нему.
      expect(app.availableUpdate, isNotNull);
    });

    test('skipUpdateVersion записывает версию в настройки', () async {
      final svc = FakeUpdateService(
          info: const UpdateInfo(
              version: 'v9.9.9', pkgUrl: 'https://e/x.pkg', releaseUrl: 'https://e'));
      final app = build(updateService: svc);
      await app.init();
      await Future<void>.delayed(Duration.zero);

      await app.skipUpdateVersion();
      expect(app.settings.skippedVersion, 'v9.9.9');
      expect(app.updateToOffer, isNull);
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

  group('движки', () {
    // hysteria2 — зона Xray, naive/vless без xhttp — зона sing-box.
    const hySub = 'hysteria2://AUTH@h.example:443#HY';

    AppController buildWithXray({
      required FakeXray xray,
      bool probeOk = true,
      String sub = hySub,
      StateRepository? repo,
    }) =>
        AppController(
          subscription:
              SubscriptionService(fetcher: (_) async => FetchResult(sub, const {})),
          builder: const ConfigBuilder(),
          proxyTunnel: proxyTunnel,
          tunTunnel: tunTunnel,
          repo: repo ?? InMemoryStateRepository(),
          platform: FakePlatformInfo(),
          resolveHost: (_) async => '9.9.9.9',
          xrayFactory: () => xray,
          pickPort: () async => 11080,
          probeSocks: (_) async => probeOk,
        );

    test('hysteria2 идёт через Xray: socks-outbound на его порт', () async {
      final xray = FakeXray();
      final app = buildWithXray(xray: xray);
      await app.init();
      await app.addProfile('Sub', 'https://x');
      await app.selectNode(app.profiles.first.id, 0);
      await app.connect();

      expect(app.activeEngine, NodeEngine.xray);
      expect(xray.startCalls, 1);
      final out = proxyTunnel.lastConfig!['outbounds'][0];
      expect(out['type'], 'socks');
      expect(out['server_port'], 11080);
    });

    test('auto: неудачный старт Xray откатывается на sing-box', () async {
      final xray = FakeXray(failStart: true);
      final app = buildWithXray(xray: xray);
      await app.init();
      await app.addProfile('Sub', 'https://x');
      await app.selectNode(app.profiles.first.id, 0);
      await app.connect();

      expect(app.activeEngine, NodeEngine.singbox);
      expect(app.status, TunnelStatus.connected);
      expect(proxyTunnel.lastConfig!['outbounds'][0]['type'], 'hysteria2');
    });

    test('auto: мёртвый socks-порт тоже откатывается', () async {
      final xray = FakeXray();
      final app = buildWithXray(xray: xray, probeOk: false);
      await app.init();
      await app.addProfile('Sub', 'https://x');
      await app.selectNode(app.profiles.first.id, 0);
      await app.connect();

      expect(app.activeEngine, NodeEngine.singbox);
      // Не оставляем висеть процесс, который не отвечает.
      expect(xray.stopCalls, greaterThan(0));
    });

    test('ручной выбор Xray: неудача — это ошибка, а не откат', () async {
      final xray = FakeXray(failStart: true);
      final app = buildWithXray(xray: xray);
      await app.init();
      await app.addProfile('Sub', 'https://x');
      final profileId = app.profiles.first.id;
      await app.selectNode(profileId, 0);
      await app.setNodeEngineChoice(
          profileId, app.selectedNode!, EngineChoice.xray);
      await app.connect();

      expect(app.status, TunnelStatus.error);
      expect(proxyTunnel.startCallCount, 0);
    });

    test('ручной sing-box поверх hysteria2: Xray не запускается вовсе', () async {
      final xray = FakeXray();
      final app = buildWithXray(xray: xray);
      await app.init();
      await app.addProfile('Sub', 'https://x');
      final profileId = app.profiles.first.id;
      await app.selectNode(profileId, 0);
      await app.setNodeEngineChoice(
          profileId, app.selectedNode!, EngineChoice.singbox);
      await app.connect();

      expect(app.activeEngine, NodeEngine.singbox);
      expect(xray.startCalls, 0);
      expect(proxyTunnel.lastConfig!['outbounds'][0]['type'], 'hysteria2');
    });

    test('disconnect гасит sing-box раньше Xray', () async {
      final order = <String>[];
      final xray = FakeXray(onStop: () => order.add('xray'));
      proxyTunnel.onStop = () => order.add('singbox');
      final app = buildWithXray(xray: xray);
      await app.init();
      await app.addProfile('Sub', 'https://x');
      await app.selectNode(app.profiles.first.id, 0);
      await app.connect();
      await app.disconnect();

      expect(order, ['singbox', 'xray']);
      expect(app.activeEngine, isNull);
    });

    test('vless без xhttp остаётся на sing-box', () async {
      final xray = FakeXray();
      final app = buildWithXray(xray: xray, sub: fakeSub);
      await app.init();
      await app.addProfile('Sub', 'https://x');
      await app.selectNode(app.profiles.first.id, 0);
      await app.connect();

      expect(app.activeEngine, NodeEngine.singbox);
      expect(xray.startCalls, 0);
    });
  });

  group('автовыбор ноды', () {
    test('autoSelectBest выбирает ноду с лучшей HTTP-задержкой', () async {
      // Профиль с двумя нодами; тестер отдаёт вторую как лучшую.
      final c = await _controllerWithProfile(best: 1);
      await _markActive(c);
      await c.autoSelectBest();
      expect(c.profiles.first.selectedNodeIndex, 1);
    });

    test('при нуле успешных HTTP берётся лучшая по TCP', () async {
      final c = await _controllerWithProfile(best: null, tcpBest: 1);
      await _markActive(c);
      await c.autoSelectBest();
      expect(c.profiles.first.selectedNodeIndex, 1);
    });

    test('когда все ноды мертвы, выбор не меняется', () async {
      final c = await _controllerWithProfile(best: null, tcpBest: null);
      await _markActive(c);
      final before = c.profiles.first.selectedNodeIndex;
      await c.autoSelectBest();
      expect(c.profiles.first.selectedNodeIndex, before);
    });

    test('неотмеченный профиль в переборе не участвует', () async {
      final c = await _controllerWithProfile(best: 1);
      await c.updateAutoSelectSettings(
          const AutoSelectSettings(enabled: true, profileIds: {}));
      await c.autoSelectBest();
      expect(c.profiles.first.selectedNodeIndex, 0);
    });

    test('лучшая нода в другом профиле делает его активным', () async {
      // Два профиля: в первом ноды мертвы по TCP, во втором живы. Победитель
      // из второго профиля должен и профиль сделать активным.
      final c = build(
        sub: SubscriptionService(
          fetcher: (url) async => FetchResult(
              url.endsWith('/2')
                  ? 'vless://uid@alive:443#C'
                  : 'vless://uid@dead:443#A',
              const {}),
        ),
        nodeTester: NodeTester(
          ping: _FakePing((node) => node.host == 'alive'
              ? PingResult.ok(10)
              : const PingResult.timeout()),
          startSingbox: (_) async {},
          stopSingbox: () async {},
          startXray: (_) async {},
          stopXray: () async {},
          pickPort: () async => 9000,
          probe: (url, port, timeout) async => 5,
        ),
      );
      await c.init();
      await c.addProfile('First', 'https://x/1');
      await c.addProfile('Second', 'https://x/2');
      final first = c.profiles.first.id;
      final second = c.profiles.last.id;
      await c.selectNode(first, 0);
      expect(c.activeProfileId, first);

      await c.updateAutoSelectSettings(
          AutoSelectSettings(enabled: true, profileIds: {first, second}));
      await c.autoSelectBest();

      expect(c.activeProfileId, second);
      expect(c.selectedNode!.name, 'C');
    });

    test('connect зовёт автовыбор только при непустом наборе профилей',
        () async {
      final c = await _controllerWithProfile(best: 1);
      await c.updateAutoSelectSettings(
          const AutoSelectSettings(enabled: true, profileIds: {}));
      await c.connect();
      expect(c.profiles.first.selectedNodeIndex, 0, reason: 'профиль не отмечен');

      await c.disconnect();
      await c.updateAutoSelectSettings(AutoSelectSettings(
          enabled: true, profileIds: {c.activeProfileId!}));
      await c.connect();
      expect(c.profiles.first.selectedNodeIndex, 1);
    });

    test('выключенный автовыбор не трогает выбор при connect', () async {
      final c = await _controllerWithProfile(best: 1);
      await c.updateAutoSelectSettings(AutoSelectSettings(
          enabled: false, profileIds: {c.activeProfileId!}));
      await c.connect();
      expect(c.profiles.first.selectedNodeIndex, 0);
    });
  });

  group('health-check', () {
    test('один провал health-check ноду не меняет, два подряд — меняют', () async {
      final c = await _controllerWithHealthCheck(checkResults: [false, true]);
      _fireTimer(); await pumpEventQueue();
      expect(c.profiles.first.selectedNodeIndex, 0, reason: 'сеть могла мигнуть');
      _fireTimer(); await pumpEventQueue();
      expect(c.profiles.first.selectedNodeIndex, 0, reason: 'успех обнуляет счётчик');
    });

    test('два провала подряд запускают автовыбор и переподключение', () async {
      final c = await _controllerWithHealthCheck(
          checkResults: [false, false], best: 1);
      _fireTimer(); await pumpEventQueue();
      _fireTimer(); await pumpEventQueue();
      expect(c.profiles.first.selectedNodeIndex, 1);
    });

    test('health-check продолжает тикать после переключения ноды', () async {
      // Первые два тика роняют ноду 0 → автовыбор уводит на ноду 1 с
      // переподключением. Дальше проверка должна жить: следующие два провала
      // обязаны вернуть выбор обратно.
      // Проба отвечает провалом на всё: очередь общая с HTTP-фазой автовыбора,
      // поэтому её берём с запасом.
      final c = await _controllerWithHealthCheck(
          checkResults: List.filled(20, false), best: 1);
      _fireTimer(); await pumpEventQueue();
      _fireTimer(); await pumpEventQueue();
      expect(c.profiles.first.selectedNodeIndex, 1);

      expect(_activeTimers, isNotEmpty,
          reason: 'после переподключения таймер должен быть заведён заново');

      // Лучшей остаётся та же нода 1, поэтому выбор не меняется — но живая
      // проверка обязана продолжать работать и переподнимать туннель.
      final startsBefore = proxyTunnel.startCallCount;
      _fireTimer(); await pumpEventQueue();
      _fireTimer(); await pumpEventQueue();
      expect(proxyTunnel.startCallCount, greaterThan(startsBefore));
    });

    test('успешная проверка видна в логе и в lastHealthCheck*', () async {
      final c = await _controllerWithHealthCheck(checkResults: [true]);
      _fireTimer(); await pumpEventQueue();

      expect(c.lastHealthCheckOk, isTrue);
      expect(c.lastHealthCheckAt, isNotNull);
      expect(c.logs.map((e) => e.message),
          contains(contains('проверка A — ok')));
    });

    test('провал проверки виден в логе со счётчиком', () async {
      final c = await _controllerWithHealthCheck(checkResults: [false]);
      _fireTimer(); await pumpEventQueue();

      expect(c.lastHealthCheckOk, isFalse);
      expect(c.logs.map((e) => e.message),
          contains(contains('не ответила (1 из 2)')));
    });

    test('таймер снимается при disconnect', () async {
      final c = await _controllerWithHealthCheck(checkResults: [false, false]);
      await c.disconnect();
      expect(_activeTimers, isEmpty);
    });
  });

  test('setProfileRefreshInterval пишет и сбрасывает оверрайд', () async {
    final repo = InMemoryStateRepository(PersistedState(profiles: [
      Profile(
        id: 'p1', name: 'P', url: 'https://example.com/a',
        nodes: const [], selectedNodeIndex: null,
        subscriptionMeta: const SubscriptionMeta(updateIntervalHours: 6),
      ),
    ]));
    final app = build(repo: repo);
    await app.init();

    await app.setProfileRefreshInterval('p1', 30);
    expect(app.profiles.first.effectiveRefreshIntervalMinutes, 30);

    await app.setProfileRefreshInterval('p1', null);
    // Оверрайд снят — снова действует интервал провайдера.
    expect(app.profiles.first.effectiveRefreshIntervalMinutes, 360);
  });

  group('пинг gstatic', () {
    AppController buildWithProbe({
      required Future<int?> Function(String url, int? port, {Duration timeout})
          probe,
      Future<int?> Function(String host, int port, {Duration timeout})?
          bypassProbe,
      Timer Function(Duration, void Function(Timer))? timerFactory,
    }) =>
        AppController(
          subscription: SubscriptionService(
              fetcher: (_) async => FetchResult(fakeSub, const {})),
          builder: const ConfigBuilder(),
          proxyTunnel: proxyTunnel,
          tunTunnel: tunTunnel,
          repo: InMemoryStateRepository(),
          platform: FakePlatformInfo(),
          resolveHost: (_) async => '9.9.9.9',
          timerFactory: timerFactory,
          gstaticProbe: probe,
          bypassProbe: bypassProbe ??
              (host, port, {timeout = const Duration(seconds: 3)}) async => null,
        );

    test('после подключения запускает таймер пинга с интервалом настроек',
        () async {
      final timerFactory = ControlledTimerFactory();
      final c = buildWithProbe(
        probe: (url, port, {timeout = const Duration(seconds: 3)}) async => 42,
        timerFactory: timerFactory.call,
      );
      await c.init();
      proxyTunnel.emit(TunnelStatus.connected);
      await Future<void>.delayed(Duration.zero);

      expect(timerFactory.capturedDuration, const Duration(seconds: 60));
      expect(c.settings.gstaticPingIntervalSeconds, 60);
    });

    test('первый замер приходит сразу после подключения, не ждёт интервала',
        () async {
      final c = buildWithProbe(
        probe: (url, port, {timeout = const Duration(seconds: 3)}) async => 42,
      );
      await c.init();
      proxyTunnel.emit(TunnelStatus.connected);
      await Future<void>.delayed(Duration.zero);

      expect(c.gstaticPingMs, 42);
    });

    test('выключенная настройка не запускает таймер и не пингует', () async {
      final timerFactory = ControlledTimerFactory();
      final c = buildWithProbe(
        probe: (url, port, {timeout = const Duration(seconds: 3)}) async => 42,
        timerFactory: timerFactory.call,
      );
      await c.init();
      // Интервал не 60 с: столько же длится тик автообновления профилей, и по
      // одной длительности таймеры было бы не различить.
      await c.updateSettings(c.settings.copyWith(
          gstaticPingEnabled: false, gstaticPingIntervalSeconds: 30));
      proxyTunnel.emit(TunnelStatus.connected);
      await Future<void>.delayed(Duration.zero);

      // Таймеров с интервалом пинга нет — только автообновление профилей.
      expect(
          timerFactory.durations, isNot(contains(const Duration(seconds: 30))));
      expect(c.gstaticPingMs, isNull);
    });

    test('дисконнект останавливает таймер', () async {
      final timerFactory = ControlledTimerFactory();
      final c = buildWithProbe(
        probe: (url, port, {timeout = const Duration(seconds: 3)}) async => 42,
        timerFactory: timerFactory.call,
      );
      await c.init();
      // 30, а не дефолтные 60: тик автообновления профилей идёт ровно раз в
      // минуту и попал бы в ту же выборку.
      await c.updateSettings(
          c.settings.copyWith(gstaticPingIntervalSeconds: 30));
      proxyTunnel.emit(TunnelStatus.connected);
      await Future<void>.delayed(Duration.zero);
      proxyTunnel.emit(TunnelStatus.disconnected);

      // Таймер пинга заводился один раз и не перезапустился новым тиком.
      expect(
          timerFactory.durations
              .where((d) => d == const Duration(seconds: 30))
              .length,
          1);
    });

    test('ручной pingGstatic() бьёт немедленно и обновляет значение',
        () async {
      var calls = 0;
      final c = buildWithProbe(
        probe: (url, port, {timeout = const Duration(seconds: 3)}) async {
          calls++;
          return 77;
        },
      );
      await c.init();
      proxyTunnel.emit(TunnelStatus.connected);
      await Future<void>.delayed(Duration.zero);
      calls = 0; // сбрасываем счётчик автозамера при коннекте

      await c.pingGstatic();

      expect(calls, 1);
      expect(c.gstaticPingMs, 77);
    });

    test('устаревший ответ не перетирает более новый результат', () async {
      final completers = <Completer<int?>>[];
      final c = buildWithProbe(
        probe: (url, port, {timeout = const Duration(seconds: 3)}) {
          final completer = Completer<int?>();
          completers.add(completer);
          return completer.future;
        },
      );
      await c.init();
      proxyTunnel.emit(TunnelStatus.connected);
      await Future<void>.delayed(Duration.zero);
      // Замер при коннекте уже в полёте (completers[0]).

      final first = c.pingGstatic(); // второй параллельный замер
      await Future<void>.delayed(Duration.zero);
      expect(completers.length, 2);

      // Новый (второй) приходит первым...
      completers[1].complete(10);
      await first;
      expect(c.gstaticPingMs, 10);

      // ...старый (первый) приходит позже и не должен перетереть.
      completers[0].complete(999);
      await Future<void>.delayed(Duration.zero);
      expect(c.gstaticPingMs, 10);
    });

    test('в TUN проверка идёт мимо туннеля, а не через HTTP-зонд', () async {
      var httpProbeCalls = 0;
      String? capturedHost;
      int? capturedPort;
      final c = buildWithProbe(
        probe: (url, port, {timeout = const Duration(seconds: 3)}) async {
          httpProbeCalls++;
          return 5;
        },
        bypassProbe: (host, port, {timeout = const Duration(seconds: 3)}) async {
          capturedHost = host;
          capturedPort = port;
          return 5;
        },
      );
      await c.init();
      await c.updateSettings(c.settings.copyWith(tunnelMode: TunnelMode.tun));
      tunTunnel.emit(TunnelStatus.connected);
      await Future<void>.delayed(Duration.zero);

      expect(httpProbeCalls, 0);
      expect(capturedHost, 'www.gstatic.com');
      expect(capturedPort, 443);
      expect(c.gstaticPingMs, 5);
    });

    test('в TUN пинг ноды меряется мимо туннеля, а не обычным сокетом',
        () async {
      var bypassCalls = 0;
      var plainCalls = 0;
      final c = build(
        pingService: PingService(
          connect: (host, port, {timeout}) async {
            plainCalls++;
            throw const SocketException('обычный сокет меряет туннель');
          },
          bypassPing: (host, port,
              {timeout = const Duration(seconds: 3)}) async {
            bypassCalls++;
            return 21;
          },
        ),
      );
      await c.init();
      await c.addProfile('Sub', 'https://x');
      await c.selectNode(c.profiles.first.id, 0);
      await c.updateSettings(c.settings.copyWith(tunnelMode: TunnelMode.tun));
      tunTunnel.emit(TunnelStatus.connected);
      await Future<void>.delayed(Duration.zero);

      await c.pingNode(c.selectedNode!);
      expect(bypassCalls, greaterThanOrEqualTo(1));
      expect(plainCalls, 0);
      expect(c.pingFor(c.selectedNode!)?.latencyMs, 21);
    });

    test('в Proxy пинг ноды меряется обычным сокетом', () async {
      var bypassCalls = 0;
      final c = build(
        pingService: PingService(
          connect: (host, port, {timeout}) async =>
              throw const SocketException('refused',
                  osError: OSError('Connection refused', 61)),
          bypassPing: (host, port,
              {timeout = const Duration(seconds: 3)}) async {
            bypassCalls++;
            return 21;
          },
        ),
      );
      await c.init();
      await c.addProfile('Sub', 'https://x');
      await c.selectNode(c.profiles.first.id, 0);
      proxyTunnel.emit(TunnelStatus.connected);
      await Future<void>.delayed(Duration.zero);

      await c.pingNode(c.selectedNode!);
      expect(bypassCalls, 0);
      expect(c.pingFor(c.selectedNode!)?.error, isNotNull);
    });

    test('у naive первый замер откладывается, у остальных идёт сразу',
        () async {
      Future<int> firstPingDelaySeconds(String link) async {
        final timerFactory = ControlledTimerFactory();
        final c = build(
          sub: SubscriptionService(fetcher: (_) async => FetchResult(link, const {})),
          timerFactory: timerFactory.call,
          gstaticProbe:
              (url, port, {timeout = const Duration(seconds: 3)}) async => 42,
        );
        await c.init();
        await c.addProfile('Sub', 'https://x');
        await c.selectNode(c.profiles.first.id, 0);
        proxyTunnel.emit(TunnelStatus.connected);
        await Future<void>.delayed(Duration.zero);
        // null (замер сразу) отличаем от отложенного по значению пинга.
        return c.gstaticPingMs == null ? 10 : 0;
      }

      // Naive поднимает соединение не мгновенно: замер в этот момент повис бы
      // до собственного таймаута и заметно тормозил бы приложение.
      expect(
          await firstPingDelaySeconds(
              'naive+https://user:pass@example.com:443#Naive'),
          10);
      expect(await firstPingDelaySeconds('vless://u@h:443#A'), 0);
    });

    test('автовыбор в поднятом TUN меряет TCP тоже мимо туннеля', () async {
      var bypassCalls = 0;
      var plainCalls = 0;
      final c = build(
        nodeTester: NodeTester(
          ping: PingService(
            connect: (host, port, {timeout}) async {
              plainCalls++;
              throw const SocketException('обычный сокет меряет туннель');
            },
            bypassPing: (host, port,
                {timeout = const Duration(seconds: 3)}) async {
              bypassCalls++;
              return 10;
            },
          ),
          startSingbox: (_) async {},
          stopSingbox: () async {},
          startXray: (_) async {},
          stopXray: () async {},
          pickPort: () async => 9000,
          probe: (url, port, timeout) async => 5,
        ),
      );
      await c.init();
      await c.addProfile('Sub', 'https://x');
      await c.updateSettings(c.settings.copyWith(tunnelMode: TunnelMode.tun));
      await c.updateAutoSelectSettings(c.autoSelect
          .copyWith(enabled: true, profileIds: {c.profiles.first.id}));
      tunTunnel.emit(TunnelStatus.connected);
      await Future<void>.delayed(Duration.zero);

      await c.autoSelectBest();

      expect(bypassCalls, greaterThanOrEqualTo(1));
      expect(plainCalls, 0);
    });

    test('в режиме Proxy зонд идёт через localPort', () async {
      int? capturedPort = -1;
      final c = buildWithProbe(
        probe: (url, port, {timeout = const Duration(seconds: 3)}) async {
          capturedPort = port;
          return 5;
        },
      );
      await c.init();
      proxyTunnel.emit(TunnelStatus.connected);
      await Future<void>.delayed(Duration.zero);

      expect(capturedPort, c.settings.localPort);
    });

    test('refreshHeroPing пингует и gstatic, и ноду параллельно', () async {
      var gstaticCalls = 0;
      final fakePing = PingService(
        connect: (host, port, {timeout}) async {
          throw const SocketException('refused');
        },
      );
      final app = build(
        pingService: fakePing,
        gstaticProbe: (url, port, {timeout = const Duration(seconds: 3)}) async {
          gstaticCalls++;
          return 42;
        },
      );
      await app.init();
      await app.addProfile('Sub', 'https://x');
      await app.selectNode(app.profiles.first.id, 0);
      proxyTunnel.emit(TunnelStatus.connected);
      await Future<void>.delayed(Duration.zero);

      await app.refreshHeroPing();

      expect(gstaticCalls, greaterThanOrEqualTo(1));
      expect(app.pingFor(app.selectedNode!), isNotNull);
      app.dispose();
    });
  });
}
