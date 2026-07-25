import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/node_config.dart';
import '../models/subscription_info.dart';
import 'share_link_parser.dart';
import 'xray_config_parser.dart';

class FetchResult {
  final String body;
  final Map<String, String> headers;
  const FetchResult(this.body, this.headers);
}

typedef Fetcher = Future<FetchResult> Function(String url);

class LoadResult {
  final List<NodeConfig> nodes;
  final SubscriptionInfo? info;
  const LoadResult(this.nodes, this.info);
}

class SubscriptionException implements Exception {
  final String message;
  SubscriptionException(this.message);
  @override
  String toString() => 'SubscriptionException: $message';
}

class SubscriptionService {
  final Fetcher _fetcher;

  SubscriptionService({Fetcher? fetcher, String? hwid, http.Client? client})
      : _fetcher = fetcher ?? _defaultFetcher(hwid, client ?? http.Client());

  // Многие панели (Remnawave и др.) отдают конфиг в зависимости от User-Agent;
  // без него возвращается пустой Clash-шаблон. UA клиента на базе sing-box даёт
  // либо нативный sing-box JSON, либо Xray JSON со списком нод.
  static const _userAgent = 'v2rayNG/1.8.0';

  // Панели с HWID-привязкой (Remnawave) отдают реальный конфиг только при
  // наличии стабильного заголовка x-hwid; иначе возвращают ноды-заглушки.
  static Fetcher _defaultFetcher(String? hwid, http.Client client) {
    return (String url) async {
      // Не-HTTP ввод (вставленные share-ссылки vless://, base64, список нод)
      // обрабатываем как сам контент, без сетевого запроса.
      final scheme = Uri.tryParse(url.trim())?.scheme.toLowerCase();
      if (scheme != 'http' && scheme != 'https') {
        return FetchResult(url, const {});
      }
      final headers = <String, String>{'User-Agent': _userAgent};
      if (hwid != null && hwid.isNotEmpty) headers['x-hwid'] = hwid;
      final resp = await client.get(Uri.parse(url), headers: headers);
      if (resp.statusCode != 200) {
        throw SubscriptionException('HTTP ${resp.statusCode}');
      }
      return FetchResult(resp.body, resp.headers);
    };
  }

  // Outbound-типы, которые не являются нодами-серверами.
  static const _utilityOutbounds = {'direct', 'block', 'dns', 'selector', 'urltest'};

  Future<List<NodeConfig>> load(String url) async =>
      (await loadWithInfo(url)).nodes;

  Future<LoadResult> loadWithInfo(String url) async {
    final fetched = await _fetcher(url);
    final decoded = _maybeBase64(fetched.body.trim()).trim();
    final nodes = switch (decoded.isEmpty ? '' : decoded[0]) {
      '{' => _parseSingboxConfig(decoded),
      '[' => parseXrayConfigs(decoded) ?? const [],
      _ => _parseShareLinks(decoded),
    };
    if (nodes.isEmpty) {
      throw SubscriptionException('подписка не содержит валидных нод');
    }
    // Панели с HWID-привязкой при отсутствии/непринятии x-hwid отдают
    // ноды-заглушки с адресом 0.0.0.0 и человекочитаемым remark
    // («Превышен лимит устройств», «Приложение не поддерживается»).
    if (nodes.every((n) => n.host == '0.0.0.0')) {
      final msg = nodes.map((n) => n.name).where((n) => n.isNotEmpty).join('; ');
      throw SubscriptionException(
          msg.isEmpty ? 'подписка вернула ноды-заглушки' : msg);
    }
    final info = SubscriptionInfo.parseHeader(
        fetched.headers['subscription-userinfo']);
    return LoadResult(nodes, info);
  }

  List<NodeConfig> _parseShareLinks(String text) => const LineSplitter()
      .convert(text)
      .where((l) => l.trim().isNotEmpty)
      .map(parseShareLink)
      .whereType<NodeConfig>()
      .toList();

  /// Извлекает ноды из готового sing-box JSON-конфига (его `outbounds`).
  List<NodeConfig> _parseSingboxConfig(String text) {
    final Map<String, dynamic> cfg;
    try {
      cfg = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      throw SubscriptionException('невалидный JSON-конфиг');
    }
    final outbounds = (cfg['outbounds'] as List?) ?? const [];
    return outbounds
        .whereType<Map>()
        .map((o) => o.cast<String, dynamic>())
        .where((o) => !_utilityOutbounds.contains(o['type']))
        .where((o) => o['server'] != null)
        .map(_nodeFromOutbound)
        .toList();
  }

  NodeConfig _nodeFromOutbound(Map<String, dynamic> o) {
    final type = o['type'] as String?;
    final protocol = switch (type) {
      'naive' => NodeProtocol.naive,
      'hysteria2' => NodeProtocol.hysteria2,
      _ => NodeProtocol.vless,
    };
    return NodeConfig(
      name: (o['tag'] as String?)?.isNotEmpty == true
          ? o['tag'] as String
          : (o['server'] as String),
      protocol: protocol,
      host: o['server'] as String,
      port: (o['server_port'] as num?)?.toInt() ?? 443,
      params: const {},
      rawOutbound: o,
    );
  }

  String _maybeBase64(String body) {
    if (body.contains('://')) return body;
    try {
      return utf8.decode(base64.decode(base64.normalize(body)));
    } catch (_) {
      return body;
    }
  }
}
