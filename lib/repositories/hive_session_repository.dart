import '../data/local_db_hive.dart';
import '../models/shooting_session.dart';
import '../models/series.dart';
import 'session_repository.dart';

/// Hive-backed implementation of [SessionRepository].
class HiveSessionRepository implements SessionRepository {
  final LocalDatabaseHive _hive = LocalDatabaseHive();

  @override
  Future<void> clearAll() => _hive.clearAllSessions();

  @override
  Future<void> delete(int id) => _hive.deleteSession(id);

  @override
  Future<List<ShootingSession>> getAll() async {
    final raw = await _hive.getSessionsWithSeries();
    return raw.map((e) {
      final sessionMap = e['session'];
      final seriesList = e['series'] as List<dynamic>? ?? [];
      final sessionMapFixed = sessionMap is Map<String, dynamic> ? sessionMap : Map<String, dynamic>.from(sessionMap);
      return ShootingSession.fromMap(sessionMapFixed)
        ..series = seriesList.map((s) => Series.fromMap(s is Map<String, dynamic> ? s : Map<String, dynamic>.from(s))).toList();
    }).toList();
  }

  @override
  Future<int> insert(ShootingSession session) async {
  await _hive.insertSession(session.toMap(), session.series.map((s) => s.toMap()).toList());
  // On relit tout et prend l'id max (approx) faute d'API de retour direct.
  final all = await getAll();
  final ids = all.map((s) => s.id ?? -1).where((id) => id >= 0).toList();
  if (ids.isEmpty) return -1;
  ids.sort();
  return ids.last;
  }

  @override
  Future<bool> update(ShootingSession session, {bool preserveExistingSeriesIfEmpty = true}) async {
    final seriesMaps = session.series.map((s) => s.toMap()).toList();
    if (preserveExistingSeriesIfEmpty && (session.id != null) && seriesMaps.isEmpty) {
      final existing = await _hive.getSessionsWithSeries();
      final match = existing.firstWhere(
        (e) => (e['session']?['id'] == session.id),
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        final existingSeries = (match['series'] as List<dynamic>? ?? [])
            .map((s) => (s is Map<String, dynamic>) ? s : Map<String, dynamic>.from(s))
            .toList();
        if (existingSeries.isNotEmpty) {
          await _hive.updateSession(session.toMap(), existingSeries);
          return true; // fallback applied
        }
      }
    }
    await _hive.updateSession(session.toMap(), seriesMaps);
    return false; // no fallback
  }
}
