import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:tir_sportif/services/exercise_service.dart';
import 'package:tir_sportif/services/goal_service.dart';
import 'package:tir_sportif/models/goal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Exercise <-> Goals linking', () {
    late ExerciseService exerciseService;
    late GoalService goalService;

    setUpAll(() async {
      final dir = await Directory.systemTemp.createTemp('nt_test_exercises_');
      Hive.init(dir.path);
      // Register goal adapters
      if (!Hive.isAdapterRegistered(40)) Hive.registerAdapter(GoalMetricAdapter());
      if (!Hive.isAdapterRegistered(41)) Hive.registerAdapter(GoalComparatorAdapter());
      if (!Hive.isAdapterRegistered(42)) Hive.registerAdapter(GoalStatusAdapter());
      if (!Hive.isAdapterRegistered(43)) Hive.registerAdapter(GoalPeriodAdapter());
      if (!Hive.isAdapterRegistered(44)) Hive.registerAdapter(GoalAdapter());
      exerciseService = ExerciseService();
      goalService = GoalService();
      await goalService.init();
    });

    tearDown(() async {
      // Clear boxes between tests if opened
      if (Hive.isBoxOpen('exercises')) await Hive.box('exercises').clear();
      if (Hive.isBoxOpen('goals')) await Hive.box<Goal>('goals').clear();
    });

    test('create exercise then link goals', () async {
      // Create two goals
      final g1 = Goal(title: 'Améliorer moyenne', metric: GoalMetric.averagePoints, comparator: GoalComparator.greaterOrEqual, targetValue: 90);
      final g2 = Goal(title: 'Réduire groupement', metric: GoalMetric.groupSize, comparator: GoalComparator.lessOrEqual, targetValue: 25);
      await goalService.addGoal(g1);
      await goalService.addGoal(g2);

      // Add exercise
      await exerciseService.addExercise(name: 'Drill précision', category: 'précision');
      final list = await exerciseService.listAll();
      expect(list.length, 1);
      final ex = list.first;
      expect(ex.goalIds, isEmpty);

      // Link goals
      await exerciseService.setGoals(ex, [g1.id, g2.id]);
      final updated = (await exerciseService.listAll()).first;
      expect(updated.goalIds.toSet(), {g1.id, g2.id});
    });
  });
}
