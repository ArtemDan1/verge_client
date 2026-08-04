import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/subscription_meta.dart';

String b64(String s) => base64.encode(utf8.encode(s));

void main() {
  test('пустые заголовки — null', () {
    expect(SubscriptionMeta.parseHeaders(const {}), isNull);
    expect(SubscriptionMeta.parseHeaders(const {'profile-title': '  '}), isNull);
  });

  test('обычные значения', () {
    final m = SubscriptionMeta.parseHeaders({
      'profile-title': 'Мой VPN',
      'announce': 'Акция до конца месяца',
      'profile-web-page-url': 'https://panel.example.com',
      'support-url': 'https://t.me/support',
      'profile-update-interval': '12',
    })!;
    expect(m.title, 'Мой VPN');
    expect(m.announce, 'Акция до конца месяца');
    expect(m.webPageUrl, 'https://panel.example.com');
    expect(m.supportUrl, 'https://t.me/support');
    expect(m.updateIntervalHours, 12);
  });

  test('префикс base64: декодируется', () {
    final m = SubscriptionMeta.parseHeaders({
      'profile-title': 'base64:${b64('Мой VPN')}',
    })!;
    expect(m.title, 'Мой VPN');
  });

  test('голый base64 декодируется', () {
    final m = SubscriptionMeta.parseHeaders({'announce': b64('Привет')})!;
    expect(m.announce, 'Привет');
  });

  test('битый base64 берётся как есть', () {
    final m = SubscriptionMeta.parseHeaders({'profile-title': 'base64:!!!'})!;
    expect(m.title, 'base64:!!!');
  });

  test('обычный текст не принимается за base64', () {
    final m = SubscriptionMeta.parseHeaders({'profile-title': 'VPN Франция'})!;
    expect(m.title, 'VPN Франция');
  });

  test('URL не принимается за base64', () {
    final m = SubscriptionMeta.parseHeaders(
        {'profile-web-page-url': 'https://panel.example.com/sub'})!;
    expect(m.webPageUrl, 'https://panel.example.com/sub');
  });

  test('support_url через подчёркивание тоже читается', () {
    final m =
        SubscriptionMeta.parseHeaders({'support_url': 'https://t.me/s'})!;
    expect(m.supportUrl, 'https://t.me/s');
  });

  test('имена заголовков регистронезависимы', () {
    final m = SubscriptionMeta.parseHeaders({'Profile-Title': 'Имя'})!;
    expect(m.title, 'Имя');
  });

  test('нечисловой profile-update-interval — null, остальное живёт', () {
    final m = SubscriptionMeta.parseHeaders(
        {'profile-title': 'X', 'profile-update-interval': 'скоро'})!;
    expect(m.updateIntervalHours, isNull);
    expect(m.title, 'X');
  });

  test('JSON round-trip', () {
    const m = SubscriptionMeta(
      title: 'Мой VPN', announce: 'Привет',
      webPageUrl: 'https://p.example.com', supportUrl: 'https://t.me/s',
      updateIntervalHours: 24,
    );
    expect(SubscriptionMeta.fromJson(m.toJson()), equals(m));
  });
}
