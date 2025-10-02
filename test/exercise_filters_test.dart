import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/exercise.dart';

List<Exercise> _filter(List<Exercise> all, {Set<ExerciseCategory>? cats, Set<ExerciseType>? types}) {
  final c = cats ?? {};
  final t = types ?? {};
  return all.where((e) {
    if (c.isNotEmpty && !c.contains(e.categoryEnum)) return false;
    if (t.isNotEmpty && !t.contains(e.type)) return false;
    return true;
  }).toList();
}

Exercise _ex(String id, ExerciseCategory c, ExerciseType t) => Exercise(
  id: id,
  name: id,
  categoryEnum: c,
  type: t,
  createdAt: DateTime.now(),
);

void main() {
  group('Exercise filters logic', () {
    final list = [
      _ex('a', ExerciseCategory.precision, ExerciseType.stand),
      _ex('b', ExerciseCategory.group, ExerciseType.stand),
      _ex('c', ExerciseCategory.group, ExerciseType.home),
      _ex('d', ExerciseCategory.speed, ExerciseType.home),
    ];

    test('No filters returns all', () {
      final r = _filter(list);
      expect(r.length, list.length);
    });

    test('Category filter only', () {
      final r = _filter(list, cats: {ExerciseCategory.group});
      expect(r.map((e)=> e.id), ['b','c']);
    });

    test('Type filter only', () {
      final r = _filter(list, types: {ExerciseType.home});
      expect(r.map((e)=> e.id), ['c','d']);
    });

    test('Both filters', () {
      final r = _filter(list, cats: {ExerciseCategory.group}, types: {ExerciseType.home});
      expect(r.map((e)=> e.id), ['c']);
    });
  });
}
