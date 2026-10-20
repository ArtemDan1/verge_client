import 'dart:io';

import 'package:flutter/services.dart';

import '../services/deep_link.dart';

/// Сканер QR-кода подписки. Есть только на Android: там системный сканер
/// Google (Code Scanner) — без разрешения на камеру и без своего экрана.
class QrScanner {
  const QrScanner([this._channel = const MethodChannel('verge/qr')]);

  final MethodChannel _channel;

  static bool get isSupported => Platform.isAndroid;

  /// Текст из QR или null, если пользователь закрыл сканер. Бросает
  /// [QrScanException] с понятным текстом, если сканер недоступен.
  Future<String?> scan() async {
    try {
      final raw = await _channel.invokeMethod<String>('scan');
      return raw == null ? null : normalizeScannedLink(raw);
    } on PlatformException catch (e) {
      throw QrScanException(e.message ?? 'Сканер QR недоступен');
    }
  }
}

class QrScanException implements Exception {
  const QrScanException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// QR может нести ссылку `verge://import/...` — из неё берём саму подписку.
/// Всё остальное (URL подписки, share-ссылка, JSON) отдаём как есть.
String normalizeScannedLink(String raw) {
  final text = raw.trim();
  if (text.startsWith('verge://')) {
    final req = parseVergeLink(text);
    if (req != null) return req.url;
  }
  return text;
}
