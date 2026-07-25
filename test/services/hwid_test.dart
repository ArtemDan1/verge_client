import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/services/hwid.dart';
import 'package:singbox_client/storage/state_repository.dart';

void main() {
  test('генерирует и персистит hwid при пустом стейте', () async {
    final repo = InMemoryStateRepository();
    final hwid = await resolveHwid(repo);
    expect(hwid, isNotEmpty);
    expect((await repo.load()).hwid, hwid);
  });

  test('возвращает существующий hwid без перегенерации', () async {
    final repo = InMemoryStateRepository();
    final first = await resolveHwid(repo);
    final second = await resolveHwid(repo);
    expect(second, first);
  });
}
