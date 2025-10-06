import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/repositories/session_repository.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/services/rolling_stats_service.dart';

class _InMemorySessionRepo implements SessionRepository {
  final List<ShootingSession> _sessions;
  _InMemorySessionRepo(this._sessions);

  @override
  Future<void> clearAll() async => _sessions.clear();

  @override
  Future<void> delete(int id) async => _sessions.removeWhere((s) => s.id == id);

  @override
  Future<List<ShootingSession>> getAll() async => _sessions;

  @override
  Future<int> insert(ShootingSession session) async { _sessions.add(session); return session.id ?? _sessions.length; }

  @override
  Future<bool> update(ShootingSession session, {bool preserveExistingSeriesIfEmpty = true}) async {
    final idx = _sessions.indexWhere((s) => s.id == session.id);
    if (idx >= 0) _sessions[idx] = session; else _sessions.add(session);
    return false;
  }
}

void main() {
  group('RollingStatsService', () {
    test('Empty sessions returns zeros', () async {
      final repo = _InMemorySessionRepo([]);
      final svc = RollingStatsService(repo);
      final snap = await svc.compute();
      expect(snap.avg30, 0);
      expect(snap.avg60, 0);
      expect(snap.delta, 0);
      expect(snap.sessions30, 0);
      expect(snap.sessions60, 0);
    });

    test('Basic averages 30/60 days', () async {
      final now = DateTime.now();
      final sessions = [
        ShootingSession(id: 1, date: now.subtract(const Duration(days: 10)), weapon: 'Pistolet', caliber: '22LR', series: [
          Series(distance: 10, points: 45, groupSize: 20),
          Series(distance: 10, points: 50, groupSize: 22),
        ]), // total 95
        ShootingSession(id: 2, date: now.subtract(const Duration(days: 40)), weapon: 'Pistolet', caliber: '22LR', series: [
          Series(distance: 10, points: 40, groupSize: 25),
          Series(distance: 10, points: 42, groupSize: 24),
        ]), // total 82 (in 60 window only)
      ];
      final repo = _InMemorySessionRepo(sessions);
      final svc = RollingStatsService(repo);
      final snap = await svc.compute();
      expect(snap.sessions30, 1); // only first session inside 30 days
      expect(snap.sessions60, 2); // both inside 60 days
      expect(snap.avg30, closeTo(95, 0.001));
      expect(snap.avg60, closeTo((95 + 82) / 2, 0.001));
      expect(snap.delta, closeTo(95 - ((95 + 82) / 2), 0.001));
    });
  });
}
