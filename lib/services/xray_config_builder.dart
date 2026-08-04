import '../models/network_settings.dart';
import '../models/node_config.dart';
import 'xray_outbound_builder.dart';

/// Конфиг процесса Xray: один socks-inbound на loopback и один реальный
/// outbound. Роутинга, DNS и sniff здесь нет намеренно — всем этим владеет
/// sing-box, а Xray работает «глупым» нижним звеном цепочки.
///
/// null — из ноды не собирается Xray-outbound, движок для неё недоступен.
Map<String, dynamic>? buildXrayConfig(NodeConfig node,
    {required int socksPort,
    NetworkSettings network = const NetworkSettings()}) {
  final outbound = buildXrayOutbound(node, network: network);
  if (outbound == null) return null;
  return {
    'log': {'loglevel': 'warning'},
    'inbounds': [
      {
        'listen': '127.0.0.1',
        'port': socksPort,
        'protocol': 'socks',
        'tag': 'socks-in',
        // udp обязателен: hysteria2 целиком UDP, и без UDP ASSOCIATE
        // цепочка sing-box → Xray для него мертва.
        'settings': {'auth': 'noauth', 'udp': true},
      }
    ],
    'outbounds': [outbound],
  };
}
