import 'dart:async';

import 'package:flutter/services.dart';

/// Запрос на импорт подписки, извлечённый из deep-link `verge://`.
class ImportRequest {
  final String url;
  final String name;
  const ImportRequest({required this.url, required this.name});
}

/// Парсит `verge://import/<url-encoded url>?name=<name>`.
/// Возвращает null для любой невалидной ссылки.
ImportRequest? parseVergeLink(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null) return null;
  if (uri.scheme != 'verge') return null;
  if (uri.host != 'import') return null;

  // Путь после `import/` — url-encoded ссылка на подписку.
  final encoded = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
  if (encoded.isEmpty) return null;

  final subUrl = Uri.decodeComponent(encoded);
  final sub = Uri.tryParse(subUrl);
  if (sub == null || (sub.scheme != 'http' && sub.scheme != 'https')) {
    return null;
  }
  if (sub.host.isEmpty) return null;

  final name = uri.queryParameters['name']?.trim();
  return ImportRequest(
    url: subUrl,
    name: (name != null && name.isNotEmpty) ? name : sub.host,
  );
}

/// Слушает нативный канал `app/deeplink` и отдаёт валидные запросы импорта.
class DeepLinkService {
  final MethodChannel _channel;
  final _controller = StreamController<ImportRequest>.broadcast();

  DeepLinkService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('app/deeplink');

  Stream<ImportRequest> get imports => _controller.stream;

  Future<void> init() async {
    _channel.setMethodCallHandler(_handle);
    // Холодный старт: ссылка могла прийти до готовности Flutter.
    final initial = await _channel.invokeMethod<String>('getInitialLink');
    if (initial != null) _emit(initial);
  }

  Future<dynamic> _handle(MethodCall call) async {
    if (call.method == 'onLink' && call.arguments is String) {
      _emit(call.arguments as String);
    }
    return null;
  }

  void _emit(String raw) {
    final req = parseVergeLink(raw);
    if (req != null) _controller.add(req);
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
    _controller.close();
  }
}
