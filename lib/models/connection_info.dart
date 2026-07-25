/// Куда в итоге ушло соединение. Определяется по цепочке аутбаундов, а не по
/// тексту правила: правило может быть общим (rule_set), а тег аутбаунда всегда
/// конкретный.
enum OutboundKind { direct, proxy, block }

/// Clash API отдаёт порты строками, а не числами.
int _port(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
int _int(dynamic v) => v is int ? v : (v is num ? v.toInt() : 0);
String _str(dynamic v) => v is String ? v : '';

OutboundKind _kindOfTag(String tag) {
  final t = tag.toLowerCase();
  if (t == 'direct') return OutboundKind.direct;
  if (t == 'block' || t == 'reject') return OutboundKind.block;
  return OutboundKind.proxy;
}

class ConnectionInfo {
  const ConnectionInfo({
    required this.id,
    required this.start,
    required this.upload,
    required this.download,
    required this.network,
    required this.sniffedType,
    required this.host,
    required this.destinationIP,
    required this.destinationPort,
    required this.sourceIP,
    required this.sourcePort,
    required this.processPath,
    required this.chains,
    required this.rule,
    required this.rulePayload,
  });

  final String id;
  final DateTime start;
  final int upload;
  final int download;
  final String network;
  final String sniffedType;
  final String host;
  final String destinationIP;
  final int destinationPort;
  final String sourceIP;
  final int sourcePort;
  final String processPath;
  final List<String> chains;
  final String rule;
  final String rulePayload;

  factory ConnectionInfo.fromJson(Map<String, dynamic> json) {
    final meta = (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {};
    return ConnectionInfo(
      id: _str(json['id']),
      start: DateTime.tryParse(_str(json['start']))?.toUtc() ??
          DateTime.now().toUtc(),
      upload: _int(json['upload']),
      download: _int(json['download']),
      network: _str(meta['network']),
      sniffedType: _str(meta['type']),
      host: _str(meta['host']),
      destinationIP: _str(meta['destinationIP']),
      destinationPort: _port(meta['destinationPort']),
      sourceIP: _str(meta['sourceIP']),
      sourcePort: _port(meta['sourcePort']),
      processPath: _str(meta['processPath']),
      chains: (json['chains'] as List?)?.map((e) => '$e').toList() ?? const [],
      rule: _str(json['rule']),
      rulePayload: _str(json['rulePayload']),
    );
  }

  /// В TUN домен есть благодаря sniff; в system-proxy для не-HTTP(S) он может
  /// быть пустым — тогда показываем IP.
  String get title =>
      '${host.isNotEmpty ? host : destinationIP}:$destinationPort';

  String get source => '$sourceIP:$sourcePort';

  /// Имя приложения = имя исполняемого файла. Пусто, когда sing-box не смог
  /// определить процесс (в system-proxy он работает без root).
  String? get appName {
    if (processPath.isEmpty) return null;
    final parts = processPath.split('/').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return parts.last;
  }

  /// Clash отдаёт chains от последнего аутбаунда к первому; показываем в
  /// порядке прохождения.
  String get chainLabel => chains.reversed.join(' → ');

  OutboundKind get outboundKind {
    if (chains.isNotEmpty) return _kindOfTag(chains.first);
    return _kindOfTag(rule);
  }

  Duration durationAt(DateTime now) => now.toUtc().difference(start);
}

class TrafficStats {
  const TrafficStats({
    required this.upSpeed,
    required this.downSpeed,
    required this.upTotal,
    required this.downTotal,
  });

  final int upSpeed;
  final int downSpeed;
  final int upTotal;
  final int downTotal;

  static const zero =
      TrafficStats(upSpeed: 0, downSpeed: 0, upTotal: 0, downTotal: 0);

  /// Сообщение /traffic несёт только мгновенные скорости.
  factory TrafficStats.fromTraffic(
          Map<String, dynamic> json, TrafficStats prev) =>
      TrafficStats(
        upSpeed: _int(json['up']),
        downSpeed: _int(json['down']),
        upTotal: prev.upTotal,
        downTotal: prev.downTotal,
      );

  /// Снапшот /connections несёт суммы за сессию sing-box.
  factory TrafficStats.fromConnectionsSnapshot(
          Map<String, dynamic> json, TrafficStats prev) =>
      TrafficStats(
        upSpeed: prev.upSpeed,
        downSpeed: prev.downSpeed,
        upTotal: _int(json['uploadTotal']),
        downTotal: _int(json['downloadTotal']),
      );
}

List<ConnectionInfo> parseConnections(Map<String, dynamic> snapshot) {
  final list = snapshot['connections'] as List?;
  if (list == null) return const [];
  return [
    for (final e in list)
      ConnectionInfo.fromJson((e as Map).cast<String, dynamic>()),
  ];
}
