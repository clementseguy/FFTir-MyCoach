import '../models/shooting_session.dart';

/// Abstraction layer for session persistence.
abstract class SessionRepository {
  Future<List<ShootingSession>> getAll();
  Future<int> insert(ShootingSession session);
  Future<void> update(ShootingSession session, {bool preserveExistingSeriesIfEmpty = true});
  Future<void> delete(int id);
  Future<void> clearAll();
}
