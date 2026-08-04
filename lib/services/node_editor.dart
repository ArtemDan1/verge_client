import 'dart:convert';
import '../models/node_config.dart';

Map<String, dynamic> _map(Object? v) =>
    (v as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

/// Синтезирует sing-box outbound из params — для нод из share-ссылок, у
/// которых нет rawOutbound. Повторяет минимальный набор полей, которые
/// ConfigBuilder собирает сам при сборке рабочего конфига; здесь достаточно
/// того, что нужно для показа и редактирования в JSON-редакторе.
Map<String, dynamic> _synthesizeOutbound(NodeConfig node) {
  switch (node.protocol) {
    case NodeProtocol.vless:
      final tls = <String, dynamic>{
        'enabled': true,
        'server_name': node.params['sni'] ?? node.host,
      };
      if (node.params['fp'] != null) {
        tls['utls'] = {'enabled': true, 'fingerprint': node.params['fp']};
      }
      if (node.params['security'] == 'reality') {
        tls['reality'] = {
          'enabled': true,
          'public_key': node.params['pbk'] ?? '',
          'short_id': node.params['sid'] ?? '',
        };
      }
      final out = <String, dynamic>{
        'type': 'vless',
        'server': node.host,
        'server_port': node.port,
        'uuid': node.params['uuid'] ?? '',
        'tls': tls,
      };
      if ((node.params['flow'] ?? '').isNotEmpty) {
        out['flow'] = node.params['flow'];
      }
      return out;
    case NodeProtocol.naive:
      return {
        'type': 'naive',
        'server': node.host,
        'server_port': node.port,
        'username': node.params['username'] ?? '',
        'password': node.params['password'] ?? '',
        'tls': {'enabled': true, 'server_name': node.host},
      };
    case NodeProtocol.hysteria2:
      return {
        'type': 'hysteria2',
        'server': node.host,
        'server_port': node.port,
        'password': node.params['password'] ?? '',
        'tls': {
          'enabled': true,
          'server_name': node.params['sni'] ?? node.host,
        },
      };
  }
}

/// JSON ноды для показа в редакторе. У нод из share-ссылок rawOutbound нет,
/// только params — для них outbound синтезируется, чтобы редактор был
/// доступен для любой ноды, а не только для пришедших из raw-конфигов.
String nodeToEditableJson(NodeConfig node) {
  final raw = node.rawOutbound ?? _synthesizeOutbound(node);
  return const JsonEncoder.withIndent('  ').convert(raw);
}

/// Адрес и порт нужны только для подписи в списке нод: маршрутизацию делает
/// сам outbound. Поэтому не найденный адрес — не ошибка, а причина оставить
/// прежние значения.
({String? host, int? port}) _addressOf(
    Map<String, dynamic> out, RawSchema schema) {
  if (schema == RawSchema.singbox) {
    return (
      host: out['server'] as String?,
      port: (out['server_port'] as num?)?.toInt(),
    );
  }
  final settings = _map(out['settings']);
  final vnext = (settings['vnext'] as List?);
  if (vnext != null && vnext.isNotEmpty) {
    final first = _map(vnext.first);
    return (
      host: first['address'] as String?,
      port: (first['port'] as num?)?.toInt(),
    );
  }
  final servers = (settings['servers'] as List?);
  if (servers != null && servers.isNotEmpty) {
    final first = _map(servers.first);
    return (
      host: first['address'] as String?,
      port: (first['port'] as num?)?.toInt(),
    );
  }
  // hysteria2 и подобные держат адрес прямо в settings.
  return (
    host: settings['address'] as String?,
    port: (settings['port'] as num?)?.toInt(),
  );
}

/// Собирает NodeConfig из отредактированного JSON. Источником истины
/// становится rawOutbound: params копируются из исходной ноды как есть.
NodeConfig nodeFromJson(NodeConfig node, String name, String jsonText) {
  final decoded = jsonDecode(jsonText);
  if (decoded is! Map) {
    throw const FormatException('Ожидается JSON-объект outbound');
  }
  final out = decoded.cast<String, dynamic>();
  final schema = node.rawSchema;
  final addr = _addressOf(out, schema);
  return NodeConfig(
    name: name.trim().isEmpty ? node.name : name.trim(),
    protocol: node.protocol,
    host: addr.host ?? node.host,
    port: addr.port ?? node.port,
    params: node.params,
    rawSchema: schema,
    rawOutbound: out,
  );
}
