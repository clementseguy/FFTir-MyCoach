import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/exercise.dart';
import 'package:tir_sportif/utils/exercise_sorting.dart';

Exercise ex(String name, ExerciseCategory c, ExerciseType t, int ms) => Exercise(
  id: name,
  name: name,
  categoryEnum: c,
  type: t,
  createdAt: DateTime.fromMillisecondsSinceEpoch(ms),
);

void main() {
  group('Exercise sorting', () {
    final list = [
      ex('Alpha', ExerciseCategory.speed, ExerciseType.home, 3),
      ex('beta', ExerciseCategory.group, ExerciseType.stand, 2),
      ex('Gamma', ExerciseCategory.group, ExerciseType.home, 1),
    ];

    test('nameAsc', () {
      final r = sortExercises(list, ExerciseSortMode.nameAsc);
      expect(r.map((e)=> e.name).toList(), ['Alpha','beta','Gamma']);
    });

    test('nameDesc', () {
      final r = sortExercises(list, ExerciseSortMode.nameDesc);
      expect(r.first.name, 'Gamma');
    });

    test('category groups first then name', () {
      final r = sortExercises(list, ExerciseSortMode.category);
      // group category appears before speed; within group beta before Gamma (case-insensitive)
      expect(r.map((e)=> e.name).toList(), ['beta','Gamma','Alpha']);
    });

    test('type sort (stand first)', () {
      final r = sortExercises(list, ExerciseSortMode.type);
      expect(r.first.type, ExerciseType.stand);
    });

    test('newest', () {
      final r = sortExercises(list, ExerciseSortMode.newest);
      expect(r.first.name, 'Alpha'); // ms=3 newest
    });
  });
}
