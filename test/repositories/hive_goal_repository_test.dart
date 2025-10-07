import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/models/goal.dart';
import 'package:tir_sportif/repositories/goal_repository.dart';

void main() {
  setUp(() async {
    // Ensure no previously opened boxes in this isolate
    await Hive.close();
    final dir = await Directory.systemTemp.createTemp('nt_repo_goal_');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(40)) Hive.registerAdapter(GoalMetricAdapter());
    if (!Hive.isAdapterRegistered(41)) Hive.registerAdapter(GoalComparatorAdapter());
    if (!Hive.isAdapterRegistered(42)) Hive.registerAdapter(GoalStatusAdapter());
    if (!Hive.isAdapterRegistered(43)) Hive.registerAdapter(GoalPeriodAdapter());
    if (!Hive.isAdapterRegistered(44)) Hive.registerAdapter(GoalAdapter());
  });

  test('put/getAll sorts by priority then createdAt', () async {
  final repo = HiveGoalRepository(boxName: 'goals_test_${DateTime.now().microsecondsSinceEpoch}');
    final g1 = Goal(
      id: 'a', title: 'A', metric: GoalMetric.totalPoints, comparator: GoalComparator.greaterOrEqual, targetValue: 10,
      priority: 2, createdAt: DateTime(2025,1,2),
    );
    final g2 = Goal(
      id: 'b', title: 'B', metric: GoalMetric.totalPoints, comparator: GoalComparator.greaterOrEqual, targetValue: 10,
      priority: 1, createdAt: DateTime(2025,1,3),
    );
    final g3 = Goal(
      id: 'c', title: 'C', metric: GoalMetric.totalPoints, comparator: GoalComparator.greaterOrEqual, targetValue: 10,
      priority: 1, createdAt: DateTime(2025,1,1),
    );
    await repo.put(g1);
    await repo.put(g2);
    await repo.put(g3);
    final list = await repo.getAll();
    // Expect priority ascending; ties by createdAt ascending -> g3 (p1, older), g2 (p1, newer), g1 (p2)
    expect(list.map((g)=>g.id).toList(), ['c','b','a']);
    await Hive.close();
  });

  test('delete and deleteAll remove items', () async {
  final repo = HiveGoalRepository(boxName: 'goals_test_${DateTime.now().microsecondsSinceEpoch}');
    final g = Goal(id: 'x', title: 'X', metric: GoalMetric.sessionCount, comparator: GoalComparator.greaterOrEqual, targetValue: 3);
    await repo.put(g);
    expect((await repo.getAll()).length, 1);
    await repo.delete('x');
    expect((await repo.getAll()).length, 0);

    await repo.put(g);
    await repo.deleteAll();
    expect((await repo.getAll()).length, 0);
    await Hive.close();
  });
}
