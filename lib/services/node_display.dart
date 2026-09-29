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

/// Протокол и его технологии без адреса — колонка «Протокол» в списке нод.
String nodeProtocolLabel(NodeConfig node) => [
      node.displayProtocol,
      if (node.security != null) node.security!,
      if (node.transport != null) node.transport!,
    ].join(' · ');

/// Код страны из флага-emoji в начале имени ноды и имя без флага.
///
/// Подписки обычно называют ноды «🇳🇱 Amsterdam». Флаг выносим в чип с
/// буквенным кодом: так он одинаково выглядит на macOS и Windows (где своих
/// глифов флагов нет) и выравнивает имена в колонку. Без флага — `code == null`
/// и имя как есть.
({String? code, String name}) splitCountryFlag(String name) {
  final runes = name.trimLeft().runes.toList();
  bool isRegional(int r) => r >= 0x1F1E6 && r <= 0x1F1FF;
  if (runes.length < 2 || !isRegional(runes[0]) || !isRegional(runes[1])) {
    return (code: null, name: name);
  }
  final code = String.fromCharCodes(
      [runes[0] - 0x1F1E6 + 0x41, runes[1] - 0x1F1E6 + 0x41]);
  final rest = String.fromCharCodes(runes.skip(2)).trim();
  return (code: code, name: rest.isEmpty ? name : rest);
}
