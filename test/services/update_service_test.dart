import 'dart:convert';
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

  test('выбирает ассет по заданному суффиксу', () async {
    final client = MockClient((req) async {
      return http.Response(
        jsonEncode({
          'tag_name': '2.0.0',
          'html_url': 'https://example/releases/2.0.0',
          'assets': [
            {
              'name': 'Verge-2.0.0.pkg',
              'browser_download_url': 'https://example/a.pkg'
            },
            {
              'name': 'Verge-2.0.0-setup.exe',
              'browser_download_url': 'https://example/a.exe'
            },
          ],
        }),
        200,
      );
    });
    final svc = UpdateService(client: client, assetSuffix: '-setup.exe');
    final info = await svc.checkForUpdate('1.0.0');
    expect(info!.pkgUrl, 'https://example/a.exe');
  });

  test('находит ассет с именем, которое выкладывает CI', () async {
    final client = MockClient((req) async {
      return http.Response(
        jsonEncode({
          'tag_name': '2.0.0',
          'html_url': 'https://example/releases/2.0.0',
          'assets': [
            {
              'name': 'Verge-2.0.0-setup.exe',
              'browser_download_url': 'https://example/setup.exe'
            },
            {
              'name': 'Verge-2.0.0.pkg',
              'browser_download_url': 'https://example/a.pkg'
            },
          ],
        }),
        200,
      );
    });
    final svc = UpdateService(client: client, assetSuffix: '-setup.exe');
    final info = await svc.checkForUpdate('1.0.0');
    expect(info!.pkgUrl, 'https://example/setup.exe');
  });

  test('по умолчанию на macOS берёт .pkg', () async {
    final client = MockClient((req) async {
      return http.Response(
        jsonEncode({
          'tag_name': '2.0.0',
          'html_url': 'https://example/releases/2.0.0',
          'assets': [
            {
              'name': 'Verge-2.0.0.pkg',
              'browser_download_url': 'https://example/a.pkg'
            },
          ],
        }),
        200,
      );
    });
    final svc = UpdateService(client: client);
    final info = await svc.checkForUpdate('1.0.0');
    expect(info!.pkgUrl, 'https://example/a.pkg');
  }, skip: Platform.isWindows ? 'macOS-специфичный дефолт' : false);

  test('windows-суффикс .exe находит ассет с произвольным именем', () async {
    final client = MockClient((req) async {
      return http.Response(
        jsonEncode({
          'tag_name': '1.1.0',
          'html_url': 'https://example/releases/1.1.0',
          'assets': [
            {
              'name': 'Verge_1.1.0_macos_universal.pkg',
              'browser_download_url': 'https://example/a.pkg'
            },
            {
              'name': 'Verge_1.1.0_windows_x64.exe',
              'browser_download_url': 'https://example/a.exe'
            },
          ],
        }),
        200,
      );
    });
    final svc = UpdateService(client: client, assetSuffix: '.exe');
    final info = await svc.checkForUpdate('1.0.0');
    expect(info!.pkgUrl, 'https://example/a.exe');
  });
}
