import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:singbox_client/services/geo_catalog.dart';
import 'package:singbox_client/services/geo_updater.dart';

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('geo-upd'));
  tearDown(() => tmp.deleteSync(recursive: true));

  // Валидный .srs начинается с магии "SRS".
  List<int> srs(String tag) => [0x53, 0x52, 0x53, 0x01, ...tag.codeUnits];

  test('обновляет все наборы и пишет файлы на диск', () async {
    final updater = GeoUpdater(tmp.path,
        clientFactory: (_) => MockClient((req) async {
              final tag = p.basenameWithoutExtension(req.url.path);
              return http.Response.bytes(srs(tag), 200);
            }));

    final res = await updater.updateAll();

    expect(res.ok, isTrue);
    expect(res.updated, geoCatalog.length);
    final f = File(p.join(tmp.path, 'geosite-category-ru.srs'));
    expect(f.existsSync(), isTrue);
    expect(f.readAsBytesSync().sublist(0, 3), [0x53, 0x52, 0x53]);
  });

  test('пустой/битый ответ не перезаписывает существующий файл', () async {
    final keep = File(p.join(tmp.path, 'geoip-ru.srs'))
      ..writeAsBytesSync(srs('old-geoip-ru'));

    final updater = GeoUpdater(tmp.path,
        clientFactory: (_) =>
            MockClient((req) async => http.Response('not-srs', 200)));

    final res = await updater.updateAll();

    expect(res.ok, isFalse);
    expect(res.failed, hasLength(geoCatalog.length));
    // рабочий файл уцелел
    expect(keep.readAsBytesSync(), srs('old-geoip-ru'));
    // tmp-файлы не оставлены
    expect(File(p.join(tmp.path, 'geoip-ru.srs.tmp')).existsSync(), isFalse);
  });

  test('proxyPort прокидывается в фабрику клиента', () async {
    int? seen;
    final updater = GeoUpdater(tmp.path, clientFactory: (port) {
      seen = port;
      return MockClient((req) async => http.Response.bytes(srs('x'), 200));
    });

    await updater.updateAll(proxyPort: 2080);
    expect(seen, 2080);
  });
}
