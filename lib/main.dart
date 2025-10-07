import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'models/goal.dart';
import 'migrations/migration.dart';
import 'migrations/migration_2_add_exercises_field.dart';
import 'migrations/migration_3_create_exercises_box.dart';
import 'constants/session_constants.dart';
import 'providers/navigation_provider.dart';
import 'providers/settings_provider.dart';
import 'app/my_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.load();
  await Hive.initFlutter();
  
  // Run schema migrations (Hive structural adjustments) before opening boxes / using data.
  final schemaStore = SchemaVersionStore();
  final runner = MigrationRunner([
    Migration2AddExercisesField(), // v2
    Migration3CreateExercisesBox(), // v3
  ], schemaStore);
  await runner.run();
  
  // Register adapters for goals
  if (!Hive.isAdapterRegistered(40)) Hive.registerAdapter(GoalMetricAdapter());
  if (!Hive.isAdapterRegistered(41)) Hive.registerAdapter(GoalComparatorAdapter());
  if (!Hive.isAdapterRegistered(42)) Hive.registerAdapter(GoalStatusAdapter());
  if (!Hive.isAdapterRegistered(43)) Hive.registerAdapter(GoalPeriodAdapter());
  if (!Hive.isAdapterRegistered(44)) Hive.registerAdapter(GoalAdapter());

  await Hive.openBox(SessionConstants.hiveBoxSessions);
  if (!Hive.isBoxOpen('app_preferences')) {
    await Hive.openBox('app_preferences');
  }

  // Lancer l'application avec les providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
