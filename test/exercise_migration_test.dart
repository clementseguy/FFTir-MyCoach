import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/exercise.dart';

void main() {
  group('Exercise migration/backfill', () {
    test('fromMap legacy without type/category normalizes to defaults', () {
      final legacy = {
        'id': 'abc',
        'name': 'Séance précision',
        'category': 'précision',
        'createdAt': DateTime.now().toIso8601String(),
        'priority': 9999,
      };
      final ex = Exercise.fromMap(legacy);
      expect(ex.categoryEnum, ExerciseCategory.precision);
      expect(ex.type, ExerciseType.stand); // default
    });

    test('fromMap legacy unknown category maps to precision', () {
      final legacy = {
        'id': 'def',
        'name': 'Custom',
        'category': 'inconnue',
        'createdAt': DateTime.now().toIso8601String(),
      };
      final ex = Exercise.fromMap(legacy);
      expect(ex.categoryEnum, ExerciseCategory.precision);
    });

    test('fromMap with new fields preserves enums', () {
      final map = Exercise(
        id: 'x1',
        name: 'Vitesse base',
        categoryEnum: ExerciseCategory.speed,
        type: ExerciseType.home,
        createdAt: DateTime.now(),
      ).toMap();
      final ex = Exercise.fromMap(map);
      expect(ex.categoryEnum, ExerciseCategory.speed);
      expect(ex.type, ExerciseType.home);
    });
  });
}
