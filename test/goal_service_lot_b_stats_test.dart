import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/goal.dart';
import 'package:tir_sportif/services/goal_service.dart';
import 'package:tir_sportif/repositories/goal_repository.dart';

class InMemoryGoalRepository implements GoalRepository {
  final Map<String, Goal> _store = {};
  @override
  Future<void> delete(String id) async { _store.remove(id); }
  @override
  Future<void> deleteAll() async { _store.clear(); }
  @override
  Future<List<Goal>> getAll() async => _store.values.toList();
  @override
  Future<void> put(Goal goal) async { _store[goal.id] = goal; }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('GoalService.macroAchievementStats', () {
    late GoalService service;
    late InMemoryGoalRepository repo;

    setUp(() async {
      // Pas de Hive: on reste purement en mémoire pour éviter MissingPluginException.
      repo = InMemoryGoalRepository();
      service = GoalService(goalRepository: repo, sessionRepository: null);
    });

    Goal achievedDaysAgo(int days) {
      final now = DateTime.now();
      final date = now.subtract(Duration(days: days));
      return Goal(
        title: 'A-$days',
        metric: GoalMetric.sessionCount,
        comparator: GoalComparator.greaterOrEqual,
        targetValue: 10,
      ).copyWith(status: GoalStatus.achieved, achievementDate: date, lastProgress: 1.0, lastMeasuredValue: 10);
    }

    test('counts distribute into proper windows', () async {
      // Achieved at boundaries and outside
      final goals = [
        achievedDaysAgo(1), // in all windows
        achievedDaysAgo(6), // in all windows
        achievedDaysAgo(8), // 30/60/90 only
        achievedDaysAgo(29), // 30/60/90
        achievedDaysAgo(31), // 60/90
        achievedDaysAgo(59), // 60/90
        achievedDaysAgo(61), // 90 only
        achievedDaysAgo(89), // 90 only
        achievedDaysAgo(91), // outside all windows
      ];
      for (final g in goals) { await repo.put(g); }
      // Add 2 active
      await repo.put(Goal(title: 'Active1', metric: GoalMetric.sessionCount, comparator: GoalComparator.greaterOrEqual, targetValue: 5));
      await repo.put(Goal(title: 'Active2', metric: GoalMetric.sessionCount, comparator: GoalComparator.greaterOrEqual, targetValue: 3));

      final stats = await service.macroAchievementStats();
      expect(stats.totalCompleted, goals.length);
      expect(stats.totalActive, 2);
      // completedLast7: days 1 & 6 => 2
      expect(stats.completedLast7, 2);
      // completedLast30: days <=29: 1,6,8,29 => 4
      expect(stats.completedLast30, 4);
      // completedLast60: days <=59: add 31,59 => 6
      expect(stats.completedLast60, 6);
      // completedLast90: days <=89: add 61,89 => 8
      expect(stats.completedLast90, 8);
    });

    test('empty returns zeros', () async {
      final stats = await service.macroAchievementStats();
      expect(stats.totalCompleted, 0);
      expect(stats.totalActive, 0);
      expect(stats.completedLast7, 0);
    });
  });
}
