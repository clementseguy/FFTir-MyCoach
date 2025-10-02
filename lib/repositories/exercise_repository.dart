import 'package:hive/hive.dart';
import '../models/exercise.dart';

abstract class ExerciseRepository {
  Future<List<Exercise>> getAll();
  Future<void> put(Exercise exercise);
  Future<void> delete(String id);
  Future<void> clear();
}

class HiveExerciseRepository implements ExerciseRepository {
  static const String boxName = 'exercises';
  Box? _box;

  Future<Box> _ensureBox() async {
    if (_box != null) return _box!;
    _box = await Hive.openBox(boxName);
    return _box!;
  }

  @override
  Future<void> clear() async {
    final b = await _ensureBox();
    await b.clear();
  }

  @override
  Future<void> delete(String id) async {
    final b = await _ensureBox();
    await b.delete(id);
  }

  @override
  Future<List<Exercise>> getAll() async {
    final b = await _ensureBox();
  final list = b.values.map((e) => Exercise.fromMap(Map<String, dynamic>.from(e))).toList();
    list.sort((a,b){
      final pa=a.priority; final pb=b.priority;
      if (pa!=pb) return pa.compareTo(pb);
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  @override
  Future<void> put(Exercise exercise) async {
    final b = await _ensureBox();
    await b.put(exercise.id, exercise.toMap());
  }
}