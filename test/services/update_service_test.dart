import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbox_client/services/update_service.dart';

void main() {
  String releaseJson(String tag, {bool withPkg = true}) => '''
  {"tag_name":"$tag","html_url":"https://gh/rel",
   "assets":[${withPkg ? '{"name":"SingboxFlutter-$tag.pkg","browser_download_url":"https://gh/x.pkg"}' : '{"name":"notes.txt","browser_download_url":"https://gh/n.txt"}'}]}''';

  test('есть новее → UpdateInfo с pkgUrl', () async {
    final svc = UpdateService(
        client: MockClient((_) async => http.Response(releaseJson('v1.0.1'), 200)));
    final info = await svc.checkForUpdate('1.0.0+1');
    expect(info, isNotNull);
    expect(info!.pkgUrl, 'https://gh/x.pkg');
    expect(info.version, 'v1.0.1');
  });

  test('та же версия → null', () async {
    final svc = UpdateService(
        client: MockClient((_) async => http.Response(releaseJson('v1.0.0'), 200)));
    expect(await svc.checkForUpdate('1.0.0+1'), isNull);
  });

  test('нет .pkg-ассета → null', () async {
    final svc = UpdateService(
        client: MockClient(
            (_) async => http.Response(releaseJson('v2.0.0', withPkg: false), 200)));
    expect(await svc.checkForUpdate('1.0.0'), isNull);
  });

  test('404 (нет релизов) → null, не ошибка', () async {
    final svc = UpdateService(
        client: MockClient((_) async => http.Response('Not Found', 404)));
    expect(await svc.checkForUpdate('1.0.0'), isNull);
  });

  test('прочий не-200 → исключение', () async {
    final svc =
        UpdateService(client: MockClient((_) async => http.Response('x', 503)));
    expect(svc.checkForUpdate('1.0.0'), throwsException);
  });

  test('downloadPkg пишет файл и зовёт прогресс', () async {
    final svc = UpdateService(
        client: MockClient((_) async => http.Response('PKGDATA', 200,
            headers: {'content-length': '7'})));
    final tmp = Directory.systemTemp.createTempSync();
    final progress = <double>[];
    final path = await svc.downloadPkg('https://gh/x.pkg',
        targetDir: tmp, onProgress: progress.add);
    expect(File(path).readAsStringSync(), 'PKGDATA');
    expect(progress.last, 1.0);
  });

  // getTemporaryDirectory() на macOS отдаёт ~/Library/Caches/<bundle-id>, но вне
  // сэндбокса эта папка не существует — без mkdir запись падает PathNotFound.
  test('downloadPkg создаёт целевую папку, если её нет', () async {
    final svc = UpdateService(
        client: MockClient((_) async => http.Response('PKGDATA', 200,
            headers: {'content-length': '7'})));
    final missing = Directory(
        '${Directory.systemTemp.createTempSync().path}/nope/deeper');
    expect(missing.existsSync(), isFalse);
    final path = await svc.downloadPkg('https://gh/x.pkg', targetDir: missing);
    expect(File(path).readAsStringSync(), 'PKGDATA');
  });
}
