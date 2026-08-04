import '../models/node_config.dart';

/// Вторая строка карточки ноды: протокол и его технологии, затем адрес.
/// Отсутствующие сегменты выпадают, разделитель — ' · '.
String nodeSubtitle(NodeConfig node) {
  final parts = <String>[node.displayProtocol];
  final security = node.security;
  if (security != null) parts.add(security);
  final transport = node.transport;
  if (transport != null) parts.add(transport);
  parts.add('${node.host}:${node.port}');
  return parts.join(' · ');
}
