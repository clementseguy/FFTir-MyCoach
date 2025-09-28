import '../models/shooting_session.dart';
import '../repositories/session_repository.dart';
import '../repositories/hive_session_repository.dart';
import 'logger.dart';

class SessionService {
  final SessionRepository _repo;

  SessionService({SessionRepository? repository}) : _repo = repository ?? HiveSessionRepository();

  Future<List<ShootingSession>> getAllSessions() async {
    return _repo.getAll();
  }

  Future<void> addSession(ShootingSession session) async {
    await _repo.insert(session);
  }

  Future<void> updateSession(ShootingSession session) async {
    await _repo.update(session, preserveExistingSeriesIfEmpty: true);
  }

  Future<void> deleteSession(int id) async {
    await _repo.delete(id);
  }

  Future<void> clearAllSessions() async {
    AppLogger.I.debug('Clearing all sessions');
    await _repo.clearAll();
  }
}
