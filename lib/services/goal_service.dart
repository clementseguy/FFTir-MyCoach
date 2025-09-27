import 'package:hive/hive.dart';
import '../models/goal.dart';
import '../models/shooting_session.dart';
import '../data/local_db_hive.dart';

class GoalService {
  static const String goalsBoxName = 'goals';
  Box<Goal>? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox<Goal>(goalsBoxName);
    // Migration légère : attribuer des priorités séquentielles si absentes (9999) pour conserver ordre stable.
    final b = _box!;
    final goals = b.values.toList();
    // Si tous ont priorité par défaut ou mélange -> réattribuer ordre actuel d'insertion.
    final sorted = goals.toList();
    int idx = 0;
    for (final g in sorted) {
      if (g.priority >= 9999) {
        final updated = g.copyWith(priority: idx);
        await b.put(updated.id, updated);
        // priorité migrée
      }
      idx++;
    }
  }

  Box<Goal> _ensureBox() {
    final b = _box;
    if (b == null) {
      throw StateError('GoalService not initialized. Call init().');
    }
    return b;
  }

  Future<List<Goal>> listAll() async {
    final b = _ensureBox();
    final list = b.values.toList();
    list.sort((a,b){
      final pa = a.priority;
      final pb = b.priority;
      if (pa != pb) return pa.compareTo(pb);
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  Future<void> addGoal(Goal goal) async {
    final b = _ensureBox();
    await b.put(goal.id, goal);
  }

  Future<void> updateGoal(Goal goal) async {
    final b = _ensureBox();
    await b.put(goal.id, goal);
  }

  Future<void> deleteGoal(String id) async {
    final b = _ensureBox();
    await b.delete(id);
  }

  Future<void> recomputeAllProgress() async {
    final b = _ensureBox();
    final raw = await LocalDatabaseHive().getSessionsWithSeries();
    final sessions = raw.map((m) {
      final sessionMap = Map<String, dynamic>.from(m['session']);
      final seriesRaw = (m['series'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
      sessionMap['series'] = seriesRaw;
      return ShootingSession.fromMap(sessionMap);
    }).toList();
    for (final goal in b.values) {
      final updated = _computeProgress(goal, sessions);
      await b.put(updated.id, updated);
    }
  }

  Goal _computeProgress(Goal goal, List<ShootingSession> sessions) {
    double? value;
    switch (goal.metric) {
      case GoalMetric.averagePoints:
        final allSeries = sessions.expand((s) => s.series);
        final points = allSeries.map((s) => s.points.toDouble()).toList();
        if (points.isNotEmpty) value = points.reduce((a,b)=>a+b) / points.length;
        break;
      case GoalMetric.sessionCount:
        value = sessions.length.toDouble();
        break;
      case GoalMetric.totalPoints:
        final allSeries = sessions.expand((s) => s.series);
        final points = allSeries.map((s) => s.points.toDouble()).toList();
        value = points.isEmpty ? 0 : points.reduce((a,b)=>a+b);
        break;
      case GoalMetric.groupSize:
        final allSeries = sessions.expand((s) => s.series);
        final groups = allSeries.map((s) => s.groupSize).toList();
        if (groups.isNotEmpty) value = groups.reduce((a,b)=>a+b) / groups.length;
        break;
    }

    double? progress;
    if (value != null) {
      switch (goal.comparator) {
        case GoalComparator.greaterOrEqual:
          progress = value / goal.targetValue;
          break;
        case GoalComparator.lessOrEqual:
          progress = goal.targetValue == 0 ? 0 : goal.targetValue / value;
          break;
      }
      if (progress.isNaN || progress.isInfinite) {
        progress = 0;
      }
      progress = progress.clamp(0, 1);
    }

    var status = goal.status;
    if (progress != null) {
      final achieved = (goal.comparator == GoalComparator.greaterOrEqual && value! >= goal.targetValue) ||
          (goal.comparator == GoalComparator.lessOrEqual && value! <= goal.targetValue);
      if (achieved && status == GoalStatus.active) status = GoalStatus.achieved;
    }

    return goal.copyWith(
      lastProgress: progress ?? goal.lastProgress,
      lastMeasuredValue: value ?? goal.lastMeasuredValue,
      status: status,
    );
  }
}
