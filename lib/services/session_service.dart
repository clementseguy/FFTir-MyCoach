import '../models/shooting_session.dart';
import '../repositories/session_repository.dart';
import '../repositories/hive_session_repository.dart';
import 'logger.dart';
import '../models/exercise.dart';
import '../models/series.dart';

class SessionService {
  final SessionRepository _repo;

  SessionService({SessionRepository? repository}) : _repo = repository ?? HiveSessionRepository();

  Future<List<ShootingSession>> getAllSessions() async {
    return _repo.getAll();
  }

  Future<void> addSession(ShootingSession session) async {
    await _repo.insert(session);
  }

  Future<void> updateSession(
    ShootingSession session, {
    bool preserveExistingSeriesIfEmpty = true,
    bool warnOnFallback = true,
  }) async {
    final fallback = await _repo.update(
      session,
      preserveExistingSeriesIfEmpty: preserveExistingSeriesIfEmpty,
    );
    if (fallback && warnOnFallback) {
      AppLogger.I.warn('Session ${session.id} update used fallback (empty series ignored).');
    }
  }

  Future<void> deleteSession(int id) async {
    await _repo.delete(id);
  }

  Future<void> clearAllSessions() async {
    AppLogger.I.debug('Clearing all sessions');
    await _repo.clearAll();
  }

  /// Create a planned session from an Exercise definition.
  /// One empty Series is generated per consigne (or single if none).
  Future<ShootingSession> planFromExercise(Exercise exercise) async {
    final List<Series> series = [];
    final steps = exercise.consignes;
    if (steps.isEmpty) {
      series.add(Series(distance: 0, points: 0, groupSize: 0, comment: ''));
    } else {
      for (final step in steps) {
        series.add(Series(distance: 0, points: 0, groupSize: 0, comment: step));
      }
    }
    final session = ShootingSession(
      weapon: '',
      caliber: '',
      date: null,
      status: 'prévue',
      series: series,
      exercises: [exercise.id],
      category: 'entraînement',
    );
    await addSession(session);
    return session;
  }
}
