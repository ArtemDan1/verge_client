import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/profile.dart';
import 'package:singbox_client/models/node_config.dart';

void main() {
  const node = NodeConfig(name: 'n', protocol: NodeProtocol.naive, host: 'h', port: 443, params: {});

  test('JSON round-trip', () {
    const p = Profile(id: 'i', name: 'Netvisor', url: 'https://x', nodes: [node], selectedNodeIndex: 0);
    final r = Profile.fromJson(p.toJson());
    expect(r.id, 'i');
    expect(r.name, 'Netvisor');
    expect(r.url, 'https://x');
    expect(r.nodes, hasLength(1));
    expect(r.selectedNodeIndex, 0);
  });

  test('copyWith заменяет nodes и индекс', () {
    const p = Profile(id: 'i', name: 'n', url: 'u', nodes: [], selectedNodeIndex: null);
    final r = p.copyWith(nodes: [node], selectedNodeIndex: 0);
    expect(r.nodes, hasLength(1));
    expect(r.selectedNodeIndex, 0);
    expect(r.id, 'i');
  });

  test('lastRefreshedAt null по умолчанию и переживает JSON', () {
    const p = Profile(id: 'i', name: 'n', url: 'u', nodes: [], selectedNodeIndex: null);
    expect(p.lastRefreshedAt, isNull);
    final r = Profile.fromJson(p.toJson());
    expect(r.lastRefreshedAt, isNull);
  });

  test('lastRefreshedAt non-null переживает JSON round-trip', () {
    final dt = DateTime.utc(2026, 6, 4, 12, 0, 0);
    final p = Profile(id: 'i', name: 'n', url: 'u', nodes: [], selectedNodeIndex: null, lastRefreshedAt: dt);
    final r = Profile.fromJson(p.toJson());
    expect(r.lastRefreshedAt, equals(dt));
  });

  test('copyWith сохраняет lastRefreshedAt если не передан', () {
    final dt = DateTime.utc(2026, 1, 1);
    final p = Profile(id: 'i', name: 'n', url: 'u', nodes: [], selectedNodeIndex: null, lastRefreshedAt: dt);
    expect(p.copyWith(name: 'new').lastRefreshedAt, equals(dt));
  });

  test('copyWith обновляет lastRefreshedAt если передан', () {
    final dt = DateTime.utc(2026, 6, 4);
    const p = Profile(id: 'i', name: 'n', url: 'u', nodes: [], selectedNodeIndex: null);
    expect(p.copyWith(lastRefreshedAt: dt).lastRefreshedAt, equals(dt));
  });
}
