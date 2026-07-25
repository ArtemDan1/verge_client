import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/node_config.dart';
import 'package:singbox_client/services/share_link_parser.dart';

void main() {
  test('парсит vless+reality', () {
    const link =
        'vless://11111111-1111-1111-1111-111111111111@example.com:443'
        '?security=reality&pbk=KEY&fp=chrome&sni=www.apple.com&sid=ab&flow=xtls-rprx-vision'
        '#Server%20A';
    final node = parseShareLink(link)!;
    expect(node.protocol, NodeProtocol.vless);
    expect(node.host, 'example.com');
    expect(node.port, 443);
    expect(node.name, 'Server A');
    expect(node.params['uuid'], '11111111-1111-1111-1111-111111111111');
    expect(node.params['security'], 'reality');
    expect(node.params['pbk'], 'KEY');
    expect(node.params['sni'], 'www.apple.com');
    expect(node.params['flow'], 'xtls-rprx-vision');
  });

  test('парсит naive+https', () {
    const link = 'naive+https://user:pass@example.com:443#Naive%20B';
    final node = parseShareLink(link)!;
    expect(node.protocol, NodeProtocol.naive);
    expect(node.host, 'example.com');
    expect(node.port, 443);
    expect(node.name, 'Naive B');
    expect(node.params['username'], 'user');
    expect(node.params['password'], 'pass');
  });

  test('парсит hysteria2://', () {
    const link = 'hysteria2://mypassword@example.com:443?sni=example.com&insecure=1#Hy2%20Server';
    final node = parseShareLink(link)!;
    expect(node.protocol, NodeProtocol.hysteria2);
    expect(node.host, 'example.com');
    expect(node.port, 443);
    expect(node.name, 'Hy2 Server');
    expect(node.params['password'], 'mypassword');
    expect(node.params['sni'], 'example.com');
  });

  test('парсит hy2:// сокращённую схему', () {
    const link = 'hy2://secret@hy.example.com:8443#HY2';
    final node = parseShareLink(link)!;
    expect(node.protocol, NodeProtocol.hysteria2);
    expect(node.host, 'hy.example.com');
    expect(node.port, 8443);
    expect(node.params['password'], 'secret');
  });

  test('неизвестная схема → null', () {
    expect(parseShareLink('ss://whatever'), isNull);
  });
}
