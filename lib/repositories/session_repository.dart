import '../models/shooting_session.dart';

/// Abstraction layer for session persistence.
abstract class SessionRepository {
  Future<List<ShootingSession>> getAll();
  Future<int> insert(ShootingSession session);
  /// Returns true if a fallback (preserving existing series) was applied instead of provided empty list.
  Future<bool> update(ShootingSession session, {bool preserveExistingSeriesIfEmpty = true});
  Future<void> delete(int id);
  Future<void> clearAll();
}
