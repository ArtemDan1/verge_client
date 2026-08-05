import 'dart:async';
import 'dart:io';

import '../models/network_settings.dart';
import '../models/node_config.dart';
import '../tunnel/test_process.dart';
import '../tunnel/xray_process.dart' show pickFreePort;
import 'engine_selector.dart';
import 'ping_service.dart';
import 'test_config_builder.dart';

typedef ProcessStarter = Future<void> Function(Map<String, dynamic> config);
typedef ProcessStopper = Future<void> Function();

/// Задержка запроса через прокси на 127.0.0.1:[proxyPort], либо null, если
/// запрос не удался. Инъектируется в тестах.
typedef HttpProbe =
    Future<int?> Function(String url, int proxyPort, Duration timeout);

class NodeTestResult {
  final NodeConfig node;

  /// Позиция ноды в списке, переданном в [NodeTester.test]. Результаты
  /// отсортированы, а ноды сравниваются по значению — без позиции победителя
  /// не сопоставить с источником, если один и тот же сервер есть в двух
  /// профилях.
  final int index;

  /// Задержка HTTP-запроса через ноду. null — нода до HTTP-фазы не дошла или
  /// провалила её.
  final int? latencyMs;

  /// Задержка TCP-коннекта до адреса ноды. null — не отвечает вовсе.
  final int? tcpMs;

  const NodeTestResult(this.node, this.index, {this.latencyMs, this.tcpMs});
}

Future<int?> _defaultProbe(String url, int proxyPort, Duration timeout,
    void Function(String)? log) async {
  final client = HttpClient()
    ..connectionTimeout = timeout
    // Тестовый процесс поднимает http-инбаунд — HttpClient ходит через него
    // как через обычный прокси, отдельный SOCKS-клиент не нужен.
    ..findProxy = (_) => 'PROXY 127.0.0.1:$proxyPort';
  final sw = Stopwatch()..start();
  try {
    final req = await client.getUrl(Uri.parse(url)).timeout(timeout);
    final res = await req.close().timeout(timeout);
    sw.stop();
    await res.drain<void>();
    if (res.statusCode >= 400) {
      log?.call('порт $proxyPort: HTTP ${res.statusCode}');
      return null;
    }
    return sw.elapsedMilliseconds;
  } catch (e) {
    log?.call('порт $proxyPort: $e');
    return null;
  } finally {
    client.close(force: true);
  }
}

/// Замер «лучшей ноды»: сначала дешёвый TCP-префильтр по всем нодам, затем
/// честный HTTP-запрос через несколько лучших. TCP-пинг один не годится —
/// нода может принимать соединение и не пропускать трафик.
class NodeTester {
  final PingService _ping;
  final ProcessStarter _startSingbox;
  final ProcessStopper _stopSingbox;
  final ProcessStarter _startXray;
  final ProcessStopper _stopXray;
  late final HttpProbe _probe;
  final Future<int> Function() _pickPort;

  /// Куда писать причины провалов. Молчаливый тестер невозможно
  /// диагностировать: снаружи видно только «HTTP не прошёл ни у одной ноды».
  final void Function(String)? _onLog;

  /// Сколько лучших по TCP нод доходит до HTTP-фазы.
  static const httpCandidates = 5;
  static const httpTimeout = Duration(seconds: 5);

  /// Параллельность TCP-префильтра — как в AppController.pingNodes.
  static const _tcpConcurrency = 8;

  NodeTester({
    PingService? ping,
    ProcessStarter? startSingbox,
    ProcessStopper? stopSingbox,
    ProcessStarter? startXray,
    ProcessStopper? stopXray,
    HttpProbe? probe,
    Future<int> Function()? pickPort,
    void Function(String)? onLog,
  }) : _onLog = onLog,
       _ping = ping ?? PingService(),
       _startSingbox = startSingbox ?? SingboxTestProcess().start,
       _stopSingbox = stopSingbox ?? SingboxTestProcess().stop,
       _startXray = startXray ?? XrayTestProcess().start,
       _stopXray = stopXray ?? XrayTestProcess().stop,
       _pickPort = pickPort ?? pickFreePort {
    _probe = probe ?? (url, port, timeout) => _defaultProbe(url, port, timeout, _onLog);
  }

  Future<List<NodeTestResult>> test(
    List<NodeConfig> nodes, {
    required String url,
    NetworkSettings network = const NetworkSettings(),
  }) async {
    final tcp = await _tcpPhase(nodes);

    // Ноды сравниваются по значению, поэтому нумеруем их позициями: две
    // одинаковые ноды в профиле иначе схлопнулись бы в один ключ и получили
    // бы один порт на двоих — тестовый процесс не забиндился бы.
    final alive = [
      for (var i = 0; i < nodes.length; i++)
        if (tcp[i] != null) i,
    ]..sort((a, b) => tcp[a]!.compareTo(tcp[b]!));
    final candidates = alive.take(httpCandidates).toList();

    final http = candidates.isEmpty
        ? const <int, int>{}
        : await _httpPhase(
            [for (final i in candidates) nodes[i]],
            url: url,
            network: network,
          );

    final latency = <int, int>{
      for (var k = 0; k < candidates.length; k++)
        if (http[k] != null) candidates[k]: http[k]!,
    };

    final results = [
      for (var i = 0; i < nodes.length; i++)
        NodeTestResult(nodes[i], i, latencyMs: latency[i], tcpMs: tcp[i]),
    ];
    results.sort(_byQuality);
    return results;
  }

  /// Жива ли конкретная нода прямо сейчас. Используется фоновой проверкой:
  /// один процесс, один запрос.
  Future<bool> check(
    NodeConfig node, {
    required String url,
    NetworkSettings network = const NetworkSettings(),
  }) async {
    final res = await _httpPhase([node], url: url, network: network);
    return res[0] != null;
  }

  /// Лучший первым: сначала прошедшие HTTP по возрастанию задержки, затем
  /// живые по TCP, затем мёртвые.
  static int _byQuality(NodeTestResult a, NodeTestResult b) {
    if (a.latencyMs != null || b.latencyMs != null) {
      if (a.latencyMs == null) return 1;
      if (b.latencyMs == null) return -1;
      return a.latencyMs!.compareTo(b.latencyMs!);
    }
    if (a.tcpMs == null && b.tcpMs == null) return 0;
    if (a.tcpMs == null) return 1;
    if (b.tcpMs == null) return -1;
    return a.tcpMs!.compareTo(b.tcpMs!);
  }

  /// Задержки по позициям нод, а не по самим нодам: NodeConfig сравнивается
  /// по значению, и дубликаты в профиле потеряли бы свой результат.
  Future<List<int?>> _tcpPhase(List<NodeConfig> nodes) async {
    final out = List<int?>.filled(nodes.length, null);
    var i = 0;
    Future<void> worker() async {
      while (i < nodes.length) {
        final at = i++;
        final res = await _ping.ping(nodes[at]);
        out[at] = res.latencyMs;
      }
    }

    await Future.wait(List.generate(_tcpConcurrency, (_) => worker()));
    return out;
  }

  /// Поднимает по процессу на движок и меряет все ноды параллельно.
  /// Процессы останавливаются всегда: висящий тестовый sing-box хуже
  /// проваленного замера.
  /// Ключ результата — позиция ноды в [nodes], по той же причине, что и в
  /// TCP-фазе.
  Future<Map<int, int>> _httpPhase(
    List<NodeConfig> nodes, {
    required String url,
    required NetworkSettings network,
  }) async {
    final singbox = <int>[], xray = <int>[];
    for (var i = 0; i < nodes.length; i++) {
      (preferXray(nodes[i]) ? xray : singbox).add(i);
    }
    final ports = [for (var i = 0; i < nodes.length; i++) await _pickPort()];

    final started = <ProcessStopper>[];
    try {
      if (singbox.isNotEmpty) {
        final cfg = buildSingboxTestConfig(
          [for (final i in singbox) nodes[i]],
          ports: [for (final i in singbox) ports[i]],
          network: network,
        );
        await _startSingbox(cfg);
        started.add(_stopSingbox);
      }
      if (xray.isNotEmpty) {
        final cfg = buildXrayTestConfig(
          [for (final i in xray) nodes[i]],
          ports: [for (final i in xray) ports[i]],
          network: network,
        );
        await _startXray(cfg);
        started.add(_stopXray);
      }

      final out = <int, int>{};
      await Future.wait([
        for (var i = 0; i < nodes.length; i++)
          () async {
            try {
              final ms = await _probe(url, ports[i], httpTimeout);
              if (ms != null) out[i] = ms;
            } catch (_) {
              // Провал пробы — это провал ноды, а не всего прогона.
            }
          }(),
      ]);
      return out;
    } on Object catch (e) {
      // Процесс не поднялся (в том числе MissingPluginException не на macOS) —
      // считаем, что HTTP-фаза не дала результатов.
      _onLog?.call('тестовый процесс не запустился: $e');
      return const {};
    } finally {
      for (final stop in started) {
        try {
          await stop();
        } catch (_) {}
      }
    }
  }
}
