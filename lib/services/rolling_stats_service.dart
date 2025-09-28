import '../repositories/session_repository.dart';
import 'stats_contract.dart';
import 'logger.dart';

class RollingStatsService implements RollingStatsCalculator {
  final SessionRepository _repo;
  RollingStatsService(this._repo);

  @override
  Future<RollingStatsSnapshot> compute() async {
    final sessions = await _repo.getAll();
    if (sessions.isEmpty) {
      return const RollingStatsSnapshot(
        avg30: 0,
        avg60: 0,
        delta: 0,
        sessions30: 0,
        sessions60: 0,
      );
    }
    final now = DateTime.now();
    final limit30 = now.subtract(const Duration(days: 30));
    final limit60 = now.subtract(const Duration(days: 60));

    double sum30 = 0;
    double sum60 = 0;
    int count30 = 0;
    int count60 = 0;

    for (final s in sessions) {
      final d = s.date;
      if (d == null) continue;
      // total points per session
      final totalPoints = s.series.fold<int>(0, (acc, e) => acc + e.points);
      if (d.isAfter(limit60)) {
        sum60 += totalPoints.toDouble();
        count60++;
        if (d.isAfter(limit30)) {
          sum30 += totalPoints.toDouble();
          count30++;
        }
      }
    }

  final double avg60 = count60 == 0 ? 0 : (sum60 / count60);
  final double avg30 = count30 == 0 ? 0 : (sum30 / count30);
  final double delta = avg30 - avg60;

    AppLogger.I.debug('Rolling stats: avg30=$avg30 avg60=$avg60 delta=$delta sessions30=$count30 sessions60=$count60');

    return RollingStatsSnapshot(
  avg30: avg30.toDouble(),
  avg60: avg60.toDouble(),
  delta: delta.toDouble(),
      sessions30: count30,
      sessions60: count60,
    );
  }
}
