import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/tunnel/xray_process.dart';

void main() {
  test('pickFreePort отдаёт свободный порт, который можно занять', () async {
    final port = await pickFreePort();
    expect(port, greaterThan(0));
    final server = await ServerSocket.bind('127.0.0.1', port);
    addTearDown(server.close);
    expect(server.port, port);
  });

  test('probeSocks: true на слушающем порту', () async {
    final server = await ServerSocket.bind('127.0.0.1', 0);
    addTearDown(server.close);
    expect(await probeSocks(server.port), isTrue);
  });

  test('probeSocks: false на закрытом порту', () async {
    final port = await pickFreePort();
    expect(await probeSocks(port), isFalse);
  });
}
