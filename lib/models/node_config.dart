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

  /// Транспорт ноды в терминах Xray: 'xhttp', 'ws', 'grpc'. null — транспорта
  /// нет: это либо голый TCP ('tcp'/'raw' — не транспорт, а его отсутствие),
  /// либо поле не задано. Используется автовыбором движка и подписью в UI.
  String? get transport {
    final raw = rawOutbound;
    final String? value;
    if (raw != null) {
      if (rawSchema == RawSchema.xray) {
        final stream = (raw['streamSettings'] as Map?)?.cast<String, dynamic>();
        value = stream?['network'] as String?;
      } else {
        final t = (raw['transport'] as Map?)?.cast<String, dynamic>();
        value = t?['type'] as String?;
      }
    } else {
      value = params['type'];
    }
    return _meaningful(value, const {'tcp', 'raw'});
  }

  /// Реальное имя протокола для показа пользователю. Enum [protocol] для этого
  /// не годится: парсеры мапят в него всё неизвестное как vless, потому что
  /// такие ноды всё равно собираются напрямую из [rawOutbound].
  String get displayProtocol {
    final raw = rawOutbound;
    final name = raw == null
        ? null
        : (rawSchema == RawSchema.xray
            ? raw['protocol'] as String?
            : raw['type'] as String?);
    final value =
        (name == null || name.isEmpty) ? protocol.name : name.toLowerCase();
    return switch (value) {
      'hysteria' => 'hysteria2',
      'shadowsocks' => 'ss',
      _ => value,
    };
  }

  /// Слой шифрования поверх транспорта: 'reality' или 'tls'. null — ничего,
  /// в том числе явное security=none.
  String? get security {
    final raw = rawOutbound;
    if (raw == null) return _meaningful(params['security'], const {});
    if (rawSchema == RawSchema.xray) {
      final stream = (raw['streamSettings'] as Map?)?.cast<String, dynamic>();
      return _meaningful(stream?['security'] as String?, const {});
    }
    final tls = (raw['tls'] as Map?)?.cast<String, dynamic>();
    if (tls == null || tls['enabled'] != true) return null;
    final reality = (tls['reality'] as Map?)?.cast<String, dynamic>();
    return reality?['enabled'] == true ? 'reality' : 'tls';
  }

  /// Пустое значение, 'none' и перечисленные [empties] считаем отсутствием.
  static String? _meaningful(String? value, Set<String> empties) {
    final v = value?.trim().toLowerCase();
    if (v == null || v.isEmpty || v == 'none' || empties.contains(v)) {
      return null;
    }
    return v;
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
