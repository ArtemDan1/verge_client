import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/network_settings.dart';

void main() {
  test('дефолты повторяют нынешний конфиг', () {
    const s = NetworkSettings();
    expect(s.ipv6Enabled, isFalse);
    expect(s.tunAddressV4, '198.18.0.1/30');
    expect(s.tunAddressV6, 'fdfe:dcba:9876::1/126');
    expect(s.tunMtu, 4064);
    expect(s.tunStack, TunStack.gvisor);
    expect(s.tunStrictRoute, isFalse);
    expect(s.tunAutoRoute, isTrue);
    expect(s.dnsHijack, isTrue);
    expect(s.proxyDnsServer, '1.1.1.1');
    expect(s.directDnsServer, '77.88.8.8');
    expect(s.tlsSkipCertVerify, isFalse);
    expect(s.tlsFragmentEnabled, isFalse);
    expect(s.tlsRecordFragment, isFalse);
    expect(s.tlsFragmentFallbackDelay, '500ms');
  });

  test('round-trip через JSON', () {
    const s = NetworkSettings(
      ipv6Enabled: true,
      tunMtu: 1500,
      tunStack: TunStack.mixed,
      tlsFragmentEnabled: true,
      tlsRecordFragment: true,
      tlsFragmentFallbackDelay: '1s',
    );
    final back = NetworkSettings.fromJson(s.toJson());
    expect(back, s);
  });

  test('пустой JSON даёт дефолты', () {
    expect(NetworkSettings.fromJson(const {}), const NetworkSettings());
  });

  test('неизвестное значение enum откатывается на дефолт', () {
    final s = NetworkSettings.fromJson(const {'tunStack': 'wireguard'});
    expect(s.tunStack, TunStack.gvisor);
  });
}
