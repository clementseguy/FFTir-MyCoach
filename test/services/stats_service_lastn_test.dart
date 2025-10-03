import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/services/stats_service.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/constants/session_constants.dart';

void main() {
  test('lastNSortedSeriesAsc returns newest on the right with ASC order', () {
    final now = DateTime.now();
    // Build 3 sessions with dates increasing and multiple series each
    final s1 = ShootingSession(
      date: now.subtract(const Duration(days: 3)),
      weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
      series: [
        Series(distance: 10, points: 10, groupSize: 30),
        Series(distance: 10, points: 11, groupSize: 29),
      ],
    );
    final s2 = ShootingSession(
      date: now.subtract(const Duration(days: 2)),
      weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
      series: [
        Series(distance: 10, points: 20, groupSize: 25),
      ],
    );
    final s3 = ShootingSession(
      date: now.subtract(const Duration(days: 1)),
      weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
      series: [
        Series(distance: 10, points: 30, groupSize: 20),
        Series(distance: 10, points: 31, groupSize: 19),
      ],
    );
    final stats = StatsService([s2, s3, s1]); // shuffled input
    final last5 = stats.lastNSortedSeriesAsc(5);
    expect(last5.length, 5);
    // Expect ASC chronological order (oldest -> newest): points should be [10,11,20,30,31]
    expect(last5.map((e)=> e.points).toList(), [10,11,20,30,31]);
    // The rightmost (last entry) is the most recent
    expect(last5.last.points, 31);
  });
}
