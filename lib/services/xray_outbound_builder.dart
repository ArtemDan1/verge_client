import '../models/node_config.dart';

/// Xray-outbound для ноды: passthrough для нод из Xray-подписки, сборка из
/// params для share-ссылок. null — из этой ноды Xray-outbound не собрать,
/// значит движок Xray для неё недоступен.
Map<String, dynamic>? buildXrayOutbound(NodeConfig node) {
  final raw = node.rawOutbound;
  if (raw != null) {
    // Оригинал уже в схеме Xray — отдаём как есть, нормализуя тег.
    if (node.rawSchema == RawSchema.xray) return {...raw, 'tag': 'proxy'};
    // Оригинал в схеме sing-box: обратной конвертации нет и не планируется.
    return null;
  }
  return switch (node.protocol) {
    NodeProtocol.hysteria2 => _hysteria2(node),
    NodeProtocol.vless => _vless(node),
    NodeProtocol.naive => null, // в Xray такого протокола нет
  };
}

Map<String, dynamic> _hysteria2(NodeConfig n) => {
      'protocol': 'hysteria',
      'tag': 'proxy',
      'settings': {'address': n.host, 'port': n.port, 'version': 2},
      'streamSettings': {
        'network': 'hysteria',
        'security': 'tls',
        'hysteriaSettings': {
          'version': 2,
          'auth': n.params['password'] ?? '',
        },
        // alpn h3 обязателен: hysteria2 живёт поверх QUIC/HTTP3, без него
        // сервер рвёт TLS-хендшейк.
        'tlsSettings': _tls(n, alpn: const ['h3']),
      },
    };

Map<String, dynamic> _vless(NodeConfig n) {
  final user = <String, dynamic>{
    'id': n.params['uuid'] ?? '',
    'encryption': 'none',
  };
  final flow = n.params['flow'];
  if (flow != null && flow.isNotEmpty) user['flow'] = flow;

  final stream = <String, dynamic>{
    'network': n.transport ?? 'tcp',
  };
  if (n.params['security'] == 'reality') {
    stream['security'] = 'reality';
    stream['realitySettings'] = {
      'serverName': n.params['sni'] ?? n.host,
      'publicKey': n.params['pbk'] ?? '',
      'shortId': n.params['sid'] ?? '',
      if ((n.params['fp'] ?? '').isNotEmpty) 'fingerprint': n.params['fp'],
    };
  } else {
    stream['security'] = 'tls';
    stream['tlsSettings'] = _tls(n);
  }
  if (n.transport == 'xhttp') {
    stream['xhttpSettings'] = {
      'path': n.params['path'] ?? '/',
      if ((n.params['mode'] ?? '').isNotEmpty) 'mode': n.params['mode'],
      if ((n.params['host'] ?? '').isNotEmpty) 'host': n.params['host'],
    };
  }

  return {
    'protocol': 'vless',
    'tag': 'proxy',
    'settings': {
      'vnext': [
        {'address': n.host, 'port': n.port, 'users': [user]}
      ]
    },
    'streamSettings': stream,
  };
}

Map<String, dynamic> _tls(NodeConfig n, {List<String>? alpn}) => {
      'serverName': n.params['sni'] ?? n.host,
      if (alpn != null) 'alpn': alpn,
      if ((n.params['fp'] ?? '').isNotEmpty) 'fingerprint': n.params['fp'],
      if (n.params['insecure'] == '1' || n.params['allowInsecure'] == '1')
        'allowInsecure': true,
    };
