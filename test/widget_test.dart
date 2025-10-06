// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:hive/hive.dart';

import 'package:tir_sportif/main.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/migrations/migration.dart';
import 'package:tir_sportif/migrations/migration_2_add_exercises_field.dart';
import 'package:tir_sportif/models/goal.dart';
import 'package:tir_sportif/models/exercise.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/widgets/goals_at_glance_card.dart';
import 'package:tir_sportif/widgets/exercises_at_glance_card.dart';
import 'package:tir_sportif/services/goal_service.dart';
import 'package:tir_sportif/services/exercise_service.dart';
import 'package:tir_sportif/repositories/goal_repository.dart';
import 'package:tir_sportif/repositories/session_repository.dart';
import 'package:tir_sportif/repositories/exercise_repository.dart';

// Local stub repositories to keep tests deterministic (no Hive/IO).
class _StubGoalRepo implements GoalRepository {
  final List<Goal> _store;
  _StubGoalRepo(this._store);
  @override
  Future<void> delete(String id) async {}
  @override
  Future<void> deleteAll() async {}
  @override
  Future<List<Goal>> getAll() async => _store;
  @override
  Future<void> put(Goal goal) async {}
}

class _StubSessionRepo implements SessionRepository {
  @override
  Future<void> clearAll() async {}
  @override
  Future<void> delete(int id) async {}
  @override
  Future<List<ShootingSession>> getAll() async => const [];
  @override
  Future<int> insert(ShootingSession session) async => 1;
  @override
  Future<bool> update(ShootingSession session, {bool preserveExistingSeriesIfEmpty = true}) async => true;
}

class _StubExerciseRepo implements ExerciseRepository {
  final List<Exercise> _list;
  _StubExerciseRepo(this._list);
  @override
  Future<void> clear() async {}
  @override
  Future<void> delete(String id) async {}
  @override
  Future<List<Exercise>> getAll() async => _list;
  @override
  Future<void> put(Exercise exercise) async {}
}

/// Smoke test: assure que l'application se construit après initialisation
/// minimale (config + Hive + migrations) et affiche la navigation principale.
/// L'ancien test "counter" Flutter par défaut a été remplacé car l'app
/// n'utilise pas ce concept.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AppConfig.load();
    final tempDir = await Directory.systemTemp.createTemp('nex_target_test_');
    Hive.init(tempDir.path);

    // Migrations (mêmes que dans main())
    final schemaStore = SchemaVersionStore();
    final runner = MigrationRunner([
      Migration2AddExercisesField(),
    ], schemaStore);
    await runner.run();

    // Goal adapters (idempotent)
    if (!Hive.isAdapterRegistered(40)) Hive.registerAdapter(GoalMetricAdapter());
    if (!Hive.isAdapterRegistered(41)) Hive.registerAdapter(GoalComparatorAdapter());
    if (!Hive.isAdapterRegistered(42)) Hive.registerAdapter(GoalStatusAdapter());
    if (!Hive.isAdapterRegistered(43)) Hive.registerAdapter(GoalPeriodAdapter());
    if (!Hive.isAdapterRegistered(44)) Hive.registerAdapter(GoalAdapter());

    // Open required boxes
    await Hive.openBox(SessionConstants.hiveBoxSessions);
    if (!Hive.isBoxOpen('app_preferences')) {
      await Hive.openBox('app_preferences');
    }
    // Goals box (nécessaire pour carte Objectifs)
    if (!Hive.isBoxOpen('goals')) {
      await Hive.openBox<Goal>('goals');
    }
  });

  testWidgets('App boots and shows bottom navigation items', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // Premier frame + animations éventuelles
    await tester.pump(const Duration(milliseconds: 50));

    // Vérifie la présence des items de navigation (labels)
  // BottomNavigationBar may create multiple instances (e.g. semantics / offstage),
  // we assert at least one occurrence.
  expect(find.text('Coach'), findsWidgets);
  expect(find.text('Exercices'), findsWidgets);
  expect(find.text('Tableau de bord'), findsWidgets);
  expect(find.text('Sessions'), findsWidgets);
  expect(find.text('Paramètres'), findsWidgets);
  });

  // Test stable: compose the two glance cards with injected stub services (no Hive/IO).
  testWidgets('Exercices & Objectifs glance cards render without roadmap', (WidgetTester tester) async {
    // Minimal adapters for Goal (idempotent) only, no Hive boxes opened.
    if (!Hive.isAdapterRegistered(40)) Hive.registerAdapter(GoalMetricAdapter());
    if (!Hive.isAdapterRegistered(41)) Hive.registerAdapter(GoalComparatorAdapter());
    if (!Hive.isAdapterRegistered(42)) Hive.registerAdapter(GoalStatusAdapter());
    if (!Hive.isAdapterRegistered(43)) Hive.registerAdapter(GoalPeriodAdapter());
    if (!Hive.isAdapterRegistered(44)) Hive.registerAdapter(GoalAdapter());

    final goalService = GoalService(
      goalRepository: _StubGoalRepo([
        Goal(title: '10 sessions', metric: GoalMetric.sessionCount, comparator: GoalComparator.greaterOrEqual, targetValue: 10, status: GoalStatus.active),
        Goal(title: '100 points', metric: GoalMetric.totalPoints, comparator: GoalComparator.greaterOrEqual, targetValue: 100, status: GoalStatus.achieved),
      ]),
      sessionRepository: _StubSessionRepo(),
    );
    final exerciseService = ExerciseService(repository: _StubExerciseRepo([
      Exercise(id: 'e1', name: 'Dry fire', categoryEnum: ExerciseCategory.technique, type: ExerciseType.home, createdAt: DateTime.now()),
      Exercise(id: 'e2', name: 'Groupement 5 balles', categoryEnum: ExerciseCategory.group, type: ExerciseType.stand, createdAt: DateTime.now()),
    ]));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            GoalsAtGlanceCard(service: goalService),
            const SizedBox(height: 12),
            ExercisesAtGlanceCard(service: exerciseService),
          ],
        ),
      ),
    ));

    // Allow init microtasks
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));

    // Assertions: cards titles visible
    expect(find.text('Objectifs'), findsWidgets);
    expect(find.text('Exercices'), findsWidgets);
    expect(find.text('au total'), findsWidgets);
    // Roadmap label should not be present anymore
    expect(find.text('Prochaines évolutions'), findsNothing);
  });
}
