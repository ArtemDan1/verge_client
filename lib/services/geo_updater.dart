import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:path/path.dart' as p;

import 'geo_catalog.dart';

/// Бинарный .srs sing-box начинается с магии "SRS".
const _srsMagic = [0x53, 0x52, 0x53];

class GeoUpdateResult {
  final int updated;
  final List<String> failed;
  const GeoUpdateResult(this.updated, this.failed);

  bool get ok => failed.isEmpty;
}

/// Скачивает свежие gee-наборы (.srs) и перезаписывает их в той же папке,
/// откуда их читает sing-box (type: local). По возможности качаем через
/// локальный прокси: прямой путь к raw.githubusercontent.com в РФ блокируется.
class GeoUpdater {
  final String dir;
  final http.Client Function(int? proxyPort) _clientFactory;

  GeoUpdater(this.dir, {http.Client Function(int? proxyPort)? clientFactory})
      : _clientFactory = clientFactory ?? _defaultClient;

  static http.Client _defaultClient(int? proxyPort) {
    if (proxyPort == null) return http.Client();
    final hc = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20)
      ..findProxy = ((_) => 'PROXY 127.0.0.1:$proxyPort');
    return IOClient(hc);
  }

  /// Обновляет все наборы каталога. Если [proxyPort] задан — трафик идёт через
  /// локальный mixed-инбаунд sing-box (нужен поднятый туннель). Запись атомарна
  /// (tmp→rename), повреждённые/пустые ответы не перезаписывают рабочий файл.
  Future<GeoUpdateResult> updateAll({int? proxyPort}) async {
    final client = _clientFactory(proxyPort);
    var updated = 0;
    final failed = <String>[];
    try {
      await Directory(dir).create(recursive: true);
      for (final cat in geoCatalog) {
        try {
          final resp = await client.get(Uri.parse(cat.srsUrl));
          final bytes = resp.bodyBytes;
          if (resp.statusCode != 200 || !_looksLikeSrs(bytes)) {
            failed.add(cat.tag);
            continue;
          }
          final tmp = File(p.join(dir, '${cat.tag}.srs.tmp'));
          await tmp.writeAsBytes(bytes, flush: true);
          await tmp.rename(p.join(dir, '${cat.tag}.srs'));
          updated++;
        } catch (_) {
          failed.add(cat.tag);
        }
      }
    } finally {
      client.close();
    }
    return GeoUpdateResult(updated, failed);
  }

  bool _looksLikeSrs(List<int> b) {
    if (b.length < _srsMagic.length) return false;
    for (var i = 0; i < _srsMagic.length; i++) {
      if (b[i] != _srsMagic[i]) return false;
    }
    return true;
  }
}
