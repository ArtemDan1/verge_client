import '../models/network_settings.dart';
import '../models/node_config.dart';
import 'config_builder.dart';
import 'engine_selector.dart';
import 'xray_outbound_builder.dart';

/// Ноды, разложенные по движкам: одним процессом их не проверить.
class EngineSplit {
  final List<NodeConfig> singbox;
  final List<NodeConfig> xray;
  const EngineSplit(this.singbox, this.xray);
}

/// Делит ноды так же, как это делает боевое подключение в режиме auto.
EngineSplit splitByEngine(List<NodeConfig> nodes) {
  final sb = <NodeConfig>[], xr = <NodeConfig>[];
  for (final n in nodes) {
    (preferXray(n) ? xr : sb).add(n);
  }
  return EngineSplit(sb, xr);
}

void _checkPorts(List<NodeConfig> nodes, List<int> ports) {
  if (nodes.length != ports.length) {
    throw ArgumentError('нужен ровно один порт на ноду: '
        '${nodes.length} нод, ${ports.length} портов');
  }
}

/// Конфиг тестового sing-box: по http-инбаунду на ноду, каждый заворачивается
/// в свой outbound. Инбаунд именно http, а не socks: HttpClient умеет
/// http-прокси из коробки, а SOCKS-клиента в проекте нет.
///
/// Роутинга по гео, DNS и clash-api здесь нет намеренно — процесс живёт
/// секунды и меряет один запрос.
Map<String, dynamic> buildSingboxTestConfig(List<NodeConfig> nodes,
    {required List<int> ports,
    NetworkSettings network = const NetworkSettings()}) {
  _checkPorts(nodes, ports);
  final builder = ConfigBuilder(network: network);
  final inbounds = <Map<String, dynamic>>[];
  final outbounds = <Map<String, dynamic>>[];
  final rules = <Map<String, dynamic>>[];

  for (var i = 0; i < nodes.length; i++) {
    inbounds.add({
      'type': 'http',
      'tag': 'test-in-$i',
      'listen': '127.0.0.1',
      'listen_port': ports[i],
    });
    outbounds.add(builder.outboundFor(nodes[i], tag: 'test-out-$i'));
    rules.add({
      'inbound': ['test-in-$i'],
      'outbound': 'test-out-$i',
    });
  }

  return {
    'log': {'level': 'error', 'timestamp': true},
    // Outbound'ы приходят из ConfigBuilder с `domain_resolver: direct-dns` —
    // без сервера с таким тегом sing-box падает с FATAL «domain resolver not
    // found». Резолвер тут системный: тестовому процессу нужно разрешить
    // только адрес самой ноды, целевой домен уедет внутрь прокси-протокола.
    'dns': {
      'servers': [
        {'type': 'local', 'tag': 'direct-dns'},
      ],
      'final': 'direct-dns',
      'strategy': network.ipv6Enabled ? 'prefer_ipv4' : 'ipv4_only',
    },
    'inbounds': inbounds,
    'outbounds': [...outbounds, {'type': 'direct', 'tag': 'direct'}],
    'route': {'rules': rules, 'final': 'direct'},
  };
}

/// То же для Xray. Ноды, из которых Xray-outbound не собирается, молча
/// пропускаются: провалить весь прогон из-за одной такой ноды нельзя.
Map<String, dynamic> buildXrayTestConfig(List<NodeConfig> nodes,
    {required List<int> ports,
    NetworkSettings network = const NetworkSettings()}) {
  _checkPorts(nodes, ports);
  final inbounds = <Map<String, dynamic>>[];
  final outbounds = <Map<String, dynamic>>[];
  final rules = <Map<String, dynamic>>[];

  for (var i = 0; i < nodes.length; i++) {
    final out = buildXrayOutbound(nodes[i], network: network);
    if (out == null) continue;
    inbounds.add({
      'listen': '127.0.0.1',
      'port': ports[i],
      'protocol': 'http',
      'tag': 'test-in-$i',
    });
    outbounds.add({...out, 'tag': 'test-out-$i'});
    rules.add({
      'type': 'field',
      'inboundTag': ['test-in-$i'],
      'outboundTag': 'test-out-$i',
    });
  }

  return {
    'log': {'loglevel': 'warning'},
    'inbounds': inbounds,
    'outbounds': outbounds,
    'routing': {'rules': rules},
  };
}
