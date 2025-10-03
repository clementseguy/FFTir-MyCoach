import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/services/rolling_stats_service.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/repositories/session_repository.dart';
import 'package:tir_sportif/constants/session_constants.dart';

class _Repo implements SessionRepository {
  final List<ShootingSession> _s;
  _Repo(this._s);
  @override
  Future<void> clearAll() async {}
  @override
  Future<void> delete(int id) async {}
  @override
  Future<List<ShootingSession>> getAll() async => _s;
  @override
  Future<int> insert(ShootingSession session) async => 1;
  @override
  Future<bool> update(ShootingSession session, {bool preserveExistingSeriesIfEmpty = true}) async => true;
}

void main() {
  test('RollingStatsService excludes planned sessions (Lot C)', () async {
    final now = DateTime.now();
    final sReal = ShootingSession(
      id: 1,
      date: now.subtract(const Duration(days: 10)),
      weapon: 'Pistolet', caliber: '22LR',
      status: SessionConstants.statusRealisee,
      series: [Series(distance: 10, points: 50, groupSize: 20)],
    );
    final sPlan = ShootingSession(
      id: 2,
      date: now.subtract(const Duration(days: 5)),
      weapon: 'Pistolet', caliber: '22LR',
      status: SessionConstants.statusPrevue,
      series: [Series(distance: 10, points: 100, groupSize: 10)],
    );
    final svc = RollingStatsService(_Repo([sReal, sPlan]));
    final snap = await svc.compute();
    // Only realized counted: sessions30==1, avg30==50
    expect(snap.sessions30, 1);
    expect(snap.avg30, 50);
  });
}
