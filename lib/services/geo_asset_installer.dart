import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;

import 'geo_catalog.dart';

/// Распаковывает вшитые .srs-наборы из ассетов в writable-папку на диске,
/// откуда их читает sing-box (type: local). Папка переживает обновления
/// приложения, поэтому позже автообновление сможет перезаписывать те же файлы.
class GeoAssetInstaller {
  /// Корень, куда складываем наборы (обычно ApplicationSupportDirectory).
  final String baseDir;

  const GeoAssetInstaller(this.baseDir);

  String get dir => p.join(baseDir, 'rule-sets');

  /// Сидит недостающие наборы из ассетов и возвращает путь к папке.
  /// Существующие файлы не трогаем — их может обновлять автообновление.
  Future<String> install() async {
    final target = Directory(dir);
    await target.create(recursive: true);
    for (final cat in geoCatalog) {
      final file = File(p.join(dir, '${cat.tag}.srs'));
      if (await file.exists()) continue;
      final data = await rootBundle.load('assets/rule-sets/${cat.tag}.srs');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    return dir;
  }
}
