/// Конвертация Xray-outbound в sing-box-outbound. Вынесено из
/// xray_config_parser, чтобы конвертация происходила при СБОРКЕ конфига, а не
/// при парсинге: ноды теперь хранят оригинальный outbound, из которого можно
/// собрать обе формы — sing-box и Xray.
library;

/// Конвертирует один Xray-outbound в sing-box-outbound (tag всегда `proxy`).
/// Возвращает `null` для неподдерживаемого протокола.
Map<String, dynamic>? xrayOutboundToSingbox(Map<String, dynamic> o) {
  final protocol = o['protocol'] as String?;
  final settings = (o['settings'] as Map?)?.cast<String, dynamic>() ?? const {};
  final stream =
      (o['streamSettings'] as Map?)?.cast<String, dynamic>() ?? const {};

  switch (protocol) {
    case 'hysteria':
    case 'hysteria2':
      return _hysteria2(settings, stream);
    case 'vless':
      return _vless(settings, stream);
    case 'trojan':
      return _trojan(settings, stream);
    case 'shadowsocks':
      return _shadowsocks(settings);
    default:
      return null;
  }
}

Map<String, dynamic>? _hysteria2(
    Map<String, dynamic> settings, Map<String, dynamic> stream) {
  final hy = (stream['hysteriaSettings'] as Map?)?.cast<String, dynamic>() ??
      const {};
  final server = settings['address'] as String?;
  final port = (settings['port'] as num?)?.toInt();
  if (server == null || port == null) return null;
  return {
    'type': 'hysteria2',
    'tag': 'proxy',
    'server': server,
    'server_port': port,
    'password': hy['auth'] ?? settings['auth'] ?? '',
    'tls': _tls(stream, fallbackSni: server),
  };
}

Map<String, dynamic>? _vless(
    Map<String, dynamic> settings, Map<String, dynamic> stream) {
  final vnext = (settings['vnext'] as List?)
      ?.whereType<Map>()
      .firstOrNull
      ?.cast<String, dynamic>();
  if (vnext == null) return null;
  final user = (vnext['users'] as List?)
      ?.whereType<Map>()
      .firstOrNull
      ?.cast<String, dynamic>();
  final server = vnext['address'] as String?;
  final port = (vnext['port'] as num?)?.toInt();
  if (server == null || port == null) return null;
  final out = <String, dynamic>{
    'type': 'vless',
    'tag': 'proxy',
    'server': server,
    'server_port': port,
    'uuid': user?['id'] ?? '',
    'tls': _tls(stream, fallbackSni: server),
  };
  final flow = user?['flow'] as String?;
  if (flow != null && flow.isNotEmpty) out['flow'] = flow;
  final transport = _transport(stream);
  if (transport != null) out['transport'] = transport;
  return out;
}

Map<String, dynamic>? _trojan(
    Map<String, dynamic> settings, Map<String, dynamic> stream) {
  final srv = (settings['servers'] as List?)
      ?.whereType<Map>()
      .firstOrNull
      ?.cast<String, dynamic>();
  if (srv == null) return null;
  final server = srv['address'] as String?;
  final port = (srv['port'] as num?)?.toInt();
  if (server == null || port == null) return null;
  return {
    'type': 'trojan',
    'tag': 'proxy',
    'server': server,
    'server_port': port,
    'password': srv['password'] ?? '',
    'tls': _tls(stream, fallbackSni: server),
  };
}

Map<String, dynamic>? _shadowsocks(Map<String, dynamic> settings) {
  final srv = (settings['servers'] as List?)
      ?.whereType<Map>()
      .firstOrNull
      ?.cast<String, dynamic>();
  if (srv == null) return null;
  final server = srv['address'] as String?;
  final port = (srv['port'] as num?)?.toInt();
  if (server == null || port == null) return null;
  return {
    'type': 'shadowsocks',
    'tag': 'proxy',
    'server': server,
    'server_port': port,
    'method': srv['method'] ?? 'aes-256-gcm',
    'password': srv['password'] ?? '',
  };
}

/// Собирает sing-box TLS-блок из Xray streamSettings.
Map<String, dynamic> _tls(Map<String, dynamic> stream,
    {required String fallbackSni}) {
  final tlsSettings =
      (stream['tlsSettings'] as Map?)?.cast<String, dynamic>() ?? const {};
  final reality = (stream['realitySettings'] as Map?)?.cast<String, dynamic>();
  final security = stream['security'] as String?;

  final tls = <String, dynamic>{
    'enabled': true,
    'server_name': tlsSettings['serverName'] ?? fallbackSni,
  };
  final alpn = tlsSettings['alpn'];
  if (alpn is List && alpn.isNotEmpty) tls['alpn'] = alpn;
  if (tlsSettings['allowInsecure'] == true) tls['insecure'] = true;

  final fp = tlsSettings['fingerprint'] as String? ??
      reality?['fingerprint'] as String?;
  if (fp != null && fp.isNotEmpty) {
    tls['utls'] = {'enabled': true, 'fingerprint': fp};
  }

  if (security == 'reality' && reality != null) {
    tls['server_name'] = reality['serverName'] ?? tls['server_name'];
    tls['reality'] = {
      'enabled': true,
      'public_key': reality['publicKey'] ?? '',
      'short_id': reality['shortId'] ?? '',
    };
  }
  return tls;
}

/// Конвертирует ws/grpc транспорт из Xray streamSettings (для vless/vmess).
Map<String, dynamic>? _transport(Map<String, dynamic> stream) {
  final network = stream['network'] as String?;
  switch (network) {
    case 'ws':
      final ws =
          (stream['wsSettings'] as Map?)?.cast<String, dynamic>() ?? const {};
      final t = <String, dynamic>{'type': 'ws'};
      if (ws['path'] != null) t['path'] = ws['path'];
      final headers = (ws['headers'] as Map?)?.cast<String, dynamic>();
      final host = headers?['Host'] ?? headers?['host'];
      if (host != null) t['headers'] = {'Host': host};
      return t;
    case 'grpc':
      final grpc =
          (stream['grpcSettings'] as Map?)?.cast<String, dynamic>() ?? const {};
      return {'type': 'grpc', 'service_name': grpc['serviceName'] ?? ''};
    default:
      return null;
  }
}

extension FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
