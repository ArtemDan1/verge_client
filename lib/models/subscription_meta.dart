import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Метаданные подписки из HTTP-заголовков ответа: человекочитаемое имя,
/// объявление провайдера и ссылки. Отдельно от SubscriptionInfo — трафик и
/// мета приходят разными заголовками и меняются с разной частотой.
@immutable
class SubscriptionMeta {
  final String? title;
  final String? announce;
  final String? webPageUrl;
  final String? supportUrl;

  /// Рекомендованный провайдером период обновления, часов. Сейчас только
  /// сохраняется: автообновление работает по собственному таймеру.
  final int? updateIntervalHours;

  const SubscriptionMeta({
    this.title,
    this.announce,
    this.webPageUrl,
    this.supportUrl,
    this.updateIntervalHours,
  });

  bool get isEmpty =>
      title == null &&
      announce == null &&
      webPageUrl == null &&
      supportUrl == null &&
      updateIntervalHours == null;

  static SubscriptionMeta? parseHeaders(Map<String, String> headers) {
    final lower = <String, String>{
      for (final e in headers.entries) e.key.toLowerCase(): e.value,
    };
    String? value(String name) => _decode(lower[name]);

    final meta = SubscriptionMeta(
      title: value('profile-title'),
      announce: value('announce'),
      webPageUrl: value('profile-web-page-url'),
      supportUrl: value('support-url') ?? value('support_url'),
      updateIntervalHours:
          int.tryParse(lower['profile-update-interval']?.trim() ?? ''),
    );
    return meta.isEmpty ? null : meta;
  }

  /// Панели шлюзут значения либо текстом, либо base64 — с префиксом `base64:`
  /// или без него. Битую кодировку не считаем ошибкой: берём как есть.
  static String? _decode(String? raw) {
    final v = raw?.trim();
    if (v == null || v.isEmpty) return null;
    if (v.startsWith('base64:')) {
      return _tryBase64(v.substring(7).trim()) ?? v;
    }
    return _tryBase64(v) ?? v;
  }

  static final _base64Re = RegExp(r'^[A-Za-z0-9+/=_-]+$');

  static String? _tryBase64(String v) {
    if (v.isEmpty || !_base64Re.hasMatch(v) || v.length % 4 != 0) return null;
    try {
      final decoded = utf8.decode(base64.decode(v), allowMalformed: false);
      // Управляющие символы означают, что это были не текстовые данные,
      // а совпадение с алфавитом base64 — случайность.
      if (decoded.isEmpty ||
          decoded.codeUnits.any((c) => c < 0x20 && c != 0x0a && c != 0x0d)) {
        return null;
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'announce': announce,
        'webPageUrl': webPageUrl,
        'supportUrl': supportUrl,
        'updateIntervalHours': updateIntervalHours,
      };

  factory SubscriptionMeta.fromJson(Map<String, dynamic> json) =>
      SubscriptionMeta(
        title: json['title'] as String?,
        announce: json['announce'] as String?,
        webPageUrl: json['webPageUrl'] as String?,
        supportUrl: json['supportUrl'] as String?,
        updateIntervalHours: (json['updateIntervalHours'] as num?)?.toInt(),
      );

  @override
  bool operator ==(Object other) =>
      other is SubscriptionMeta &&
      other.title == title &&
      other.announce == announce &&
      other.webPageUrl == webPageUrl &&
      other.supportUrl == supportUrl &&
      other.updateIntervalHours == updateIntervalHours;

  @override
  int get hashCode =>
      Object.hash(title, announce, webPageUrl, supportUrl, updateIntervalHours);
}
