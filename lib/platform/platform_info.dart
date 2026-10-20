import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PlatformInfo {
  static const _channel = MethodChannel('singbox/tunnel');

  Future<String> singboxVersion() async =>
      (await _channel.invokeMethod<String>('singboxVersion')) ?? 'unknown';

  /// Версия бандленного Xray — второго движка (hysteria2, vless+xhttp).
  Future<String> xrayVersion() async =>
      (await _channel.invokeMethod<String>('xrayVersion')) ?? 'unknown';

  Future<List<String>> listNetworkServices() async {
    final res = await _channel.invokeMethod<List<dynamic>>('listNetworkServices');
    return (res ?? const []).map((e) => '$e').toList();
  }

  Future<String?> defaultService() async =>
      _channel.invokeMethod<String>('defaultService');

  /// ABI установленного APK (Android): «arm64-v8a», «armeabi-v7a», «x86_64».
  /// По нему ищется файл обновления в релизе.
  Future<String> deviceAbi() async =>
      (await _channel.invokeMethod<String>('deviceAbi')) ?? 'arm64-v8a';

  /// Только build-name. Build-номер не показываем: без `+N` в pubspec Flutter
  /// подставляет в него build-name (получалось «1.0.0+1.0.0»), а на сравнение
  /// версий и на имя .pkg он всё равно не влияет.
  Future<String> appVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// Открывает скачанный .pkg в Installer.app и завершает текущий процесс:
  /// установщик перезапишет бандл в /Applications и перезагрузит демона, а
  /// работающая поверх этого старая копия ловит SIGKILL по невалидной подписи
  /// и оставляет висеть системные DNS/прокси.
  ///
  /// На Android открывает системный установщик APK; приложение не закрывает —
  /// пакет заменит сама система.
  Future<void> installUpdate(String path) =>
      _channel.invokeMethod('installUpdate', path);
}
