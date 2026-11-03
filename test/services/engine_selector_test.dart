import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/node_config.dart';
import 'package:singbox_client/models/node_engine.dart';
import 'package:singbox_client/services/engine_selector.dart';

NodeConfig _node(NodeProtocol p, {Map<String, String> params = const {}}) =>
    NodeConfig(name: 'n', protocol: p, host: 'h', port: 443, params: params);

void main() {
  test('hysteria2 → Xray', () {
    expect(preferXray(_node(NodeProtocol.hysteria2)), isTrue);
  });

  test('vless+xhttp → Xray', () {
    expect(preferXray(_node(NodeProtocol.vless, params: {'type': 'xhttp'})), isTrue);
  });

  test('vless без xhttp → sing-box, даже с reality', () {
    // reality в правиле не участвует: sing-box его умеет, xhttp — нет.
    expect(
      preferXray(_node(NodeProtocol.vless,
          params: {'security': 'reality', 'type': 'tcp'})),
      isFalse,
    );
    expect(preferXray(_node(NodeProtocol.vless, params: {'type': 'ws'})), isFalse);
    expect(preferXray(_node(NodeProtocol.vless)), isFalse);
  });

  group('фичи Xray, которых нет в sing-box → Xray', () {
    NodeConfig xray(Map<String, dynamic> user, Map<String, dynamic> stream) =>
        NodeConfig(
          name: 'n', protocol: NodeProtocol.vless, host: 'h', port: 443,
          params: const {}, rawSchema: RawSchema.xray,
          rawOutbound: {
            'protocol': 'vless',
            'settings': {
              'vnext': [
                {'address': 'h', 'port': 443, 'users': [{'id': 'u', ...user}]}
              ]
            },
            'streamSettings': stream,
          },
        );
    const reality = {'network': 'tcp', 'security': 'reality'};

    test('VLESS-шифрование (mlkem768) в Xray JSON', () {
      expect(
          preferXray(xray({'encryption': 'mlkem768x25519plus.native.0rtt.abc'},
              reality)),
          isTrue);
    });

    test('finalmask в Xray JSON', () {
      expect(
          preferXray(xray({'encryption': 'none'}, {
            ...reality,
            'finalmask': {
              'tcp': [{'type': 'fragment'}]
            },
          })),
          isTrue);
    });

    test('gRPC multiMode в Xray JSON', () {
      expect(
          preferXray(xray({'encryption': 'none'}, {
            'network': 'grpc',
            'security': 'tls',
            'grpcSettings': {'serviceName': 's', 'multiMode': true},
          })),
          isTrue);
    });

    test('обычный reality / gRPC без multiMode остаётся на sing-box', () {
      expect(preferXray(xray({'encryption': 'none'}, reality)), isFalse);
      expect(
          preferXray(xray({'encryption': 'none'}, {
            'network': 'grpc',
            'grpcSettings': {'serviceName': 's', 'multiMode': false},
          })),
          isFalse);
    });

    test('share-ссылка: encryption и gRPC mode=multi', () {
      expect(
          preferXray(_node(NodeProtocol.vless, params: {
            'type': 'tcp', 'encryption': 'mlkem768x25519plus.native.0rtt.abc',
          })),
          isTrue);
      expect(
          preferXray(_node(NodeProtocol.vless,
              params: {'type': 'grpc', 'mode': 'multi'})),
          isTrue);
      expect(
          preferXray(_node(NodeProtocol.vless,
              params: {'type': 'grpc', 'mode': 'gun', 'encryption': 'none'})),
          isFalse);
    });
  });

  test('naive → sing-box', () {
    expect(preferXray(_node(NodeProtocol.naive)), isFalse);
  });

  test('resolveEngine уважает ручной выбор поверх автоматики', () {
    final hy = _node(NodeProtocol.hysteria2);
    expect(resolveEngine(hy, EngineChoice.auto), NodeEngine.xray);
    expect(resolveEngine(hy, EngineChoice.singbox), NodeEngine.singbox);

    final naive = _node(NodeProtocol.naive);
    expect(resolveEngine(naive, EngineChoice.auto), NodeEngine.singbox);
    expect(resolveEngine(naive, EngineChoice.xray), NodeEngine.xray);
  });
}
