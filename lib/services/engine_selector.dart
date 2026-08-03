import '../models/node_config.dart';
import '../models/node_engine.dart';

/// Ноды, которые sing-box либо не умеет, либо не тянет:
/// - hysteria2 — на sing-box нода не заводится;
/// - vless + xhttp — транспорта xhttp в sing-box нет вовсе.
///
/// reality в правиле НЕ участвует намеренно: sing-box его умеет и на нём это
/// уже работает — переносить рабочее на новый движок незачем.
bool preferXray(NodeConfig node) =>
    node.protocol == NodeProtocol.hysteria2 ||
    (node.protocol == NodeProtocol.vless && node.transport == 'xhttp');

/// Итоговый движок: ручной выбор всегда важнее автоматики.
NodeEngine resolveEngine(NodeConfig node, EngineChoice choice) =>
    switch (choice) {
      EngineChoice.singbox => NodeEngine.singbox,
      EngineChoice.xray => NodeEngine.xray,
      EngineChoice.auto =>
        preferXray(node) ? NodeEngine.xray : NodeEngine.singbox,
    };
