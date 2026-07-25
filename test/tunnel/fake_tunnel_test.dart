import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/tunnel/tunnel_controller.dart';

class FakeTunnel extends TunnelController {
  @override
  Future<void> start(Map<String, dynamic> config,
          {required int port, required String service}) async =>
      emit(TunnelStatus.connected);
  @override
  Future<void> stop() async => emit(TunnelStatus.disconnected);
}

void main() {
  test('start → connected, stop → disconnected', () async {
    final t = FakeTunnel();
    final seen = <TunnelStatus>[];
    t.statusStream.listen(seen.add);
    await t.start({}, port: 2080, service: 'Wi-Fi');
    await t.stop();
    await Future<void>.delayed(Duration.zero);
    expect(seen, [TunnelStatus.connected, TunnelStatus.disconnected]);
  });
}
