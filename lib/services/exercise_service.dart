import 'dart:math';
import '../models/exercise.dart';
import '../repositories/exercise_repository.dart';

/// High-level operations for exercises (sorting, id generation).
class ExerciseService {
  final ExerciseRepository _repo;
  ExerciseService({ExerciseRepository? repository}) : _repo = repository ?? HiveExerciseRepository();

  /// Generate a short unique id: base36 timestamp + random suffix.
  String generateId() {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rnd = Random().nextInt(1 << 20).toRadixString(36);
    return '${ts}_$rnd';
  }

  Future<List<Exercise>> listAll() => _repo.getAll();

  Future<void> addExercise({
    required String name,
    required String category,
    String? description,
    int priority = 9999,
    List<String>? goalIds,
  }) async {
    final ex = Exercise(
      id: generateId(),
      name: name.trim(),
      category: category.trim(),
      description: (description?.trim().isEmpty ?? true) ? null : description!.trim(),
      createdAt: DateTime.now(),
      priority: priority,
      goalIds: goalIds ?? const [],
    );
    await _repo.put(ex);
  }

  Future<void> updateExercise(Exercise exercise) => _repo.put(exercise);

  Future<void> deleteExercise(String id) => _repo.delete(id);

  Future<void> reorder(List<Exercise> ordered) async {
    int idx = 0;
    for (final ex in ordered) {
      await _repo.put(ex.copyWith(priority: idx++));
    }
  }

  Future<void> clearAll() => _repo.clear();
}