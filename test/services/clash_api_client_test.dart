import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/services/clash_api_client.dart';

class FakeSocket implements ClashSocket {
  FakeSocket(this.url);
  final String url;
  final ctrl = StreamController<String>();
  bool closed = false;

  @override
  Stream<String> get messages => ctrl.stream;

  @override
  Future<void> close() async {
    closed = true;
    await ctrl.close();
  }
}

void main() {
  const creds =
      ClashApiCredentials(port: 39999, secret: 's3cret', host: '127.0.0.1');

  late List<FakeSocket> sockets;
  late ClashApiClient client;

  setUp(() {
    sockets = [];
    client = ClashApiClient(
      open: (url) async {
        final s = FakeSocket(url);
        sockets.add(s);
        return s;
      },
      retryStep: const Duration(milliseconds: 1),
    );
  });

  tearDown(() async => client.dispose());

  FakeSocket socketFor(String path) =>
      sockets.lastWhere((s) => s.url.contains(path));

  test('открывает /traffic и /connections с токеном', () async {
    client.start(creds);
    await Future<void>.delayed(Duration.zero);
    expect(sockets.length, 2);
    expect(socketFor('/traffic').url,
        'ws://127.0.0.1:39999/traffic?token=s3cret');
    expect(socketFor('/connections').url,
        'ws://127.0.0.1:39999/connections?token=s3cret');
  });

  test('обновляет скорости из /traffic', () async {
    client.start(creds);
    await Future<void>.delayed(Duration.zero);
    socketFor('/traffic').ctrl.add(jsonEncode({'up': 100, 'down': 200}));
    await Future<void>.delayed(Duration.zero);
    expect(client.traffic.value.upSpeed, 100);
    expect(client.traffic.value.downSpeed, 200);
  });

  test('обновляет соединения и суммы из /connections', () async {
    client.start(creds);
    await Future<void>.delayed(Duration.zero);
    socketFor('/connections').ctrl.add(jsonEncode({
          'uploadTotal': 10,
          'downloadTotal': 20,
          'connections': [
            {
              'id': 'a',
              'start': '2026-07-25T10:00:00.000Z',
              'upload': 1,
              'download': 2,
              'chains': ['direct'],
              'rule': 'final',
              'rulePayload': '',
              'metadata': {
                'network': 'tcp',
                'type': 'tls',
                'host': 'example.com',
                'destinationIP': '1.2.3.4',
                'destinationPort': '443',
                'sourceIP': '10.20.0.1',
                'sourcePort': '5000',
                'processPath': '',
              },
            }
          ],
        }));
    await Future<void>.delayed(Duration.zero);
    expect(client.connections.value.length, 1);
    expect(client.connections.value.first.title, 'example.com:443');
    expect(client.traffic.value.upTotal, 10);
    expect(client.traffic.value.downTotal, 20);
  });

  test('битый JSON игнорируется', () async {
    client.start(creds);
    await Future<void>.delayed(Duration.zero);
    socketFor('/traffic').ctrl.add('не json');
    await Future<void>.delayed(Duration.zero);
    expect(client.traffic.value.upSpeed, 0);
  });

  test('после обрыва переподключается', () async {
    client.start(creds);
    await Future<void>.delayed(Duration.zero);
    final before = sockets.length;
    await socketFor('/traffic').ctrl.close();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(sockets.length, greaterThan(before));
  });

  test('stop закрывает сокеты и обнуляет состояние', () async {
    client.start(creds);
    await Future<void>.delayed(Duration.zero);
    socketFor('/traffic').ctrl.add(jsonEncode({'up': 100, 'down': 200}));
    await Future<void>.delayed(Duration.zero);
    final opened = List<FakeSocket>.from(sockets);
    await client.stop();
    expect(opened.every((s) => s.closed), isTrue);
    expect(client.traffic.value.upSpeed, 0);
    expect(client.connections.value, isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(sockets.length, opened.length, reason: 'после stop не переподключаемся');
  });
}
