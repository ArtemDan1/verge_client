import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/services/geo_catalog.dart';

void main() {
  test('каталог непустой, теги уникальны, url на .srs', () {
    expect(geoCatalog, isNotEmpty);
    final tags = geoCatalog.map((c) => c.tag).toList();
    expect(tags.toSet().length, tags.length, reason: 'теги должны быть уникальны');
    for (final c in geoCatalog) {
      expect(c.srsUrl, endsWith('.srs'));
      expect(c.label, isNotEmpty);
    }
  });

  test('geoCategoryByTag находит и возвращает null для неизвестного', () {
    expect(geoCategoryByTag('geosite-category-ru')?.tag, 'geosite-category-ru');
    expect(geoCategoryByTag('nope-xyz'), isNull);
  });
}
