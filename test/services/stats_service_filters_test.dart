import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/services/stats_service.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/constants/session_constants.dart';

void main() {
  group('StatsService Lot C filters & ordering', () {
    test('Excludes planned sessions from all computations', () {
      final now = DateTime.now();
  // Use current date to avoid edge cases
  final inThisMonth = DateTime(now.year, now.month, now.day);
      final sessions = [
        ShootingSession(
          id: 1,
          date: inThisMonth,
          weapon: 'Pistolet', caliber: '22LR',
          status: SessionConstants.statusRealisee,
          series: [Series(distance: 10, points: 50, groupSize: 20)],
        ),
        ShootingSession(
          id: 2,
          date: now.subtract(const Duration(days: 3)),
          weapon: 'Pistolet', caliber: '22LR',
          status: SessionConstants.statusPrevue, // should be ignored
          series: [Series(distance: 10, points: 100, groupSize: 5)],
        ),
      ];
      final stats = StatsService(sessions);
      // Only realized series counted -> average points should be 50, not (50,100)
      expect(stats.averagePointsLast30Days(), 50);
      // Session count this month counts only realized
      expect(stats.sessionsCountCurrentMonth(), 1);
      // Category distribution counts only realized sessions
      final cats = stats.categoryDistribution();
      expect(cats.values.fold(0, (a,b)=> a+b), 1);
    });

    test('Strict chronological series order (by session date, then series order)', () {
      final now = DateTime.now();
      final s1 = ShootingSession(
        id: 1,
        date: now.subtract(const Duration(days: 2)),
        weapon: 'Pistolet', caliber: '22LR',
        status: SessionConstants.statusRealisee,
        series: [
          Series(distance: 10, points: 10, groupSize: 30), // first
          Series(distance: 10, points: 20, groupSize: 25), // second
        ],
      );
      final s2 = ShootingSession(
        id: 2,
        date: now.subtract(const Duration(days: 1)),
        weapon: 'Pistolet', caliber: '22LR',
        status: SessionConstants.statusRealisee,
        series: [
          Series(distance: 10, points: 30, groupSize: 22), // third
        ],
      );
      final stats = StatsService([s2, s1]); // out-of-order input
      final moving = stats.movingAveragePoints(window: 2);
      // Moving average should reflect points ordered as [10,20,30]
      expect(moving.length, 3);
      expect(moving[0], 10);
      expect(moving[1], 15); // (10+20)/2
      expect(moving[2], 25); // (20+30)/2
    });

    test('Progression: insufficient data or avgPrev=0 yields NaN', () {
      final now = DateTime.now();
      // Only 2 series -> insufficient
      final s = ShootingSession(
        id: 1,
        date: now.subtract(const Duration(days: 5)),
        weapon: 'Pistolet', caliber: '22LR',
        status: SessionConstants.statusRealisee,
        series: [
          Series(distance: 10, points: 10, groupSize: 30),
          Series(distance: 10, points: 15, groupSize: 28),
        ],
      );
      final stats1 = StatsService([s]);
      expect(stats1.progressionPercent30Days().isNaN, isTrue);

      // Previous window avg is zero -> NaN
      final prev = ShootingSession(
        id: 2,
        date: now.subtract(const Duration(days: 50)),
        weapon: 'Pistolet', caliber: '22LR',
        status: SessionConstants.statusRealisee,
        series: [Series(distance: 10, points: 0, groupSize: 20)],
      );
      final curr = ShootingSession(
        id: 3,
        date: now.subtract(const Duration(days: 5)),
        weapon: 'Pistolet', caliber: '22LR',
        status: SessionConstants.statusRealisee,
        series: [Series(distance: 10, points: 20, groupSize: 15), Series(distance: 10, points: 25, groupSize: 14), Series(distance: 10, points: 22, groupSize: 16)],
      );
      final stats2 = StatsService([prev, curr]);
      final prog = stats2.progressionPercent30Days();
      // Avec peu de données dans prev, la moyenne peut être 0 -> NaN attendu selon règle docs
      expect(prog.isNaN, isTrue);
    });
  });
}
