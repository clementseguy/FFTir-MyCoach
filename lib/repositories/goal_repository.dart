import 'package:hive/hive.dart';
import '../models/goal.dart';

/// Abstraction for goal persistence.
abstract class GoalRepository {
  Future<List<Goal>> getAll();
  Future<void> put(Goal goal);
  Future<void> delete(String id);
  Future<void> deleteAll();
}

class HiveGoalRepository implements GoalRepository {
  static const String defaultBoxName = 'goals';
  final String _boxName;
  HiveGoalRepository({String? boxName}) : _boxName = boxName ?? defaultBoxName;
  Box<Goal>? _box;

  Future<Box<Goal>> _ensureBox() async {
    if (_box != null) return _box!;
    _box = await Hive.openBox<Goal>(_boxName);
    return _box!;
  }

  @override
  Future<void> delete(String id) async {
    final b = await _ensureBox();
    await b.delete(id);
  }

  @override
  Future<void> deleteAll() async {
    final b = await _ensureBox();
    await b.clear();
  }

  @override
  Future<List<Goal>> getAll() async {
    final b = await _ensureBox();
    final list = b.values.toList();
    list.sort((a,b){
      final pa=a.priority; final pb=b.priority;
      if (pa!=pb) return pa.compareTo(pb);
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  @override
  Future<void> put(Goal goal) async {
    final b = await _ensureBox();
    await b.put(goal.id, goal);
  }
}