import 'package:flutter/foundation.dart';

@immutable
class SubscriptionInfo {
  final int? upload;
  final int? download;
  final int? total; // null/0 трактуем как безлимит при выводе
  final DateTime? expire;

  const SubscriptionInfo({this.upload, this.download, this.total, this.expire});

  int? get used {
    if (upload == null && download == null) return null;
    return (upload ?? 0) + (download ?? 0);
  }

  int? get remaining {
    final t = total;
    final u = used;
    if (t == null || t == 0 || u == null) return null;
    final r = t - u;
    return r < 0 ? 0 : r;
  }

  /// Парсит значение заголовка `subscription-userinfo`:
  /// `upload=..; download=..; total=..; expire=..` (байты, expire — unix-сек).
  static SubscriptionInfo? parseHeader(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final map = <String, int>{};
    for (final part in raw.split(';')) {
      final kv = part.split('=');
      if (kv.length != 2) continue;
      final key = kv[0].trim().toLowerCase();
      final val = int.tryParse(kv[1].trim());
      if (val != null) map[key] = val;
    }
    if (map.isEmpty) return null;
    final expire = map['expire'];
    return SubscriptionInfo(
      upload: map['upload'],
      download: map['download'],
      total: map['total'],
      expire: (expire == null || expire == 0)
          ? null
          : DateTime.fromMillisecondsSinceEpoch(expire * 1000),
    );
  }

  Map<String, dynamic> toJson() => {
        'upload': upload,
        'download': download,
        'total': total,
        'expire': expire?.millisecondsSinceEpoch,
      };

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) =>
      SubscriptionInfo(
        upload: (json['upload'] as num?)?.toInt(),
        download: (json['download'] as num?)?.toInt(),
        total: (json['total'] as num?)?.toInt(),
        expire: json['expire'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json['expire'] as int),
      );
}
