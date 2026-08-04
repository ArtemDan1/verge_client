import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/profile.dart';
import 'package:singbox_client/models/node_config.dart';
import 'package:singbox_client/models/node_engine.dart';
import 'package:singbox_client/models/subscription_meta.dart';

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

  test('override переживает замену списка нод при обновлении подписки', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.hysteria2,
      host: 'h.example', port: 443, params: {},
    );
    final p = Profile(
      id: 'p', name: 'P', url: 'u', nodes: const [node], selectedNodeIndex: 0,
    ).withEngineChoice(node, EngineChoice.singbox);

    expect(p.engineChoiceFor(node), EngineChoice.singbox);

    // Подписка обновилась: нода та же по адресу, но объект новый (имя поменялось).
    const renamed = NodeConfig(
      name: 'A (new)', protocol: NodeProtocol.hysteria2,
      host: 'h.example', port: 443, params: {},
    );
    final refreshed = p.copyWith(nodes: const [renamed]);
    expect(refreshed.engineChoiceFor(renamed), EngineChoice.singbox);
  });

  test('выбор auto удаляет запись, а не хранит её', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h', port: 443, params: {},
    );
    final p = Profile(id: 'p', name: 'P', url: 'u', nodes: const [node],
            selectedNodeIndex: 0)
        .withEngineChoice(node, EngineChoice.xray)
        .withEngineChoice(node, EngineChoice.auto);
    expect(p.engineOverrides, isEmpty);
    expect(p.engineChoiceFor(node), EngineChoice.auto);
  });

  test('engineOverrides переживают сериализацию', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h', port: 443, params: {},
    );
    final p = Profile(id: 'p', name: 'P', url: 'u', nodes: const [node],
        selectedNodeIndex: 0).withEngineChoice(node, EngineChoice.xray);
    expect(Profile.fromJson(p.toJson()).engineChoiceFor(node), EngineChoice.xray);
  });

  test('старый persisted-state без engineOverrides читается', () {
    final p = Profile.fromJson({
      'id': 'p', 'name': 'P', 'url': 'u', 'nodes': [], 'selectedNodeIndex': null,
    });
    expect(p.engineOverrides, isEmpty);
  });

  test('nameIsCustom по умолчанию false и переживает JSON', () {
    final p = Profile(
      id: '1', name: 'X', url: 'u', nodes: const [], selectedNodeIndex: null,
    );
    expect(p.nameIsCustom, false);
    expect(Profile.fromJson(p.copyWith(nameIsCustom: true).toJson()).nameIsCustom,
        true);
  });

  test('старый state без nameIsCustom читается как ручное имя', () {
    final json = {
      'id': '1', 'name': 'X', 'url': 'u', 'nodes': <dynamic>[],
      'selectedNodeIndex': null,
    };
    expect(Profile.fromJson(json).nameIsCustom, true);
  });

  test('subscriptionMeta переживает JSON', () {
    final p = Profile(
      id: '1', name: 'X', url: 'u', nodes: const [], selectedNodeIndex: null,
      subscriptionMeta: const SubscriptionMeta(title: 'T', announce: 'A'),
    );
    final round = Profile.fromJson(p.toJson());
    expect(round.subscriptionMeta?.title, 'T');
    expect(round.subscriptionMeta?.announce, 'A');
  });

  Profile profileWith({int? override, int? providerHours}) => Profile(
        id: 'p1',
        name: 'P',
        url: 'https://example.com/sub',
        nodes: const [],
        selectedNodeIndex: null,
        refreshIntervalMinutesOverride: override,
        subscriptionMeta: providerHours == null
            ? null
            : SubscriptionMeta(updateIntervalHours: providerHours),
      );

  test('оверрайд перекрывает интервал провайдера', () {
    expect(profileWith(override: 30, providerHours: 6)
        .effectiveRefreshIntervalMinutes, 30);
  });

  test('без оверрайда берётся интервал провайдера в минутах', () {
    expect(profileWith(providerHours: 6)
        .effectiveRefreshIntervalMinutes, 360);
  });

  test('без оверрайда и без провайдера автообновления нет', () {
    expect(profileWith().effectiveRefreshIntervalMinutes, isNull);
  });

  test('нулевой или отрицательный интервал провайдера игнорируется', () {
    expect(profileWith(providerHours: 0).effectiveRefreshIntervalMinutes, isNull);
    expect(profileWith(providerHours: -1).effectiveRefreshIntervalMinutes, isNull);
  });

  test('оверрайд переживает round-trip через JSON', () {
    final p = profileWith(override: 45);
    expect(Profile.fromJson(p.toJson()).refreshIntervalMinutesOverride, 45);
  });

  test('старый JSON без поля читается как отсутствие оверрайда', () {
    final json = profileWith(override: 45).toJson()
      ..remove('refreshIntervalMinutesOverride');
    expect(Profile.fromJson(json).refreshIntervalMinutesOverride, isNull);
  });

  test('clearRefreshInterval сбрасывает оверрайд в null', () {
    final p = profileWith(override: 45);
    expect(p.copyWith(clearRefreshInterval: true)
        .refreshIntervalMinutesOverride, isNull);
  });
}
