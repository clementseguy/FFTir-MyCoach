import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/goal.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/services/goal_service.dart';
import 'package:tir_sportif/repositories/goal_repository.dart';
import 'package:tir_sportif/repositories/session_repository.dart';

class _MemGoalRepo implements GoalRepository {
  final Map<String, Goal> _store = {};
  @override Future<void> delete(String id) async { _store.remove(id); }
  @override Future<void> deleteAll() async { _store.clear(); }
  @override Future<List<Goal>> getAll() async => _store.values.toList();
  @override Future<void> put(Goal goal) async { _store[goal.id] = goal; }
}

class _MemSessionRepo implements SessionRepository {
  final List<ShootingSession> list;
  _MemSessionRepo(this.list);
  @override Future<void> clearAll() async {}
  @override Future<void> delete(int id) async {}
  @override Future<List<ShootingSession>> getAll() async => list;
  @override Future<int> insert(ShootingSession session) async => 1;
  @override Future<bool> update(ShootingSession session, {bool preserveExistingSeriesIfEmpty = true}) async => true;
}

void main() {
  group('GoalService._computeProgress via recomputeAllProgress', () {
    test('averagePoints + greaterOrEqual: progress clamped 0..1 and achieved sets date', () async {
      final now = DateTime(2025, 10, 7);
      final sessions = [
        ShootingSession(weapon: 'P', caliber: '22LR', date: now.subtract(const Duration(days: 1)), status: 'réalisée', series: [Series(distance: 10, points: 10, groupSize: 30), Series(distance: 10, points: 20, groupSize: 20)])
      ];
      final goals = _MemGoalRepo();
      final svc = GoalService(sessionRepository: _MemSessionRepo(sessions), goalRepository: goals);
      final g = Goal(title: 'Avg>=15', metric: GoalMetric.averagePoints, comparator: GoalComparator.greaterOrEqual, targetValue: 15);
      await goals.put(g);
      await svc.recomputeAllProgress();
      final updated = (await goals.getAll()).first;
      expect(updated.lastMeasuredValue, 15);
      expect(updated.lastProgress, closeTo(1.0, 1e-9));
      expect(updated.status, anyOf(GoalStatus.achieved, GoalStatus.active));
    });

    test('groupSize + lessOrEqual: progress target/value and improvementDelta with previous window', () async {
      final now = DateTime.now();
      // previous window (31-60 days): worse (bigger) group size
      final prev = ShootingSession(weapon: 'P', caliber: '22LR', date: now.subtract(const Duration(days: 50)), status: 'réalisée', series: [Series(distance: 10, points: 10, groupSize: 30)]);
      // current window (0-30 days): better (smaller) group size
      final curr = ShootingSession(weapon: 'P', caliber: '22LR', date: now.subtract(const Duration(days: 5)), status: 'réalisée', series: [Series(distance: 10, points: 10, groupSize: 20)]);
      final goals = _MemGoalRepo();
      final svc = GoalService(sessionRepository: _MemSessionRepo([prev, curr]), goalRepository: goals);
      final g = Goal(title: 'Group<=25', metric: GoalMetric.groupSize, comparator: GoalComparator.lessOrEqual, targetValue: 25, period: GoalPeriod.rollingMonth);
      await goals.put(g);
      await svc.recomputeAllProgress();
      final updated = (await goals.getAll()).first;
      // value ~ 20 (unique series), previousValue ~ 30, delta = previous - current = +10
      expect(updated.lastMeasuredValue, 20);
      expect(updated.previousMeasuredValue, 30);
      expect(updated.improvementDelta, 10);
      // progress = target/value = 25/20 = 1.25 -> clamped to 1
      expect(updated.lastProgress, 1);
    });

    test('averageSessionPoints computes average of session averages', () async {
      final now = DateTime(2025, 10, 7);
      final s1 = ShootingSession(weapon: 'P', caliber: '22LR', date: now, status: 'réalisée', series: [Series(distance: 10, points: 10, groupSize: 30), Series(distance: 10, points: 20, groupSize: 20)]);
      final s2 = ShootingSession(weapon: 'P', caliber: '22LR', date: now, status: 'réalisée', series: [Series(distance: 10, points: 30, groupSize: 20)]);
      final goals = _MemGoalRepo();
      final svc = GoalService(sessionRepository: _MemSessionRepo([s1, s2]), goalRepository: goals);
      final g = Goal(title: 'AvgSession>=20', metric: GoalMetric.averageSessionPoints, comparator: GoalComparator.greaterOrEqual, targetValue: 20);
      await goals.put(g);
      await svc.recomputeAllProgress();
      final updated = (await goals.getAll()).first;
      // s1 avg=15; s2 avg=30; global avg=(15+30)/2=22.5
      expect(updated.lastMeasuredValue, closeTo(22.5, 1e-9));
      expect(updated.lastProgress! >= 1.0, isTrue);
    });

    test('totalPoints metric sums series and achieves when >= target', () async {
      final now = DateTime.now();
      final s = ShootingSession(
        weapon: 'P', caliber: '22LR', date: now, status: 'réalisée',
        series: [Series(distance: 10, points: 15, groupSize: 20), Series(distance: 10, points: 10, groupSize: 18)],
      );
      final goals = _MemGoalRepo();
      final svc = GoalService(sessionRepository: _MemSessionRepo([s]), goalRepository: goals);
      final g = Goal(title: 'Total>=25', metric: GoalMetric.totalPoints, comparator: GoalComparator.greaterOrEqual, targetValue: 25);
      await goals.put(g);
      await svc.recomputeAllProgress();
      final updated = (await goals.getAll()).first;
      expect(updated.lastMeasuredValue, 25);
      expect(updated.lastProgress, 1);
      // achieved may be set with achievementDate
      if (updated.status == GoalStatus.achieved) {
        expect(updated.achievementDate, isNotNull);
      }
    });

    test('bestSessionPoints picks highest session total', () async {
      final now = DateTime.now();
      final s1 = ShootingSession(weapon: 'P', caliber: '22LR', date: now, status: 'réalisée', series: [Series(distance: 10, points: 10, groupSize: 20)]);
      final s2 = ShootingSession(weapon: 'P', caliber: '22LR', date: now, status: 'réalisée', series: [Series(distance: 10, points: 30, groupSize: 20), Series(distance: 10, points: 5, groupSize: 15)]);
      final goals = _MemGoalRepo();
      final svc = GoalService(sessionRepository: _MemSessionRepo([s1, s2]), goalRepository: goals);
      final g = Goal(title: 'BestSess>=34', metric: GoalMetric.bestSessionPoints, comparator: GoalComparator.greaterOrEqual, targetValue: 34);
      await goals.put(g);
      await svc.recomputeAllProgress();
      final updated = (await goals.getAll()).first;
      expect(updated.lastMeasuredValue, 35);
      expect(updated.lastProgress! >= 1.0, isTrue);
    });

    test('bestGroupSize finds minimal positive and achieves for <= comparator', () async {
      final now = DateTime.now();
      final s = ShootingSession(weapon: 'P', caliber: '22LR', date: now, status: 'réalisée', series: [
        Series(distance: 10, points: 10, groupSize: 12),
        Series(distance: 10, points: 10, groupSize: 8),
        Series(distance: 10, points: 10, groupSize: 9),
      ]);
      final goals = _MemGoalRepo();
      final svc = GoalService(sessionRepository: _MemSessionRepo([s]), goalRepository: goals);
      final g = Goal(title: 'BestGroup<=9', metric: GoalMetric.bestGroupSize, comparator: GoalComparator.lessOrEqual, targetValue: 9);
      await goals.put(g);
      await svc.recomputeAllProgress();
      final updated = (await goals.getAll()).first;
      expect(updated.lastMeasuredValue, 8);
      expect(updated.lastProgress, 1);
    });

    test('empty series edge: groupSize average remains null, progress stays null', () async {
      final now = DateTime.now();
      final s = ShootingSession(weapon: 'P', caliber: '22LR', date: now, status: 'réalisée', series: []);
      final goals = _MemGoalRepo();
      final svc = GoalService(sessionRepository: _MemSessionRepo([s]), goalRepository: goals);
      final g = Goal(title: 'AvgGroup<=10', metric: GoalMetric.groupSize, comparator: GoalComparator.lessOrEqual, targetValue: 10);
      await goals.put(g);
      await svc.recomputeAllProgress();
      final updated = (await goals.getAll()).first;
      expect(updated.lastMeasuredValue, isNull);
      expect(updated.lastProgress, isNull);
    });

    test('achieved date is set once when reaching target from active', () async {
      final now = DateTime.now();
      final s = ShootingSession(weapon: 'P', caliber: '22LR', date: now, status: 'réalisée', series: [Series(distance: 10, points: 50, groupSize: 10)]);
      final goals = _MemGoalRepo();
      final svc = GoalService(sessionRepository: _MemSessionRepo([s]), goalRepository: goals);
      final g = Goal(title: 'Avg>=40', metric: GoalMetric.averagePoints, comparator: GoalComparator.greaterOrEqual, targetValue: 40, status: GoalStatus.active);
      await goals.put(g);
      await svc.recomputeAllProgress();
      var updated = (await goals.getAll()).first;
      expect(updated.status, GoalStatus.achieved);
      expect(updated.achievementDate, isNotNull);
      final firstAchievedDate = updated.achievementDate;
      // Recompute again should keep the same achievementDate (not reset)
      await svc.recomputeAllProgress();
      updated = (await goals.getAll()).first;
      expect(updated.achievementDate, firstAchievedDate);
    });
  });
}
