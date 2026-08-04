import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/node_config.dart';
import 'package:singbox_client/services/node_editor.dart';

NodeConfig singboxNode(Map<String, dynamic> raw) => NodeConfig(
      name: 'n', protocol: NodeProtocol.vless, host: 'old', port: 1,
      params: const {}, rawOutbound: raw, rawSchema: RawSchema.singbox,
    );

NodeConfig xrayNode(Map<String, dynamic> raw) => NodeConfig(
      name: 'n', protocol: NodeProtocol.vless, host: 'old', port: 1,
      params: const {}, rawOutbound: raw, rawSchema: RawSchema.xray,
    );

void main() {
  test('sing-box: host и port берутся из server/server_port', () {
    final n = nodeFromJson(
      singboxNode({'type': 'vless', 'server': 'old', 'server_port': 1}),
      'Новое имя',
      jsonEncode({'type': 'vless', 'server': 'new.example', 'server_port': 8443}),
    );
    expect(n.host, 'new.example');
    expect(n.port, 8443);
    expect(n.name, 'Новое имя');
  });

  test('xray: host и port берутся из settings.vnext[0]', () {
    final n = nodeFromJson(
      xrayNode({'protocol': 'vless'}),
      'n',
      jsonEncode({
        'protocol': 'vless',
        'settings': {
          'vnext': [
            {'address': 'v.example', 'port': 443, 'users': []}
          ]
        }
      }),
    );
    expect(n.host, 'v.example');
    expect(n.port, 443);
  });

  test('xray: host и port берутся из settings.servers[0]', () {
    final n = nodeFromJson(
      xrayNode({'protocol': 'trojan'}),
      'n',
      jsonEncode({
        'protocol': 'trojan',
        'settings': {
          'servers': [
            {'address': 's.example', 'port': 8443}
          ]
        }
      }),
    );
    expect(n.host, 's.example');
    expect(n.port, 8443);
  });

  test('xray: host и port берутся из settings.address', () {
    final n = nodeFromJson(
      xrayNode({'protocol': 'hysteria2'}),
      'n',
      jsonEncode({
        'protocol': 'hysteria2',
        'settings': {'address': 'h.example', 'port': 9443}
      }),
    );
    expect(n.host, 'h.example');
    expect(n.port, 9443);
  });

  test('без адреса в JSON сохраняются прежние host и port', () {
    final n = nodeFromJson(
      singboxNode({'type': 'vless', 'server': 'old', 'server_port': 1}),
      'n',
      jsonEncode({'type': 'vless'}),
    );
    expect(n.host, 'old');
    expect(n.port, 1);
  });

  test('неизвестные ключи outbound сохраняются без изменений', () {
    final n = nodeFromJson(
      singboxNode({'type': 'vless', 'server': 'old', 'server_port': 1}),
      'n',
      jsonEncode({
        'type': 'vless',
        'server': 'new.example',
        'server_port': 443,
        'multiplex': {'enabled': true, 'protocol': 'smux'},
      }),
    );
    expect(n.rawOutbound!['multiplex'], {'enabled': true, 'protocol': 'smux'});
  });

  test('битый JSON бросает FormatException', () {
    expect(
      () => nodeFromJson(singboxNode({'type': 'vless'}), 'n', '{"a":'),
      throwsFormatException,
    );
  });

  test('JSON-массив вместо объекта бросает FormatException', () {
    expect(
      () => nodeFromJson(singboxNode({'type': 'vless'}), 'n', '[]'),
      throwsFormatException,
    );
  });

  test('нода без rawOutbound получает синтезированный JSON', () {
    final node = NodeConfig(
      name: 'n', protocol: NodeProtocol.vless, host: 'h.example', port: 443,
      params: const {'uuid': 'u1', 'security': 'reality'},
    );
    final text = nodeToEditableJson(node);
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    expect(decoded['server'], 'h.example');
    expect(decoded['server_port'], 443);
  });

  test('nodeToEditableJson отдаёт отформатированный текст', () {
    final text = nodeToEditableJson(
      singboxNode({'type': 'vless', 'server': 'h', 'server_port': 1}),
    );
    expect(text, contains('\n  '));
  });
}
