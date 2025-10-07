import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/exercise.dart';
import 'package:tir_sportif/repositories/exercise_repository.dart';
import 'package:tir_sportif/services/exercise_service.dart';

class _MemExerciseRepo implements ExerciseRepository {
  final Map<String, Exercise> _store = {};
  @override
  Future<void> clear() async => _store.clear();
  @override
  Future<void> delete(String id) async => _store.remove(id);
  @override
  Future<List<Exercise>> getAll() async {
    final list = _store.values.toList();
    list.sort((a,b){
      if (a.priority != b.priority) return a.priority.compareTo(b.priority);
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }
  @override
  Future<void> put(Exercise exercise) async { _store[exercise.id] = exercise; }
}

void main() {
  group('ExerciseService', () {
    late ExerciseService service;
    late _MemExerciseRepo repo;

    setUp(() { repo = _MemExerciseRepo(); service = ExerciseService(repository: repo); });

    test('generateId returns base36_ts_random format', () {
      final id = service.generateId();
      expect(id.contains('_'), isTrue);
      final parts = id.split('_');
      expect(parts.length, 2);
      // base36 strings should be alphanumeric
      expect(RegExp(r'^[a-z0-9]+$').hasMatch(parts[0]), isTrue);
      expect(RegExp(r'^[a-z0-9]+$').hasMatch(parts[1]), isTrue);
    });

    test('addExercise trims inputs and accepts legacy string category', () async {
      await service.addExercise(name: '  Drill  ', category: 'stand', type: ExerciseType.stand, description: '  desc  ', consignes: ['  a  ', '   ', 'b']);
      final all = await service.listAll();
      expect(all.length, 1);
      expect(all.first.name, 'Drill');
      expect(all.first.description, 'desc');
      // 'stand' as legacy category string defaults to precision via parser
      expect(all.first.categoryEnum, ExerciseCategory.precision);
      expect(all.first.consignes, ['a','b']);
    });

    test('setGoals deduplicates and setConsignes trims/filters', () async {
  await service.addExercise(name: 'X', category: ExerciseCategory.precision, consignes: ['x']);
      var all = await service.listAll();
      final ex = all.first;
      await service.setGoals(ex, ['g1','g1','g2']);
      all = await service.listAll();
      expect(all.first.goalIds, ['g1','g2']);

      await service.setConsignes(all.first, ['  step1  ', '', 'step2  ']);
      all = await service.listAll();
      expect(all.first.consignes, ['step1','step2']);
    });
  });
}
