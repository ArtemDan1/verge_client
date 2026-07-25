import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/storage/state_repository.dart';
import 'package:singbox_client/models/persisted_state.dart';
import 'package:singbox_client/models/app_settings.dart';

void main() {
  test('InMemory save→load', () async {
    final repo = InMemoryStateRepository();
    await repo.save(const PersistedState(activeProfileId: 'x'));
    expect((await repo.load()).activeProfileId, 'x');
  });

  test('File save→load на temp', () async {
    final tmp = await Directory.systemTemp.createTemp('sbtest');
    final repo = FileStateRepository(File('${tmp.path}/state.json'));
    await repo.save(const PersistedState(settings: AppSettings(localPort: 1234)));
    final loaded = await repo.load();
    expect(loaded.settings.localPort, 1234);
    await tmp.delete(recursive: true);
  });

  test('File load без файла → пустой дефолт', () async {
    final tmp = await Directory.systemTemp.createTemp('sbtest');
    final repo = FileStateRepository(File('${tmp.path}/missing.json'));
    final loaded = await repo.load();
    expect(loaded.profiles, isEmpty);
    expect(loaded.settings, const AppSettings());
    await tmp.delete(recursive: true);
  });
}
