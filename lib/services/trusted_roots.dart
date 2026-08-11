import 'dart:io';

import 'package:flutter/services.dart';

/// HTTP-клиент с бандленным набором корневых сертификатов в дополнение к
/// системному.
///
/// На Windows хранилище корней наполняется лениво: система докачивает нужный
/// корень в момент первой проверки. Если в этот момент сеть недоступна или идёт
/// через полуживой туннель, докачка не проходит, и рукопожатие валится с
/// «CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate» — при том
/// что до других хостов приложение достукивается нормально. Наблюдалось ровно
/// это: подписки качались, а проверка обновлений на api.github.com падала.
///
/// Бандл Mozilla (`assets/certs/cacert.pem`) добавляется К системным корням, а
/// не вместо них: `withTrustedRoots: true` оставляет системное хранилище в силе.
/// Проверка сертификатов при этом не ослабляется — множество доверенных корней
/// только расширяется на общепризнанные.
class TrustedRoots {
  TrustedRoots._();

  static const _asset = 'assets/certs/cacert.pem';

  static SecurityContext? _context;

  /// Контекст с бандленными корнями. Читается один раз и кешируется.
  ///
  /// Если ассет не прочитался, возвращает null — вызывающий откатывается на
  /// клиент по умолчанию. Остаться без проверки обновлений лучше, чем без
  /// приложения.
  static Future<SecurityContext?> context() async {
    if (_context != null) return _context;
    try {
      final pem = await rootBundle.load(_asset);
      final ctx = SecurityContext(withTrustedRoots: true)
        ..setTrustedCertificatesBytes(pem.buffer.asUint8List());
      _context = ctx;
      return ctx;
    } catch (_) {
      return null;
    }
  }

  /// Клиент с бандленными корнями. Вне Windows возвращает null: там системное
  /// хранилище работает предсказуемо, и трогать поведение macOS незачем.
  static Future<HttpClient?> httpClient() async {
    if (!Platform.isWindows) return null;
    final ctx = await context();
    if (ctx == null) return null;
    return HttpClient(context: ctx);
  }
}
