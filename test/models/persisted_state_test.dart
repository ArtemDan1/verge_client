import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/persisted_state.dart';
import 'package:singbox_client/models/profile.dart';
import 'package:singbox_client/models/app_settings.dart';
import 'package:singbox_client/models/routing_profile.dart';
import 'package:singbox_client/models/routing_rule.dart';

void main() {
  test('пустой дефолт', () {
    const s = PersistedState();
    expect(s.profiles, isEmpty);
    expect(s.activeProfileId, isNull);
    expect(s.settings, const AppSettings());
  });

  test('JSON round-trip', () {
    const s = PersistedState(
      profiles: [Profile(id: 'i', name: 'n', url: 'u', nodes: [], selectedNodeIndex: null)],
      activeProfileId: 'i',
      settings: AppSettings(localPort: 1080),
    );
    final r = PersistedState.fromJson(s.toJson());
    expect(r.profiles, hasLength(1));
    expect(r.activeProfileId, 'i');
    expect(r.settings.localPort, 1080);
  });

  test('routingProfiles/activeRoutingProfileId переживают JSON round-trip', () {
    const state = PersistedState(
      routingProfiles: [
        RoutingProfile(
          id: 'r1', name: 'R', isBuiltIn: false,
          directRules: [], proxyRules: [], blockRules: [],
          finalAction: RoutingFinal.direct,
        ),
      ],
      activeRoutingProfileId: 'r1',
    );
    final back = PersistedState.fromJson(state.toJson());
    expect(back.routingProfiles, hasLength(1));
    expect(back.routingProfiles.first.id, 'r1');
    expect(back.activeRoutingProfileId, 'r1');
  });

  test('старый JSON без routing-полей → пустой список и null', () {
    final back = PersistedState.fromJson({'profiles': [], 'settings': null});
    expect(back.routingProfiles, isEmpty);
    expect(back.activeRoutingProfileId, isNull);
  });

  test('hwid переживает JSON round-trip', () {
    const s = PersistedState(hwid: 'dev-uuid-123');
    final r = PersistedState.fromJson(s.toJson());
    expect(r.hwid, 'dev-uuid-123');
  });

  test('copyWith сохраняет и обновляет hwid', () {
    const s = PersistedState(hwid: 'a');
    expect(s.copyWith().hwid, 'a');
    expect(s.copyWith(hwid: 'b').hwid, 'b');
  });

  test('старый JSON без hwid → null', () {
    final r = PersistedState.fromJson(const <String, dynamic>{});
    expect(r.hwid, isNull);
  });
}
