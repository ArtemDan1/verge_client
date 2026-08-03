import 'dart:convert';
import '../models/node_config.dart';

/// Парсит подписку в формате Xray/V2Ray JSON — массив объектов, где каждый
/// элемент это полный Xray-конфиг одной ноды: `remarks` (имя) + `outbounds`
/// с outbound-ом `proxy`. Оригинальный Xray-outbound сохраняется в
/// [NodeConfig.rawOutbound] со схемой [RawSchema.xray]; конвертация в
/// sing-box-форму происходит позже, при сборке конфига.
///
/// Возвращает `null`, если текст не является Xray JSON-массивом.
List<NodeConfig>? parseXrayConfigs(String text) {
  final trimmed = text.trim();
  if (!trimmed.startsWith('[')) return null;
  final dynamic decoded;
  try {
    decoded = jsonDecode(trimmed);
  } catch (_) {
    return null;
  }
  if (decoded is! List) return null;

  final nodes = <NodeConfig>[];
  for (final entry in decoded) {
    if (entry is! Map) continue;
    final cfg = entry.cast<String, dynamic>();
    final node = _nodeFromXrayConfig(cfg);
    if (node != null) nodes.add(node);
  }
  return nodes;
}

NodeConfig? _nodeFromXrayConfig(Map<String, dynamic> cfg) {
  final outbounds = (cfg['outbounds'] as List?) ?? const [];
  final proxy = outbounds
      .whereType<Map>()
      .map((o) => o.cast<String, dynamic>())
      .where((o) => o['tag'] == 'proxy')
      .cast<Map<String, dynamic>?>()
      .firstWhere((_) => true, orElse: () => null);
  if (proxy == null) return null;

  final endpoint = _endpoint(proxy);
  if (endpoint == null) return null;

  final name = (cfg['remarks'] as String?)?.trim();
  return NodeConfig(
    name: (name?.isNotEmpty == true) ? name! : endpoint.host,
    protocol: _protocolFor(proxy['protocol'] as String?),
    host: endpoint.host,
    port: endpoint.port,
    params: const {},
    // Оригинал в схеме Xray: sing-box-форма получается конвертацией в билдере.
    rawSchema: RawSchema.xray,
    rawOutbound: proxy,
  );
}

/// Адрес сервера лежит в разных местах в зависимости от протокола.
({String host, int port})? _endpoint(Map<String, dynamic> o) {
  final settings = (o['settings'] as Map?)?.cast<String, dynamic>() ?? const {};
  Map<String, dynamic>? src;
  switch (o['protocol'] as String?) {
    case 'hysteria':
    case 'hysteria2':
      src = settings;
    case 'vless':
    case 'vmess':
      src = (settings['vnext'] as List?)
          ?.whereType<Map>().firstOrNull?.cast<String, dynamic>();
    case 'trojan':
    case 'shadowsocks':
      src = (settings['servers'] as List?)
          ?.whereType<Map>().firstOrNull?.cast<String, dynamic>();
    default:
      return null;
  }
  final host = src?['address'] as String?;
  final port = (src?['port'] as num?)?.toInt();
  if (host == null || port == null) return null;
  return (host: host, port: port);
}

NodeProtocol _protocolFor(String? protocol) => switch (protocol) {
      'hysteria' || 'hysteria2' => NodeProtocol.hysteria2,
      'naive' => NodeProtocol.naive,
      _ => NodeProtocol.vless,
    };

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
