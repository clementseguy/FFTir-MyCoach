import '../data/local_db_hive.dart';
import '../models/shooting_session.dart';
import '../models/series.dart';
import 'session_repository.dart';

/// Hive-backed implementation of [SessionRepository].
class HiveSessionRepository implements SessionRepository {
  final LocalDatabaseHive _hive = LocalDatabaseHive();

  @override
  Future<void> clearAll() async {
    await _hive.clearAllSessions();
  }

  @override
  Future<void> delete(int id) async {
    await _hive.deleteSession(id);
  }

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
    // Utiliser la nouvelle API qui retourne directement l'ID
    final key = await _hive.insertSession(
      session.toMap(), 
      session.series.map((s) => s.toMap()).toList()
    );
    
    // Si key est null (erreur), retourner -1
    if (key == null) return -1;
    
    // Retourner directement la clé générée (plus besoin de relire toute la base)
    return key is int ? key : -1;
  }

  @override
  Future<bool> update(ShootingSession session, {bool preserveExistingSeriesIfEmpty = true}) async {
    final seriesMaps = session.series.map((s) => s.toMap()).toList();
    
    // Si on doit préserver les séries existantes et que la session n'a pas de séries
    if (preserveExistingSeriesIfEmpty && (session.id != null) && seriesMaps.isEmpty) {
      try {
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
            final success = await _hive.updateSession(session.toMap(), existingSeries);
            return success; // Si la mise à jour a réussi, c'est un fallback
          }
        }
      } catch (e) {
        print('Erreur lors de la récupération des séries existantes: $e');
        // En cas d'erreur, on continue avec l'update normal
      }
    }
    
    await _hive.updateSession(session.toMap(), seriesMaps);
    return false; // pas de fallback même si l'update a réussi
  }
}
