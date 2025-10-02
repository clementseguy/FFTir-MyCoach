// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:hive/hive.dart';

import 'package:tir_sportif/main.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/migrations/migration.dart';
import 'package:tir_sportif/migrations/migration_2_add_exercises_field.dart';
import 'package:tir_sportif/models/goal.dart';

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
  expect(find.text('Accueil'), findsWidgets);
  expect(find.text('Sessions'), findsWidgets);
  expect(find.text('Paramètres'), findsWidgets);
  });

  testWidgets('Exercices & Objectifs screen shows new cards, without roadmap', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    // Navigate to Exercices tab
    await tester.tap(find.text('Exercices').first);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    // Goals card present
    expect(find.text('Objectifs'), findsWidgets);
    // New Exercises card present
    expect(find.text('Exercices'), findsWidgets);
    expect(find.text('au total'), findsWidgets);
    // Roadmap text removed
    expect(find.text('Prochaines évolutions'), findsNothing);
  });
}
