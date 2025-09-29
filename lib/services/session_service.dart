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
    final id = await _repo.insert(session);
    if (id >= 0) {
      session.id = id;
    }
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

  /// Convert a planned session (status 'prévue') into a realized one.
  /// Applies provided field overrides, forces date to now if not supplied.
  Future<ShootingSession> convertPlannedToRealized({
    required ShootingSession session,
    String? weapon,
    String? caliber,
    String? category,
    String? synthese,
    DateTime? forcedDate,
    List<Series>? updatedSeries,
  }) async {
    if (session.status != 'prévue') {
      throw StateError('Session ${session.id} is not planned.');
    }
    // Apply overrides in-memory
    if (weapon != null) session.weapon = weapon;
    if (caliber != null) session.caliber = caliber;
    if (category != null) session.category = category;
    if (synthese != null) session.synthese = synthese;
    if (updatedSeries != null) {
      session.series = updatedSeries;
    }
    session.status = 'réalisée';
    session.date = forcedDate ?? DateTime.now();
    await updateSession(session, preserveExistingSeriesIfEmpty: false, warnOnFallback: false);
    return session;
  }

  /// Persist a single series change in a planned session before final conversion.
  Future<void> updateSingleSeries(ShootingSession session, int seriesIndex, Series newSeries) async {
    if (seriesIndex < 0 || seriesIndex >= session.series.length) return;
    session.series[seriesIndex] = newSeries;
    // Keep status as is (likely 'prévue') during incremental updates
    await updateSession(session, preserveExistingSeriesIfEmpty: false, warnOnFallback: false);
  }

  /// Create a planned session from an Exercise definition.
  /// One empty Series is generated per consigne (or single if none).
  Future<ShootingSession> planFromExercise(Exercise exercise) async {
    final List<Series> series = [];
    final steps = exercise.consignes;
    if (steps.isEmpty) {
      series.add(Series(distance: 1, points: 0, groupSize: 0, shotCount: 1, comment: '')); // placeholder minimal série
    } else {
      for (final step in steps) {
        series.add(Series(distance: 1, points: 0, groupSize: 0, shotCount: 1, comment: step));
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
      synthese: 'Session créée à partir de ${exercise.name}',
    );
    await addSession(session);
    // Récupération post-insertion pour garantir séries présentes et id assigné
    try {
      final all = await getAllSessions();
      final match = all.where((s)=> s.exercises.contains(exercise.id)).toList();
      if (match.isNotEmpty) {
        // On choisit la plus récente (souvent la dernière insérée)
        match.sort((a,b)=> (b.id ?? 0).compareTo(a.id ?? 0));
        return match.first;
      }
    } catch (_) {}
    return session;
  }
}
