import 'package:flutter/foundation.dart';

@immutable
class GeoCategory {
  final String tag;
  final String label;
  final String srsUrl;
  const GeoCategory(this.tag, this.label, this.srsUrl);
}

const _geosite = 'https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set';
const _geoip = 'https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set';

// Теги и пути сверены с релиз-ветками SagerNet/sing-geosite и sing-geoip
// (rule-set). В sing-geoip есть только страновые наборы (нет сервисных
// geoip-google/telegram/private).
const List<GeoCategory> geoCatalog = [
  GeoCategory('geosite-category-ru', 'Россия (сайты)',
      '$_geosite/geosite-category-ru.srs'),
  GeoCategory('geoip-ru', 'Россия (IP)', '$_geoip/geoip-ru.srs'),
  GeoCategory('geosite-category-ads-all', 'Реклама и трекеры',
      '$_geosite/geosite-category-ads-all.srs'),
  GeoCategory('geosite-private', 'Приватные домены', '$_geosite/geosite-private.srs'),
  GeoCategory('geosite-google', 'Google', '$_geosite/geosite-google.srs'),
  GeoCategory('geosite-telegram', 'Telegram', '$_geosite/geosite-telegram.srs'),
  GeoCategory('geosite-youtube', 'YouTube', '$_geosite/geosite-youtube.srs'),
  GeoCategory('geosite-netflix', 'Netflix', '$_geosite/geosite-netflix.srs'),
  GeoCategory('geosite-openai', 'OpenAI / ChatGPT', '$_geosite/geosite-openai.srs'),
  GeoCategory('geosite-spotify', 'Spotify', '$_geosite/geosite-spotify.srs'),
  GeoCategory('geosite-meta', 'Meta (FB/Instagram)', '$_geosite/geosite-meta.srs'),
  GeoCategory('geosite-twitter', 'Twitter / X', '$_geosite/geosite-twitter.srs'),
  GeoCategory('geosite-discord', 'Discord', '$_geosite/geosite-discord.srs'),
  GeoCategory('geosite-category-porn', 'Взрослый контент',
      '$_geosite/geosite-category-porn.srs'),
  GeoCategory('geoip-cn', 'Китай (IP)', '$_geoip/geoip-cn.srs'),
  GeoCategory('geosite-cn', 'Китай (сайты)', '$_geosite/geosite-cn.srs'),
];

GeoCategory? geoCategoryByTag(String tag) {
  for (final c in geoCatalog) {
    if (c.tag == tag) return c;
  }
  return null;
}
