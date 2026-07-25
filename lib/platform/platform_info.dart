import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PlatformInfo {
  static const _channel = MethodChannel('singbox/tunnel');

  Future<String> singboxVersion() async =>
      (await _channel.invokeMethod<String>('singboxVersion')) ?? 'unknown';

  Future<List<String>> listNetworkServices() async {
    final res = await _channel.invokeMethod<List<dynamic>>('listNetworkServices');
    return (res ?? const []).map((e) => '$e').toList();
  }

  Future<String?> defaultService() async =>
      _channel.invokeMethod<String>('defaultService');

  Future<String> appVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }

  Future<void> openPath(String path) =>
      _channel.invokeMethod('openPath', path);
}
