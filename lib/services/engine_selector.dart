import '../models/node_config.dart';
import '../models/node_engine.dart';

/// Ноды, которые sing-box либо не умеет, либо не тянет:
/// - hysteria2 — на sing-box нода не заводится;
/// - vless + xhttp — транспорта xhttp в sing-box нет вовсе;
/// - VLESS-шифрование (`encryption` ≠ none, напр. mlkem768x25519plus) —
///   в sing-box его нет, конвертер молча выкидывает поле и сервер рвёт связь;
/// - gRPC multiMode — sing-box умеет только обычный gun-режим, сервер
///   отвечает 302 на чужой путь;
/// - finalmask (фрагментация/шум Xray) — sing-box его теряет, а без маски
///   нода может не пройти DPI.
///
/// reality в правиле НЕ участвует намеренно: sing-box его умеет и на нём это
/// уже работает — переносить рабочее на новый движок незачем.
bool preferXray(NodeConfig node) =>
    node.protocol == NodeProtocol.hysteria2 ||
    (node.protocol == NodeProtocol.vless &&
        (node.transport == 'xhttp' || _needsXrayOnlyFeature(node)));

bool _needsXrayOnlyFeature(NodeConfig node) {
  final raw = node.rawOutbound;
  if (raw == null) {
    // share-ссылка
    final p = node.params;
    return _isRealEncryption(p['encryption']) ||
        (node.transport == 'grpc' && p['mode']?.toLowerCase() == 'multi');
  }
  if (node.rawSchema != RawSchema.xray) return false;
  final stream = (raw['streamSettings'] as Map?)?.cast<String, dynamic>();
  if (stream?['finalmask'] != null) return true;
  final grpc = (stream?['grpcSettings'] as Map?)?.cast<String, dynamic>();
  if (grpc?['multiMode'] == true) return true;
  final vnext = ((raw['settings'] as Map?)?['vnext'] as List?) ?? const [];
  for (final server in vnext) {
    for (final user in ((server as Map)['users'] as List?) ?? const []) {
      if (_isRealEncryption((user as Map)['encryption'] as String?)) return true;
    }
  }
  return false;
}

bool _isRealEncryption(String? e) {
  final v = e?.trim().toLowerCase();
  return v != null && v.isNotEmpty && v != 'none';
}

/// Итоговый движок: ручной выбор всегда важнее автоматики.
NodeEngine resolveEngine(NodeConfig node, EngineChoice choice) =>
    switch (choice) {
      EngineChoice.singbox => NodeEngine.singbox,
      EngineChoice.xray => NodeEngine.xray,
      EngineChoice.auto =>
        preferXray(node) ? NodeEngine.xray : NodeEngine.singbox,
    };
