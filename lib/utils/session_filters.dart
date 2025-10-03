import '../models/shooting_session.dart';
import '../constants/session_constants.dart';

/// Centralized filters for sessions used by stats across the app (Lot C - F24).
class SessionFilters {
  /// Keep only realized sessions that have a date.
  static List<ShootingSession> realizedWithDate(Iterable<ShootingSession> sessions) {
    return sessions
        .where((s) => s.status == SessionConstants.statusRealisee && s.date != null)
        .toList();
  }
}
