import 'dart:convert';
import 'dart:io';
import '../models/persisted_state.dart';

abstract class StateRepository {
  Future<PersistedState> load();
  Future<void> save(PersistedState state);
}

class InMemoryStateRepository implements StateRepository {
  PersistedState _state;
  InMemoryStateRepository([this._state = const PersistedState()]);

  @override
  Future<PersistedState> load() async => _state;

  @override
  Future<void> save(PersistedState state) async => _state = state;
}

class FileStateRepository implements StateRepository {
  final File file;
  FileStateRepository(this.file);

  @override
  Future<PersistedState> load() async {
    if (!await file.exists()) return const PersistedState();
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return PersistedState.fromJson(json);
    } catch (_) {
      return const PersistedState();
    }
  }

  @override
  Future<void> save(PersistedState state) async {
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(state.toJson()));
    await tmp.rename(file.path); // атомарная замена
  }
}
