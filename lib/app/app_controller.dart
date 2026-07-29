import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/node_config.dart';
import '../models/node_engine.dart';
import '../models/profile.dart';
import '../models/app_settings.dart';
import '../models/persisted_state.dart';
import '../models/routing_profile.dart';
import '../models/log_entry.dart';
import '../services/subscription_service.dart';
import '../services/config_builder.dart';
import '../services/engine_selector.dart';
import '../services/xray_config_builder.dart';
import '../tunnel/xray_process.dart';
import '../services/geo_updater.dart';
import '../services/routing_presets.dart';
import '../storage/state_repository.dart';
import '../platform/platform_info.dart';
import '../platform/helper_service.dart';
import '../services/update_service.dart';
import '../tunnel/tunnel_controller.dart';
import '../services/ping_service.dart';
import '../models/connection_info.dart';
import '../services/clash_api_client.dart';

enum TunModeResult { enabled, denied }

class AppController extends ChangeNotifier {
  final SubscriptionService _subscription;
  final PingService _ping;
  final TunnelController _proxyTunnel;
  final TunnelController _tunTunnel;
  final StateRepository _repo;
  final PlatformInfo _platform;
  final Future<String?> Function(String host) _resolveHost;
  final Timer Function(Duration, void Function(Timer)) _timerFactory;
  final HelperService _helper;
  final UpdateService _update;

  /// Клиент Clash API живёт на уровне контроллера, а не экрана: badge в
  /// сайдбаре и счётчики трафика обновляются при любом открытом экране.
  final ClashApiClient _clashApi;

  /// Фабрика дочернего процесса Xray. Процесс создаётся лениво, при первой
  /// ноде, которой нужен второй движок: конструктор XrayProcess подписывается
  /// на платформенный канал, и в чисто sing-box-сценариях это лишнее.
  final XrayProcess Function() _xrayFactory;
  XrayProcess? _xrayInstance;
  StreamSubscription<String>? _xrayLogSub;

  XrayProcess get _xray {
    final existing = _xrayInstance;
    if (existing != null) return existing;
    final created = _xrayFactory();
    _xrayInstance = created;
    _xrayLogSub = created.logs.listen(_appendLog);
    return created;
  }

  /// Выбор свободного порта и проба socks — параметры, чтобы тесты могли
  /// подменить работу с реальными сокетами.
  final Future<int> Function() _pickPort;
  final Future<bool> Function(int port) _probeSocks;

  /// Доступное обновление (после успешной проверки) или null.
  UpdateInfo? availableUpdate;
  bool isCheckingUpdate = false;
  double? updateDownloadProgress;

  /// Папка с распакованными .srs; если задана — rule-set подключаются локально.
  final String? geoAssetDir;

  /// Обновлятор gee-наборов. Если null — автообновление выключено.
  final GeoUpdater? _geoUpdater;

  /// Наборы старше этого срока обновляем автоматически после подключения.
  static const _geoMaxAge = Duration(days: 7);
  final _uuid = const Uuid();
  late final StreamSubscription<TunnelStatus> _proxySub;
  late final StreamSubscription<TunnelStatus> _tunSub;
  late final StreamSubscription<String> _proxyLogSub;
  late final StreamSubscription<String> _tunLogSub;

  static const _logLimit = 500;
  final List<LogEntry> _logs = [];
  List<LogEntry> get logs => List.unmodifiable(_logs);

  ValueListenable<List<ConnectionInfo>> get connections => _clashApi.connections;
  ValueListenable<TrafficStats> get traffic => _clashApi.traffic;

  void _appendLog(String line) {
    // Строка может прийти пачкой (helper отдаёт накопленное) — режем на строки
    // и разбираем каждую отдельно, иначе время/уровень не определятся.
    for (final part in line.split('\n')) {
      if (part.trim().isEmpty) continue;
      _addEntry(LogEntry.parse(part));
    }
    notifyListeners();
  }

  void _addEntry(LogEntry entry) {
    _logs.add(entry);
    if (_logs.length > _logLimit) {
      _logs.removeRange(0, _logs.length - _logLimit);
    }
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  /// Одноразовые уведомления для UI (например, аварийное падение sing-box).
  final _alertCtrl = StreamController<String>.broadcast();
  Stream<String> get alerts => _alertCtrl.stream;

  Timer? _refreshTimer;
  bool _refreshingAll = false;
  String? _refreshError;

  AppController({
    required SubscriptionService subscription,
    required ConfigBuilder builder,
    required TunnelController proxyTunnel,
    required TunnelController tunTunnel,
    required StateRepository repo,
    required PlatformInfo platform,
    Future<String?> Function(String host)? resolveHost,
    Timer Function(Duration, void Function(Timer))? timerFactory,
    this.geoAssetDir,
    GeoUpdater? geoUpdater,
    PingService? pingService,
    HelperService? helper,
    UpdateService? updateService,
    ClashApiClient? clashApi,
    XrayProcess Function()? xrayFactory,
    Future<int> Function()? pickPort,
    Future<bool> Function(int port)? probeSocks,
  })  : _xrayFactory = xrayFactory ?? XrayProcess.new,
        _pickPort = pickPort ?? pickFreePort,
        _probeSocks = probeSocks ?? _defaultProbeSocks,
        _ping = pingService ?? PingService(),
        _helper = helper ?? HelperService(),
        _update = updateService ?? UpdateService(),
        _clashApi = clashApi ?? ClashApiClient(),
        _subscription = subscription,
        _geoUpdater = geoUpdater,
        _proxyTunnel = proxyTunnel,
        _tunTunnel = tunTunnel,
        _repo = repo,
        _platform = platform,
        _resolveHost = resolveHost ?? _dnsLookup,
        _timerFactory = timerFactory ?? Timer.periodic {
    _proxySub = _proxyTunnel.statusStream.listen((s) => _onStatus(_proxyTunnel, s));
    _tunSub = _tunTunnel.statusStream.listen((s) => _onStatus(_tunTunnel, s));
    _proxyLogSub = _proxyTunnel.logStream.listen(_appendLog);
    _tunLogSub = _tunTunnel.logStream.listen(_appendLog);
  }

  void _onStatus(TunnelController src, TunnelStatus s) {
    if (src != _activeTunnel) return;
    _status = s;
    // Момент подключения живёт в контроллере, а не в виджете: иначе аптайм
    // сбрасывался бы при каждом переходе между экранами.
    if (s == TunnelStatus.connected) {
      _connectedAt ??= DateTime.now();
    } else if (s == TunnelStatus.disconnected || s == TunnelStatus.error) {
      _connectedAt = null;
    }
    // Аварийное завершение sing-box — показываем причину пользователю.
    if (s == TunnelStatus.error) {
      _error = src.lastError ?? 'sing-box завершился аварийно';
      _alertCtrl.add('VPN отключён: ${_error!}');
    }
    if (s == TunnelStatus.disconnected || s == TunnelStatus.error) {
      _clashApi.stop();
    }
    notifyListeners();
    // Туннель поднялся — самое время обновить устаревшие наборы через прокси.
    if (s == TunnelStatus.connected &&
        _geoUpdater != null &&
        _geoStale &&
        !_updatingGeo) {
      updateGeoAssets().ignore();
    }
  }

  /// Обёртка над top-level probeSocks: одноимённый параметр конструктора его
  /// затеняет, поэтому ссылаемся через неё.
  static Future<bool> _defaultProbeSocks(int port) => probeSocks(port);

  static Future<String?> _dnsLookup(String host) async {
    try {
      final addrs = await InternetAddress.lookup(host);
      return addrs.isNotEmpty ? addrs.first.address : null;
    } catch (_) {
      return null;
    }
  }

  TunnelController get _activeTunnel =>
      _state.settings.tunnelMode == TunnelMode.tun ? _tunTunnel : _proxyTunnel;

  PersistedState _state = const PersistedState();
  TunnelStatus _status = TunnelStatus.disconnected;

  /// Момент установления соединения; null, когда VPN не активен.
  DateTime? _connectedAt;
  DateTime? get connectedAt => _connectedAt;
  final Map<String, PingResult> _pings = {};
  final Set<String> _pinging = {};
  static String _pingKey(NodeConfig n) => '${n.host}:${n.port}';

  PingResult? pingFor(NodeConfig n) => _pings[_pingKey(n)];
  bool isPinging(NodeConfig n) => _pinging.contains(_pingKey(n));
  String? _error;
  bool _updatingGeo = false;
  String? _geoUpdateError;

  List<Profile> get profiles => _state.profiles;
  String? get activeProfileId => _state.activeProfileId;
  AppSettings get settings => _state.settings;
  TunnelStatus get status => _status;
  String? get error => _error;
  PlatformInfo get platform => _platform;
  bool get isRefreshingAll => _refreshingAll;
  String? get refreshError => _refreshError;
  bool get isUpdatingGeo => _updatingGeo;
  String? get geoUpdateError => _geoUpdateError;
  DateTime? get geoUpdatedAt => _state.geoUpdatedAt;
  bool get canUpdateGeo => _geoUpdater != null;

  Profile? get activeProfile {
    final id = _state.activeProfileId;
    if (id == null) return null;
    for (final p in _state.profiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  NodeConfig? get selectedNode => activeProfile?.selectedNode;

  List<RoutingProfile> get routingProfiles => _state.routingProfiles;
  String? get activeRoutingProfileId => _state.activeRoutingProfileId;

  RoutingProfile? get activeRoutingProfile {
    final id = _state.activeRoutingProfileId;
    if (id == null) return null;
    for (final p in _state.routingProfiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  void clearRefreshError() {
    _refreshError = null;
    notifyListeners();
  }

  bool get _geoStale {
    final at = _state.geoUpdatedAt;
    return at == null || DateTime.now().difference(at) > _geoMaxAge;
  }

  /// Порт локального прокси для загрузки наборов в обход блокировок.
  /// В TUN-режиме весь трафик и так идёт через туннель (прямая загрузка),
  /// в systemProxy качаем через mixed-инбаунд sing-box.
  int? get _geoProxyPort {
    if (_status != TunnelStatus.connected) return null;
    if (_state.settings.tunnelMode == TunnelMode.tun) return null;
    return _state.settings.localPort;
  }

  /// Скачивает свежие gee-наборы и перезаписывает локальные .srs.
  /// Лучше всего вызывать при поднятом туннеле — иначе прямой путь к GitHub
  /// в РФ может быть заблокирован.
  Future<void> updateGeoAssets() async {
    final updater = _geoUpdater;
    if (updater == null || _updatingGeo) return;
    _updatingGeo = true;
    _geoUpdateError = null;
    notifyListeners();
    try {
      final res = await updater.updateAll(proxyPort: _geoProxyPort);
      if (res.updated > 0) {
        _state = _state.copyWith(geoUpdatedAt: DateTime.now());
        await _repo.save(_state);
      }
      _geoUpdateError = res.ok
          ? null
          : 'Не обновились: ${res.failed.length} наб. (проверьте подключение)';
    } catch (e) {
      _geoUpdateError = e.toString();
    } finally {
      _updatingGeo = false;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    await _repo.save(_state);
    notifyListeners();
  }

  void _scheduleAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    final s = _state.settings;
    if (!s.autoRefreshEnabled) return;
    _refreshTimer = _timerFactory(
      Duration(minutes: s.autoRefreshIntervalMinutes),
      (_) => refreshAllProfiles().ignore(),
    );
  }

  Future<void> init() async {
    _state = await _repo.load();
    if (_state.routingProfiles.isEmpty) {
      final presets = routingPresets();
      _state = _state.copyWith(
        routingProfiles: presets,
        activeRoutingProfileId:
            _state.activeRoutingProfileId ?? presets.first.id,
      );
      await _repo.save(_state);
    }
    notifyListeners();
    if (_state.settings.autostart && selectedNode != null) {
      await connect();
    }
    _scheduleAutoRefresh();
    if (_state.settings.autoRefreshEnabled) {
      refreshAllProfiles().ignore();
    }
  }

  Future<void> addProfile(String name, String url) async {
    final res = await _subscription.loadWithInfo(url);
    final nodes = res.nodes;
    final profile = Profile(
      id: _uuid.v4(),
      name: name,
      url: url,
      nodes: nodes,
      selectedNodeIndex: nodes.isEmpty ? null : 0,
      subscriptionInfo: res.info,
    );
    _state = _state.copyWith(
      profiles: [..._state.profiles, profile],
      activeProfileId: _state.activeProfileId ?? profile.id,
    );
    await _persist();
  }

  Future<void> refreshProfile(String id) async {
    final idx = _state.profiles.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    final old = _state.profiles[idx];
    try {
      final res = await _subscription.loadWithInfo(old.url);
      final nodes = res.nodes;
      final keepIndex =
          (old.selectedNodeIndex != null && old.selectedNodeIndex! < nodes.length)
              ? old.selectedNodeIndex
              : (nodes.isEmpty ? null : 0);
      final updated = old.copyWith(
        nodes: nodes,
        selectedNodeIndex: keepIndex,
        lastRefreshedAt: DateTime.now(),
        subscriptionInfo: res.info ?? old.subscriptionInfo,
      );
      final list = [..._state.profiles]..[idx] = updated;
      _state = _state.copyWith(profiles: list);
      _error = null;
    } on SubscriptionException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    }
    await _persist();
  }

  Future<void> refreshAllProfiles() async {
    if (_refreshingAll) return;
    _refreshingAll = true;
    notifyListeners();
    final failed = <String>[];
    for (final p in List.of(_state.profiles)) {
      await refreshProfile(p.id);
      if (_error != null) failed.add(p.name);
    }
    _refreshingAll = false;
    _refreshError =
        failed.isEmpty ? null : 'Не удалось обновить: ${failed.join(", ")}';
    notifyListeners();
  }

  Future<void> removeProfile(String id) async {
    if (_state.activeProfileId == id &&
        (_status == TunnelStatus.connected ||
            _status == TunnelStatus.connecting)) {
      await disconnect();
    }
    final list = _state.profiles.where((p) => p.id != id).toList();
    final clearActive = _state.activeProfileId == id;
    _state = _state.copyWith(
      profiles: list,
      clearActive: clearActive,
      activeProfileId: clearActive ? null : _state.activeProfileId,
    );
    await _persist();
  }

  Future<void> selectNode(String profileId, int index) async {
    final idx = _state.profiles.indexWhere((p) => p.id == profileId);
    if (idx < 0) return;
    final updated = _state.profiles[idx].copyWith(selectedNodeIndex: index);
    final list = [..._state.profiles]..[idx] = updated;
    _state = _state.copyWith(profiles: list, activeProfileId: profileId);
    await _persist();
    if (_status == TunnelStatus.connected ||
        _status == TunnelStatus.connecting) {
      await disconnect();
      await connect();
    }
  }

  /// Смена движка ноды. Если это активная нода на живом туннеле — переподключаем,
  /// иначе выбор вступит в силу при следующем подключении.
  Future<void> setNodeEngineChoice(
      String profileId, NodeConfig node, EngineChoice choice) async {
    final idx = _state.profiles.indexWhere((p) => p.id == profileId);
    if (idx < 0) return;
    final updated = _state.profiles[idx].withEngineChoice(node, choice);
    final list = [..._state.profiles]..[idx] = updated;
    _state = _state.copyWith(profiles: list);
    await _persist();

    final active = selectedNode;
    final isActive = active != null &&
        _state.activeProfileId == profileId &&
        nodeEngineKey(active) == nodeEngineKey(node) &&
        (_status == TunnelStatus.connected ||
            _status == TunnelStatus.connecting);
    if (isActive) {
      await disconnect();
      await connect();
    }
  }

  Future<void> selectRoutingProfile(String id) async {
    if (!_state.routingProfiles.any((p) => p.id == id)) return;
    _state = _state.copyWith(activeRoutingProfileId: id);
    await _persist();
    if (_status == TunnelStatus.connected ||
        _status == TunnelStatus.connecting) {
      await disconnect();
      await connect();
    }
  }

  Future<RoutingProfile> cloneRoutingProfile(String id) async {
    final src = _state.routingProfiles.firstWhere((p) => p.id == id);
    final clone = RoutingProfile(
      id: _uuid.v4(),
      name: '${src.name} (копия)',
      isBuiltIn: false,
      allowRules: List.of(src.allowRules),
      allowAction: src.allowAction,
      directRules: List.of(src.directRules),
      proxyRules: List.of(src.proxyRules),
      blockRules: List.of(src.blockRules),
      finalAction: src.finalAction,
    );
    _state = _state.copyWith(
        routingProfiles: [..._state.routingProfiles, clone]);
    await _persist();
    return clone;
  }

  Future<RoutingProfile> addRoutingProfile(String name) async {
    final profile = RoutingProfile(
      id: _uuid.v4(),
      name: name,
      isBuiltIn: false,
      directRules: const [],
      proxyRules: const [],
      blockRules: const [],
      finalAction: RoutingFinal.proxy,
    );
    _state = _state.copyWith(
        routingProfiles: [..._state.routingProfiles, profile]);
    await _persist();
    return profile;
  }

  Future<void> updateRoutingProfile(RoutingProfile updated) async {
    final idx =
        _state.routingProfiles.indexWhere((p) => p.id == updated.id);
    if (idx < 0 || _state.routingProfiles[idx].isBuiltIn) return;
    final list = [..._state.routingProfiles]..[idx] = updated;
    _state = _state.copyWith(routingProfiles: list);
    await _persist();
    if (_state.activeRoutingProfileId == updated.id &&
        (_status == TunnelStatus.connected ||
            _status == TunnelStatus.connecting)) {
      await disconnect();
      await connect();
    }
  }

  Future<void> removeRoutingProfile(String id) async {
    final matches = _state.routingProfiles.where((p) => p.id == id);
    if (matches.isEmpty || matches.first.isBuiltIn) return;
    final list = _state.routingProfiles.where((p) => p.id != id).toList();
    final wasActive = _state.activeRoutingProfileId == id;
    final newActive =
        wasActive ? 'preset-all-proxy' : _state.activeRoutingProfileId;
    _state = _state.copyWith(routingProfiles: list, activeRoutingProfileId: newActive);
    await _persist();
    if (wasActive &&
        (_status == TunnelStatus.connected ||
            _status == TunnelStatus.connecting)) {
      await disconnect();
      await connect();
    }
  }

  Future<void> updateSettings(AppSettings settings) async {
    final modeChanged = settings.tunnelMode != _state.settings.tunnelMode;
    final wasActive = _status == TunnelStatus.connected ||
        _status == TunnelStatus.connecting;
    // Смена режима на ходу: гасим туннель СТАРОГО режима до обновления state
    // (disconnect()/_activeTunnel смотрят на текущий tunnelMode), иначе работают
    // два sing-box одновременно — двойной роутинг и конфликт за cache-файл.
    if (modeChanged && wasActive) {
      await _activeTunnel.stop();
    }
    _state = _state.copyWith(settings: settings);
    await _persist();
    _scheduleAutoRefresh();
    if (modeChanged && wasActive) {
      await connect();
    }
  }

  /// Переключение в TUN с проверкой системного helper'а. Helper ставится
  /// отдельным .pkg-инсталлятором; приложение его не регистрирует, только
  /// проверяет доступность по XPC.
  Future<TunModeResult> requestTunMode() async {
    final status = await _helper.status();
    if (status == 'enabled') {
      await updateSettings(_state.settings.copyWith(tunnelMode: TunnelMode.tun));
      return TunModeResult.enabled;
    }
    _alertCtrl.add('Системный сервис не установлен. Переустановите приложение '
        'через установщик (.pkg).');
    return TunModeResult.denied;
  }

  /// Тонкая обёртка для UI: текущий статус helper'а.
  Future<String> helperStatus() => _helper.status();

  Future<void> checkForUpdate() async {
    isCheckingUpdate = true;
    notifyListeners();
    try {
      availableUpdate =
          await _update.checkForUpdate(await _platform.appVersion());
    } catch (e) {
      availableUpdate = null;
      _alertCtrl.add('Не удалось проверить обновления: $e');
    } finally {
      isCheckingUpdate = false;
      notifyListeners();
    }
  }

  Future<void> downloadAndInstallUpdate() async {
    final info = availableUpdate;
    if (info == null) return;
    try {
      final path = await _update.downloadPkg(info.pkgUrl, onProgress: (p) {
        updateDownloadProgress = p;
        notifyListeners();
      });
      // Гасим туннель ДО установщика: postinstall делает bootout демона, и
      // оборванный на полпути туннель оставит переопределённый DNS/системный
      // прокси в системе.
      if (_status == TunnelStatus.connected ||
          _status == TunnelStatus.connecting) {
        await disconnect();
      }
      await _platform.installUpdate(path);
    } catch (e) {
      _alertCtrl.add('Не удалось загрузить обновление: $e');
    } finally {
      updateDownloadProgress = null;
      notifyListeners();
    }
  }

  Future<void> pingNode(NodeConfig node) async {
    final key = _pingKey(node);
    if (_pinging.contains(key)) return;
    _pinging.add(key);
    notifyListeners();
    final res = await _ping.ping(node);
    _pings[key] = res;
    _pinging.remove(key);
    notifyListeners();
  }

  Future<void> pingNodes(List<NodeConfig> nodes) async {
    final unique = <String, NodeConfig>{};
    for (final n in nodes) {
      unique[_pingKey(n)] = n;
    }
    final queue = unique.values.toList();
    const concurrency = 8;
    var i = 0;
    Future<void> worker() async {
      while (i < queue.length) {
        final node = queue[i++];
        await pingNode(node);
      }
    }
    await Future.wait(List.generate(concurrency, (_) => worker()));
  }

  Future<void> pingProfile(String profileId) async {
    final idx = _state.profiles.indexWhere((p) => p.id == profileId);
    if (idx < 0) return;
    await pingNodes(_state.profiles[idx].nodes);
  }

  Future<void> pingAll() async {
    final all = <NodeConfig>[
      for (final p in _state.profiles) ...p.nodes,
    ];
    await pingNodes(all);
  }

  /// Фактический движок текущего подключения. null — не подключены.
  NodeEngine? get activeEngine => _activeEngine;
  NodeEngine? _activeEngine;

  Future<void> connect() async {
    final node = selectedNode;
    if (node == null) return;
    _status = TunnelStatus.connecting;
    notifyListeners();

    final choice = activeProfile?.engineChoiceFor(node) ?? EngineChoice.auto;
    var engine = resolveEngine(node, choice);
    int? socksPort;

    if (engine == NodeEngine.xray) {
      socksPort = await _startXray(node);
      if (socksPort == null) {
        if (choice == EngineChoice.auto) {
          // Автовыбор ошибся — молча откатываемся, нода важнее движка.
          _appendLog('Xray не запустился, откат на sing-box');
          engine = NodeEngine.singbox;
        } else {
          // Движок зафиксирован руками — уважаем выбор и показываем ошибку.
          _appendLog('Xray не запустился, движок выбран вручную — отката нет');
          _error = 'Xray не запустился';
          _status = TunnelStatus.error;
          _alertCtrl.add('VPN не подключён: Xray не запустился');
          notifyListeners();
          return;
        }
      }
    }
    _activeEngine = engine;

    final port = _state.settings.localPort;
    final api = await ClashApiCredentials.generate();
    final builder = ConfigBuilder(
      localPort: port,
      geoAssetDir: geoAssetDir,
      clashApiPort: api.port,
      clashApiSecret: api.secret,
    );
    final routing = activeRoutingProfile;
    if (_state.settings.tunnelMode == TunnelMode.tun) {
      final ip = await _resolveHost(node.host);
      // Сервис нужен, чтобы на старте TUN переопределить системный DNS (иначе
      // запросы к LAN-роутеру минуют туннель и hijack-dns не срабатывает).
      final service = await _resolveService();
      final config = builder.build(node,
          mode: TunnelMode.tun,
          serverIp: ip,
          routing: routing,
          xraySocksPort: socksPort);
      await _tunTunnel.start(config, port: port, service: service);
    } else {
      final service = await _resolveService();
      final config =
          builder.build(node, routing: routing, xraySocksPort: socksPort);
      await _proxyTunnel.start(config, port: port, service: service);
    }
    _clashApi.start(api);
    notifyListeners();
  }

  /// Поднимает Xray и возвращает порт его socks-inbound, либо null, если не
  /// удалось. Критерий успеха: процесс жив после startup-grace И порт отвечает.
  Future<int?> _startXray(NodeConfig node) async {
    final port = await _pickPort();
    final config = buildXrayConfig(node, socksPort: port);
    if (config == null) {
      _appendLog('для этой ноды Xray-конфиг не собирается');
      return null;
    }
    try {
      await _xray.start(config);
    } on PlatformException catch (e) {
      _appendLog('Xray не стартовал: ${e.message}');
      return null;
    } on MissingPluginException {
      // Канал не зарегистрирован (не macOS или тестовая среда).
      _appendLog('Xray недоступен на этой платформе');
      return null;
    }
    if (!await _probeSocks(port)) {
      _appendLog('Xray стартовал, но socks-порт $port не отвечает');
      await _stopXray();
      return null;
    }
    return port;
  }

  Future<void> _stopXray() async {
    final xray = _xrayInstance;
    if (xray == null) return;
    try {
      await xray.stop();
    } on MissingPluginException {
      // Нечего останавливать: канала нет.
    }
  }

  Future<void> disconnect() async {
    await _clashApi.stop();
    // Порядок обязателен: сначала sing-box, иначе его последние соединения
    // повиснут на уже мёртвом Xray.
    await _activeTunnel.stop();
    await _stopXray();
    _activeEngine = null;
    notifyListeners();
  }

  Future<String> _resolveService() async {
    final s = _state.settings.networkService;
    if (s != 'auto') return s;

    final auto = await _platform.defaultService();
    if (auto != null && auto.isNotEmpty) return auto;

    final list = await _platform.listNetworkServices();
    if (list.contains('Wi-Fi')) return 'Wi-Fi';

    for (final service in list) {
      if (!service.startsWith('*')) return service;
    }
    return 'Wi-Fi';
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _proxySub.cancel();
    _tunSub.cancel();
    _proxyLogSub.cancel();
    _tunLogSub.cancel();
    _xrayLogSub?.cancel();
    _xrayInstance?.dispose();
    _alertCtrl.close();
    _clashApi.dispose();
    super.dispose();
  }
}
