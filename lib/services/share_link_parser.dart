import '../models/node_config.dart';

/// Парсит одну share-ссылку. Возвращает null для неизвестной схемы.
NodeConfig? parseShareLink(String raw) {
  final link = raw.trim();
  if (link.startsWith('vless://')) return _parseVless(link);
  if (link.startsWith('naive+https://')) return _parseNaive(link);
  if (link.startsWith('hysteria2://') || link.startsWith('hy2://')) return _parseHysteria2(link);
  return null;
}

String _name(Uri uri, String fallback) =>
    uri.fragment.isEmpty ? fallback : Uri.decodeComponent(uri.fragment);

NodeConfig _parseVless(String link) {
  final uri = Uri.parse(link);
  final params = <String, String>{
    'uuid': uri.userInfo,
    ...uri.queryParameters,
  };
  return NodeConfig(
    name: _name(uri, uri.host),
    protocol: NodeProtocol.vless,
    host: uri.host,
    port: uri.port,
    params: params,
  );
}

NodeConfig _parseNaive(String link) {
  final uri = Uri.parse(link.replaceFirst('naive+https://', 'https://'));
  final creds = uri.userInfo.split(':');
  return NodeConfig(
    name: _name(uri, uri.host),
    protocol: NodeProtocol.naive,
    host: uri.host,
    port: uri.port == 0 ? 443 : uri.port,
    params: {
      'username': creds.isNotEmpty ? Uri.decodeComponent(creds[0]) : '',
      'password': creds.length > 1 ? Uri.decodeComponent(creds[1]) : '',
    },
  );
}

NodeConfig _parseHysteria2(String link) {
  final normalized = link.replaceFirst('hy2://', 'hysteria2://');
  final uri = Uri.parse(normalized.replaceFirst('hysteria2://', 'https://'));
  return NodeConfig(
    name: _name(uri, uri.host),
    protocol: NodeProtocol.hysteria2,
    host: uri.host,
    port: uri.port == 0 ? 443 : uri.port,
    params: {
      'password': uri.userInfo.isEmpty ? '' : Uri.decodeComponent(uri.userInfo),
      ...uri.queryParameters,
    },
  );
}
