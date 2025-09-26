import '../data/local_db_hive.dart';
import '../models/shooting_session.dart';
import '../models/series.dart';

class SessionService {
  final LocalDatabaseHive _db = LocalDatabaseHive();

  Future<List<ShootingSession>> getAllSessions() async {
    final raw = await _db.getSessionsWithSeries();
    return raw.map((e) {
      final sessionMap = e['session'];
      final seriesList = e['series'] as List<dynamic>? ?? [];
      // Convert LinkedMap to Map<String, dynamic> if needed
      final sessionMapFixed = sessionMap is Map<String, dynamic> ? sessionMap : Map<String, dynamic>.from(sessionMap);
      return ShootingSession.fromMap(sessionMapFixed)
        ..series = seriesList.map((s) => Series.fromMap(s is Map<String, dynamic> ? s : Map<String, dynamic>.from(s))).toList();
    }).toList();
  }

  Future<void> addSession(ShootingSession session) async {
    await _db.insertSession(session.toMap(), session.series.map((s) => s.toMap()).toList());
  }

  Future<void> updateSession(ShootingSession session) async {
    await _db.updateSession(session.toMap(), session.series.map((s) => s.toMap()).toList());
  }

  Future<void> deleteSession(int id) async {
    await _db.deleteSession(id);
  }

  Future<void> clearAllSessions() async {
    await _db.clearAllSessions();
  }
}
