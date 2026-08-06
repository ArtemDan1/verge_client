import 'dart:io';

/// Замеряет задержку HTTP-запроса к [url]. [proxyPort] — локальный proxy-порт
/// (тот, что слушает уже запущенное ядро sing-box/xray) для режима «Proxy»;
/// null — для режима TUN, где у ядра нет mixed-inbound'а на localPort
/// (ConfigBuilder._buildTun строит только tun-in) и трафик перехватывается на
/// уровне ОС через auto_route — обычный прямой запрос уже идёт через туннель,
/// проксировать его вручную не на что и не нужно.
/// Используется и для фонового бейджа пинга активного соединения, и как
/// образец для NodeTester._defaultProbe (тестовые процессы бьют в свой
/// собственный порт, а не в боевое ядро, поэтому код там не переиспользован
/// напрямую).
Future<int?> httpProbeLatency(
  String url,
  int? proxyPort, {
  Duration timeout = const Duration(seconds: 3),
  void Function(String)? log,
}) async {
  final client = HttpClient()
    ..connectionTimeout = timeout
    ..findProxy =
        (_) => proxyPort == null ? 'DIRECT' : 'PROXY 127.0.0.1:$proxyPort';
  final sw = Stopwatch()..start();
  try {
    final req = await client.getUrl(Uri.parse(url)).timeout(timeout);
    final res = await req.close().timeout(timeout);
    sw.stop();
    await res.drain<void>();
    if (res.statusCode >= 400) {
      log?.call('порт $proxyPort: HTTP ${res.statusCode}');
      return null;
    }
    return sw.elapsedMilliseconds;
  } catch (e) {
    log?.call('порт $proxyPort: $e');
    return null;
  } finally {
    client.close(force: true);
  }
}
