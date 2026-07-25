import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/subscription_info.dart';

void main() {
  test('парсит subscription-userinfo', () {
    final info = SubscriptionInfo.parseHeader(
        'upload=100; download=200; total=1000; expire=1700000000');
    expect(info, isNotNull);
    expect(info!.upload, 100);
    expect(info.download, 200);
    expect(info.total, 1000);
    expect(info.expire, DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000));
  });

  test('expire=0 → срок отсутствует', () {
    final info = SubscriptionInfo.parseHeader('download=5; total=10; expire=0');
    expect(info!.expire, isNull);
  });

  test('null/пустой/мусор → null', () {
    expect(SubscriptionInfo.parseHeader(null), isNull);
    expect(SubscriptionInfo.parseHeader(''), isNull);
    expect(SubscriptionInfo.parseHeader('garbage'), isNull);
  });

  test('used и remaining', () {
    final info = SubscriptionInfo.parseHeader(
        'upload=3; download=7; total=100; expire=0')!;
    expect(info.used, 10);
    expect(info.remaining, 90);
  });

  test('round-trip json', () {
    final info = SubscriptionInfo.parseHeader(
        'upload=1; download=2; total=3; expire=1700000000')!;
    final back = SubscriptionInfo.fromJson(info.toJson());
    expect(back.upload, info.upload);
    expect(back.download, info.download);
    expect(back.total, info.total);
    expect(back.expire, info.expire);
  });
}
