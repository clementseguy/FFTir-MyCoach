import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/services/stats_service.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/constants/session_constants.dart';

void main() {
  group('StatsService metrics', () {
    test('averages (points/group size) over last 30 days', () {
      final now = DateTime(2025, 10, 7, 12);
      final s1 = ShootingSession(
        date: now.subtract(const Duration(days: 5)),
        weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
        series: [
          Series(distance: 10, points: 10, groupSize: 30),
          Series(distance: 10, points: 20, groupSize: 20),
        ],
      );
      final s2 = ShootingSession(
        date: now.subtract(const Duration(days: 35)), // outside 30d window
        weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
        series: [Series(distance: 10, points: 100, groupSize: 5)],
      );
      final stats = StatsService([s1, s2], now: now);
      expect(stats.averagePointsLast30Days(), 15); // (10+20)/2
      expect(stats.averageGroupSizeLast30Days(), 25); // (30+20)/2
    });

    test('bestSeriesByPoints returns highest', () {
      final now = DateTime(2025, 10, 7);
      final s = ShootingSession(
        date: now.subtract(const Duration(days: 1)),
        weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
        series: [Series(distance: 10, points: 5, groupSize: 20), Series(distance: 10, points: 50, groupSize: 10)],
      );
      final stats = StatsService([s], now: now);
      expect(stats.bestSeriesByPoints()!.points, 50);
    });

    test('sessionsCountCurrentMonth counts only realized in month', () {
      final now = DateTime(2025, 10, 15);
      final inMonth = ShootingSession(
        date: DateTime(2025, 10, 1), weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
        series: [Series(distance: 10, points: 1, groupSize: 1)],
      );
      final otherMonth = ShootingSession(
        date: DateTime(2025, 9, 30), weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
        series: [Series(distance: 10, points: 1, groupSize: 1)],
      );
      final planned = ShootingSession(
        date: DateTime(2025, 10, 2), weapon: 'P', caliber: '22LR', status: SessionConstants.statusPrevue,
        series: [Series(distance: 10, points: 1, groupSize: 1)],
      );
      final stats = StatsService([inMonth, otherMonth, planned], now: now);
      expect(stats.sessionsCountCurrentMonth(), 1);
    });

    test('movingAveragePoints works for window=3', () {
      final now = DateTime(2025, 10, 7);
      final s = ShootingSession(
        date: now.subtract(const Duration(days: 2)), weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
        series: [
          Series(distance: 10, points: 10, groupSize: 30),
          Series(distance: 10, points: 20, groupSize: 25),
          Series(distance: 10, points: 30, groupSize: 20),
          Series(distance: 10, points: 40, groupSize: 15),
        ],
      );
      final stats = StatsService([s], now: now);
      final ma = stats.movingAveragePoints(window: 3);
      expect(ma, [10, 15, 20, 30]);
    });

    test('consistencyIndexLast30Days returns sane value [0,100]', () {
      final now = DateTime(2025, 10, 7);
      final s = ShootingSession(
        date: now.subtract(const Duration(days: 10)), weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
        series: [
          Series(distance: 10, points: 10, groupSize: 30),
          Series(distance: 10, points: 12, groupSize: 28),
          Series(distance: 10, points: 8, groupSize: 26),
          Series(distance: 10, points: 10, groupSize: 24),
        ],
      );
      final stats = StatsService([s], now: now);
      final ci = stats.consistencyIndexLast30Days();
      expect(ci >= 0 && ci <= 100, isTrue);
    });

    test('progressionPercent30Days computes positive when curr>prev and enough data', () {
      final now = DateTime(2025, 10, 31);
      // Previous window (31-60 days): avg 10 with 5 series
      final prev = ShootingSession(
        date: now.subtract(const Duration(days: 50)), weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
        series: List.generate(5, (i) => Series(distance: 10, points: 10, groupSize: 20)),
      );
      // Current window (0-30 days): avg 20 with 5 series
      final curr = ShootingSession(
        date: now.subtract(const Duration(days: 5)), weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
        series: List.generate(5, (i) => Series(distance: 10, points: 20, groupSize: 15)),
      );
      final stats = StatsService([prev, curr], now: now);
      final prog = stats.progressionPercent30Days();
      // Expect ~100%
      expect(prog.isNaN, isFalse);
      expect(prog > 90 && prog < 110, isTrue);
    });

    test('distanceDistribution rounds to nearest int buckets', () {
      final now = DateTime(2025, 10, 7);
      final s = ShootingSession(
        date: now.subtract(const Duration(days: 1)), weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
        series: [
          Series(distance: 10.4, points: 10, groupSize: 30), // -> 10
          Series(distance: 10.6, points: 12, groupSize: 28), // -> 11
          Series(distance: 10.5, points: 14, groupSize: 26), // -> 10 (round half up -> 11? toStringAsFixed rounds half away)
        ],
      );
      final stats = StatsService([s], now: now);
      final dist = stats.distanceDistribution(last30: false);
      final total = dist.values.fold(0, (a,b)=> a+b);
      expect(total, 3);
      expect(dist.keys.every((k)=> k == 10 || k == 11), isTrue);
    });

    test('pointBuckets builds inclusive ranges and covers all points', () {
      final now = DateTime(2025, 10, 7);
      final s = ShootingSession(
        date: now.subtract(const Duration(days: 2)), weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
        series: [
          Series(distance: 10, points: 5, groupSize: 30),
          Series(distance: 10, points: 9, groupSize: 25),
          Series(distance: 10, points: 10, groupSize: 20),
          Series(distance: 10, points: 19, groupSize: 15),
          Series(distance: 10, points: 21, groupSize: 12),
        ],
      );
      final stats = StatsService([s], now: now);
      final buckets = stats.pointBuckets(bucketSize: 10, last30: false);
      final sum = buckets.fold<int>(0, (a,b)=> a + b.count);
      expect(sum, 5);
      // First bucket [0..9] should count 2 items (5,9)
      expect(buckets.first.count, greaterThanOrEqualTo(2));
    });

    test('currentDayStreak counts consecutive days from most recent backwards', () {
      final now = DateTime(2025, 10, 7, 12);
      final s1 = ShootingSession(
        date: DateTime(2025, 10, 7), weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
        series: [Series(distance: 10, points: 10, groupSize: 20)],
      );
      final s2 = ShootingSession(
        date: DateTime(2025, 10, 6), weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
        series: [Series(distance: 10, points: 10, groupSize: 20)],
      );
      final s3 = ShootingSession(
        date: DateTime(2025, 10, 4), weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee, // gap of one day (5th missing)
        series: [Series(distance: 10, points: 10, groupSize: 20)],
      );
      final stats = StatsService([s3, s1, s2], now: now);
      expect(stats.currentDayStreak(), 2);
    });

    test('bestGroupSize returns smallest positive > 0', () {
      final now = DateTime(2025, 10, 7);
      final s = ShootingSession(
        date: now,
        weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
        series: [Series(distance: 10, points: 10, groupSize: 0), Series(distance: 10, points: 12, groupSize: 5), Series(distance: 10, points: 13, groupSize: 7)],
      );
      final stats = StatsService([s], now: now);
      expect(stats.bestGroupSize(), 5);
    });

    test('lastSeriesIsRecordPoints / Group behaves as expected', () {
      final now = DateTime(2025, 10, 7);
      final s = ShootingSession(
        date: now,
        weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
        series: [
          Series(distance: 10, points: 10, groupSize: 20),
          Series(distance: 10, points: 9, groupSize: 15),
          Series(distance: 10, points: 12, groupSize: 14),
        ],
      );
      final stats = StatsService([s], now: now);
      expect(stats.lastSeriesIsRecordPoints(), isTrue); // 12 is max vs [10,9]
      expect(stats.lastSeriesIsRecordGroup(), isTrue); // 14 < min of [20,15]
    });

    test('weekly sessions and delta', () {
      // Choose a Wednesday to have a clear week window (Mon-Sun)
      final now = DateTime(2025, 10, 8); // Wednesday
      final thisWeekMon = DateTime(2025, 10, 6);
      final prevWeekTue = DateTime(2025, 9, 30);
      final s1 = ShootingSession(date: thisWeekMon, weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee, series: [Series(distance: 10, points: 10, groupSize: 20)]);
      final s2 = ShootingSession(date: prevWeekTue, weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee, series: [Series(distance: 10, points: 10, groupSize: 20)]);
      final stats = StatsService([s1, s2], now: now);
      expect(stats.sessionsThisWeek(), 1);
      expect(stats.sessionsPreviousWeek(), 1);
      expect(stats.weeklyLoadDelta(), 0);
    });
  });
}
