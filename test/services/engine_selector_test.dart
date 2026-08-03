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
