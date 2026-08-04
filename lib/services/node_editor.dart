import '../models/node_config.dart';

/// Плоское представление ноды для формы редактирования. Общий вид для обеих
/// схем: раскладку по конкретным ключам берёт на себя [applyDraft].
class NodeDraft {
  NodeDraft({
    required this.name,
    required this.host,
    required this.port,
    this.uuid,
    this.password,
    this.flow,
    this.sni,
    this.fingerprint,
    this.publicKey,
    this.shortId,
    this.transport,
    this.security,
    this.path,
    this.hostHeader,
  });

  String name;
  String host;
  int port;
  String? uuid;
  String? password;
  String? flow;
  String? sni;
  String? fingerprint;
  String? publicKey;
  String? shortId;
  String? transport;
  String? security;
  String? path;
  String? hostHeader;
}

Map<String, dynamic> _map(Object? v) =>
    (v as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

/// Глубокая копия — правки не должны задевать исходный outbound.
Map<String, dynamic> _deepCopy(Map<String, dynamic> src) {
  Object? copy(Object? v) {
    if (v is Map) {
      return {for (final e in v.entries) '${e.key}': copy(e.value)};
    }
    if (v is List) return v.map(copy).toList();
    return v;
  }

  return copy(src) as Map<String, dynamic>;
}

/// Пустая строка означает «удалить ключ»: пустой server_name в конфиге хуже,
/// чем его отсутствие.
void _put(Map<String, dynamic> target, String key, String? value) {
  final v = value?.trim();
  if (v == null || v.isEmpty) {
    target.remove(key);
  } else {
    target[key] = v;
  }
}

String? _str(Object? v) {
  final s = v as String?;
  return (s == null || s.isEmpty) ? null : s;
}

NodeDraft draftFromNode(NodeConfig node) {
  final raw = node.rawOutbound;
  final draft = NodeDraft(
    name: node.name,
    host: node.host,
    port: node.port,
    transport: node.transport,
    security: node.security,
  );

  if (raw == null) {
    final p = node.params;
    draft.uuid = _str(p['uuid']);
    draft.password = _str(p['password']);
    draft.flow = _str(p['flow']);
    draft.sni = _str(p['sni']);
    draft.fingerprint = _str(p['fp']);
    draft.publicKey = _str(p['pbk']);
    draft.shortId = _str(p['sid']);
    draft.path = _str(p['path']);
    draft.hostHeader = _str(p['host']);
    return draft;
  }

  if (node.rawSchema == RawSchema.xray) {
    final settings = _map(raw['settings']);
    final vnext = (settings['vnext'] as List?)?.firstOrNull;
    final server = (settings['servers'] as List?)?.firstOrNull;
    final user = vnext == null ? null : (_map(vnext)['users'] as List?)?.firstOrNull;
    if (user != null) {
      draft.uuid = _str(_map(user)['id']);
      draft.flow = _str(_map(user)['flow']);
      draft.password = _str(_map(user)['password']);
    }
    if (server != null) {
      draft.password = draft.password ?? _str(_map(server)['password']);
    }
    final stream = _map(raw['streamSettings']);
    final tlsish = stream['security'] == 'reality'
        ? _map(stream['realitySettings'])
        : _map(stream['tlsSettings']);
    draft.sni = _str(tlsish['serverName']);
    draft.fingerprint = _str(tlsish['fingerprint']);
    draft.publicKey = _str(tlsish['publicKey']);
    draft.shortId = _str(tlsish['shortId']);
    final netKey = '${stream['network']}Settings';
    final net = _map(stream[netKey]);
    draft.path = _str(net['path']);
    draft.hostHeader = _str(net['host']);
    return draft;
  }

  // sing-box
  draft.uuid = _str(raw['uuid']);
  draft.password = _str(raw['password']);
  draft.flow = _str(raw['flow']);
  final tls = _map(raw['tls']);
  draft.sni = _str(tls['server_name']);
  draft.fingerprint = _str(_map(tls['utls'])['fingerprint']);
  draft.publicKey = _str(_map(tls['reality'])['public_key']);
  draft.shortId = _str(_map(tls['reality'])['short_id']);
  final transport = _map(raw['transport']);
  draft.path = _str(transport['path']);
  draft.hostHeader = _str(transport['host']);
  return draft;
}

NodeConfig applyDraft(NodeConfig node, NodeDraft d) {
  final raw = node.rawOutbound;
  final port = d.port;
  final host = d.host.trim();

  if (raw == null) {
    final params = Map<String, String>.from(node.params);
    void put(String key, String? value) {
      final v = value?.trim();
      if (v == null || v.isEmpty) {
        params.remove(key);
      } else {
        params[key] = v;
      }
    }

    put('uuid', d.uuid);
    put('password', d.password);
    put('flow', d.flow);
    put('sni', d.sni);
    put('fp', d.fingerprint);
    put('pbk', d.publicKey);
    put('sid', d.shortId);
    put('security', d.security);
    put('type', d.transport);
    put('path', d.path);
    put('host', d.hostHeader);
    return NodeConfig(
      name: d.name.trim(),
      protocol: node.protocol,
      host: host,
      port: port,
      params: params,
      rawSchema: node.rawSchema,
    );
  }

  final out = _deepCopy(raw);

  if (node.rawSchema == RawSchema.xray) {
    final settings = _map(out['settings']);
    final vnextList = settings['vnext'] as List?;
    if (vnextList != null && vnextList.isNotEmpty) {
      final vnext = _map(vnextList.first);
      vnext['address'] = host;
      vnext['port'] = port;
      final users = vnext['users'] as List?;
      if (users != null && users.isNotEmpty) {
        final user = _map(users.first);
        _put(user, 'id', d.uuid);
        _put(user, 'flow', d.flow);
        _put(user, 'password', d.password);
        users[0] = user;
      }
      vnextList[0] = vnext;
    }
    final serverList = settings['servers'] as List?;
    if (serverList != null && serverList.isNotEmpty) {
      final server = _map(serverList.first);
      server['address'] = host;
      server['port'] = port;
      _put(server, 'password', d.password);
      serverList[0] = server;
    }
    // hysteria2 и подобные держат адрес прямо в settings.
    if (settings.containsKey('address')) {
      settings['address'] = host;
      settings['port'] = port;
    }
    out['settings'] = settings;

    final stream = _map(out['streamSettings']);
    _put(stream, 'network', d.transport ?? 'tcp');
    _put(stream, 'security', d.security);
    final tlsKey =
        d.security == 'reality' ? 'realitySettings' : 'tlsSettings';
    if (d.security != null) {
      final tlsish = _map(stream[tlsKey]);
      _put(tlsish, 'serverName', d.sni);
      _put(tlsish, 'fingerprint', d.fingerprint);
      _put(tlsish, 'publicKey', d.publicKey);
      _put(tlsish, 'shortId', d.shortId);
      stream[tlsKey] = tlsish;
    }
    final network = stream['network'] as String?;
    if (network != null && network != 'tcp') {
      final netKey = '${network}Settings';
      final net = _map(stream[netKey]);
      _put(net, 'path', d.path);
      _put(net, 'host', d.hostHeader);
      if (net.isNotEmpty) stream[netKey] = net;
    }
    out['streamSettings'] = stream;
  } else {
    out['server'] = host;
    out['server_port'] = port;
    _put(out, 'uuid', d.uuid);
    _put(out, 'password', d.password);
    _put(out, 'flow', d.flow);

    if (d.security != null) {
      final tls = _map(out['tls']);
      tls['enabled'] = true;
      _put(tls, 'server_name', d.sni);
      if (d.fingerprint != null && d.fingerprint!.isNotEmpty) {
        tls['utls'] = {'enabled': true, 'fingerprint': d.fingerprint};
      }
      if (d.security == 'reality') {
        final reality = _map(tls['reality']);
        reality['enabled'] = true;
        _put(reality, 'public_key', d.publicKey);
        _put(reality, 'short_id', d.shortId);
        tls['reality'] = reality;
      } else {
        tls.remove('reality');
      }
      out['tls'] = tls;
    } else {
      out.remove('tls');
    }

    if (d.transport != null && d.transport!.isNotEmpty) {
      final transport = _map(out['transport']);
      transport['type'] = d.transport;
      _put(transport, 'path', d.path);
      _put(transport, 'host', d.hostHeader);
      out['transport'] = transport;
    } else {
      out.remove('transport');
    }
  }

  return NodeConfig(
    name: d.name.trim(),
    protocol: node.protocol,
    host: host,
    port: port,
    params: node.params,
    rawSchema: node.rawSchema,
    rawOutbound: out,
  );
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
