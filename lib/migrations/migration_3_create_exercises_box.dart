import 'package:hive/hive.dart';
import 'migration.dart';

/// Migration v3: create empty 'exercises' box (map-based) if needed.
class Migration3CreateExercisesBox extends HiveMigration {
  @override
  int get toVersion => 3;

  @override
  Future<void> apply() async {
    if (!Hive.isBoxOpen('exercises')) {
      await Hive.openBox('exercises');
    }
  }
}