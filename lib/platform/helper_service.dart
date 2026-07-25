import 'package:flutter/services.dart';

/// Обёртка над нативной проверкой доступности привилегированного helper-демона.
/// Демон ставится отдельным .pkg-инсталлятором (классический LaunchDaemon), а не
/// приложением. Здесь только проверка: достучались по XPC = 'enabled', иначе
/// 'notRegistered' (не установлен/не запущен).
class HelperService {
  static const _channel = MethodChannel('singbox/helper');

  Future<String> status() async =>
      (await _channel.invokeMethod<String>('status')) ?? 'notRegistered';
}
