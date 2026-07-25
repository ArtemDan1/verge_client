import 'package:uuid/uuid.dart';
import '../storage/state_repository.dart';

/// Возвращает стабильный per-install HWID, генерируя и сохраняя его при
/// первом обращении. Используется для заголовка `x-hwid` при запросе подписок.
Future<String> resolveHwid(StateRepository repo) async {
  final state = await repo.load();
  final existing = state.hwid;
  if (existing != null && existing.isNotEmpty) return existing;
  final hwid = const Uuid().v4();
  await repo.save(state.copyWith(hwid: hwid));
  return hwid;
}
