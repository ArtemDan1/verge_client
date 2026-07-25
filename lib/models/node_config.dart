import 'package:flutter/foundation.dart';

enum NodeProtocol { vless, naive, hysteria2 }

@immutable
class NodeConfig {
  final String name;
  final NodeProtocol protocol;
  final String host;
  final int port;
  final Map<String, String> params;

  /// Если нода извлечена из готового sing-box JSON-конфига — здесь лежит
  /// исходный outbound целиком. ConfigBuilder использует его как есть.
  final Map<String, dynamic>? rawOutbound;

  const NodeConfig({
    required this.name,
    required this.protocol,
    required this.host,
    required this.port,
    required this.params,
    this.rawOutbound,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'protocol': protocol.name,
        'host': host,
        'port': port,
        'params': params,
        'rawOutbound': rawOutbound,
      };

  factory NodeConfig.fromJson(Map<String, dynamic> json) => NodeConfig(
        name: json['name'] as String,
        protocol: NodeProtocol.values.byName(json['protocol'] as String),
        host: json['host'] as String,
        port: (json['port'] as num).toInt(),
        params: (json['params'] as Map).map((k, v) => MapEntry('$k', '$v')),
        rawOutbound: (json['rawOutbound'] as Map?)?.cast<String, dynamic>(),
      );

  @override
  bool operator ==(Object other) =>
      other is NodeConfig &&
      other.name == name &&
      other.protocol == protocol &&
      other.host == host &&
      other.port == port &&
      mapEquals(other.params, params);

  @override
  int get hashCode => Object.hash(name, protocol, host, port,
      Object.hashAllUnordered(params.entries.map((e) => '${e.key}:${e.value}')));
}
