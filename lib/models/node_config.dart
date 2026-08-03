import 'package:flutter/foundation.dart';

enum NodeProtocol { vless, naive, hysteria2 }

/// В какой схеме записан [NodeConfig.rawOutbound].
enum RawSchema { singbox, xray }

@immutable
class NodeConfig {
  final String name;
  final NodeProtocol protocol;
  final String host;
  final int port;
  final Map<String, String> params;

  /// Если нода извлечена из готового JSON-конфига — здесь лежит исходный
  /// outbound целиком. Схема этого outbound'а описывается [rawSchema]: для
  /// Xray-подписок это родной Xray-outbound, для sing-box-конфигов —
  /// sing-box-outbound. ConfigBuilder конвертирует в нужную форму при сборке.
  final Map<String, dynamic>? rawOutbound;

  /// Схема, в которой записан [rawOutbound]. Оригинал хранится как есть, а в
  /// нужную форму конвертируется при сборке конфига — только так у ноды
  /// доступны ОБЕ формы, что и делает возможным фолбэк между движками.
  final RawSchema rawSchema;

  const NodeConfig({
    required this.name,
    required this.protocol,
    required this.host,
    required this.port,
    required this.params,
    this.rawOutbound,
    this.rawSchema = RawSchema.singbox,
  });

  /// Транспорт ноды в терминах Xray: 'xhttp', 'ws', 'grpc', 'hysteria'.
  /// null — транспорта нет (голый TCP). Используется автовыбором движка.
  String? get transport {
    final raw = rawOutbound;
    if (raw != null) {
      if (rawSchema == RawSchema.xray) {
        final stream = (raw['streamSettings'] as Map?)?.cast<String, dynamic>();
        return stream?['network'] as String?;
      }
      final t = (raw['transport'] as Map?)?.cast<String, dynamic>();
      return t?['type'] as String?;
    }
    final type = params['type'];
    return (type == null || type.isEmpty) ? null : type;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'protocol': protocol.name,
        'host': host,
        'port': port,
        'params': params,
        'rawOutbound': rawOutbound,
        'rawSchema': rawSchema.name,
      };

  factory NodeConfig.fromJson(Map<String, dynamic> json) => NodeConfig(
        name: json['name'] as String,
        protocol: NodeProtocol.values.byName(json['protocol'] as String),
        host: json['host'] as String,
        port: (json['port'] as num).toInt(),
        params: (json['params'] as Map).map((k, v) => MapEntry('$k', '$v')),
        rawOutbound: (json['rawOutbound'] as Map?)?.cast<String, dynamic>(),
        // Отсутствие поля = старый persisted-state, где rawOutbound хранил
        // уже сконвертированный sing-box-outbound.
        rawSchema: json['rawSchema'] == null
            ? RawSchema.singbox
            : RawSchema.values.byName(json['rawSchema'] as String),
      );

  @override
  bool operator ==(Object other) =>
      other is NodeConfig &&
      other.name == name &&
      other.protocol == protocol &&
      other.host == host &&
      other.port == port &&
      other.rawSchema == rawSchema &&
      mapEquals(other.params, params) &&
      mapEquals(other.rawOutbound, rawOutbound);

  @override
  int get hashCode => Object.hash(name, protocol, host, port, rawSchema,
      Object.hashAllUnordered(params.entries.map((e) => '${e.key}:${e.value}')),
      rawOutbound == null
          ? null
          : Object.hashAllUnordered(rawOutbound!.entries
              .map((e) => '${e.key}:${e.value}')));
}
