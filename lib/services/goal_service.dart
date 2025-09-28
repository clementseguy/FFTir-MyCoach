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
    // Filtrer selon la période si définie
    List<ShootingSession> filtered = sessions;
    // Conserver copie brute pour calcul tendance (période précédente)
    List<ShootingSession> previousSlice = const [];
    if (goal.period != GoalPeriod.none) {
      final now = DateTime.now();
      DateTime threshold;
      switch (goal.period) {
        case GoalPeriod.rollingWeek:
          threshold = now.subtract(const Duration(days: 7));
          break;
        case GoalPeriod.rollingMonth:
          threshold = now.subtract(const Duration(days: 30));
          break;
        case GoalPeriod.none:
          threshold = DateTime.fromMillisecondsSinceEpoch(0);
          break;
      }
      filtered = sessions.where((s) {
        final d = s.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return d.isAfter(threshold);
      }).toList();
      // Fenêtre précédente (même durée juste avant)
      final prevStart = goal.period == GoalPeriod.rollingWeek
          ? now.subtract(const Duration(days: 14))
          : now.subtract(const Duration(days: 60));
      final prevEnd = goal.period == GoalPeriod.rollingWeek
          ? now.subtract(const Duration(days: 7))
          : now.subtract(const Duration(days: 30));
      previousSlice = sessions.where((s) {
        final d = s.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return d.isAfter(prevStart) && d.isBefore(prevEnd);
      }).toList();
    }

    double? value;
    switch (goal.metric) {
      case GoalMetric.averagePoints:
        final allSeries = filtered.expand((s) => s.series);
        final points = allSeries.map((s) => s.points.toDouble()).toList();
        if (points.isNotEmpty) value = points.reduce((a,b)=>a+b) / points.length;
        break;
      case GoalMetric.sessionCount:
        value = filtered.length.toDouble();
        break;
      case GoalMetric.totalPoints:
        final allSeries = filtered.expand((s) => s.series);
        final points = allSeries.map((s) => s.points.toDouble()).toList();
        value = points.isEmpty ? 0 : points.reduce((a,b)=>a+b);
        break;
      case GoalMetric.groupSize:
        final allSeries = filtered.expand((s) => s.series);
        final groups = allSeries.map((s) => s.groupSize).toList();
        if (groups.isNotEmpty) value = groups.reduce((a,b)=>a+b) / groups.length;
        break;
      case GoalMetric.averageSessionPoints:
        // Moyenne des points moyens par session (chaque session: somme points séries / nb séries)
        if (filtered.isNotEmpty) {
          double sum = 0;
            int count = 0;
            for (final s in filtered) {
              if (s.series.isEmpty) continue;
              final pts = s.series.map((e) => e.points.toDouble()).reduce((a,b)=>a+b);
              sum += pts / s.series.length;
              count++;
            }
            if (count > 0) value = sum / count;
        }
        break;
      case GoalMetric.bestSeriesPoints:
        final allSeries = filtered.expand((s)=> s.series).toList();
        if (allSeries.isNotEmpty) {
          value = allSeries.map((s)=> s.points.toDouble()).reduce((a,b)=> a>b?a:b);
        }
        break;
      case GoalMetric.bestSessionPoints:
        if (filtered.isNotEmpty) {
          double best = 0;
          for (final s in filtered) {
            if (s.series.isEmpty) continue;
            final total = s.series.map((e)=> e.points.toDouble()).reduce((a,b)=> a+b);
            if (total > best) best = total;
          }
          value = best;
        }
        break;
      case GoalMetric.bestGroupSize:
        final allSeries2 = filtered.expand((s)=> s.series).toList();
        if (allSeries2.isNotEmpty) {
          value = allSeries2.map((s)=> s.groupSize).reduce((a,b)=> a<b?a:b);
        }
        break;
    }

    double? progress;
    double? previousValue;
    if (previousSlice.isNotEmpty && goal.period != GoalPeriod.none) {
      previousValue = _computeMetricValue(goal.metric, previousSlice);
    }
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
    DateTime? achievementDate = goal.achievementDate;
    if (progress != null) {
      final achieved = (goal.comparator == GoalComparator.greaterOrEqual && value! >= goal.targetValue) ||
          (goal.comparator == GoalComparator.lessOrEqual && value! <= goal.targetValue);
      if (achieved && status == GoalStatus.active) {
        status = GoalStatus.achieved;
        if (achievementDate == null) {
          achievementDate = DateTime.now();
        }
      }
    }

    double? delta;
    if (value != null && previousValue != null) {
      // Pour les métriques où plus grand est mieux (greaterOrEqual) delta = value - previous.
      // Pour les métriques où plus petit est mieux (lessOrEqual) delta = previous - value (donc positif si amélioration).
      if (goal.comparator == GoalComparator.greaterOrEqual) {
        delta = value - previousValue;
      } else {
        delta = previousValue - value;
      }
    }
    return goal.copyWith(
      lastProgress: progress ?? goal.lastProgress,
      lastMeasuredValue: value ?? goal.lastMeasuredValue,
      status: status,
      achievementDate: achievementDate,
      previousMeasuredValue: previousValue ?? goal.previousMeasuredValue,
      improvementDelta: delta ?? goal.improvementDelta,
    );
  }

  double? _computeMetricValue(GoalMetric metric, List<ShootingSession> sessions) {
    if (sessions.isEmpty) return null;
    switch (metric) {
      case GoalMetric.averagePoints:
        final allSeries = sessions.expand((s) => s.series);
        final points = allSeries.map((s) => s.points.toDouble()).toList();
        if (points.isNotEmpty) return points.reduce((a,b)=>a+b) / points.length;
        return null;
      case GoalMetric.sessionCount:
        return sessions.length.toDouble();
      case GoalMetric.totalPoints:
        final allSeries = sessions.expand((s) => s.series);
        final points = allSeries.map((s) => s.points.toDouble()).toList();
        return points.isEmpty ? 0 : points.reduce((a,b)=>a+b);
      case GoalMetric.groupSize:
        final allSeries = sessions.expand((s) => s.series);
        final groups = allSeries.map((s) => s.groupSize).toList();
        if (groups.isNotEmpty) return groups.reduce((a,b)=>a+b) / groups.length;
        return null;
      case GoalMetric.averageSessionPoints:
        double sum = 0; int count = 0; for (final s in sessions) { if (s.series.isEmpty) continue; final pts = s.series.map((e)=>e.points.toDouble()).reduce((a,b)=>a+b); sum += pts / s.series.length; count++; }
        if (count>0) return sum / count; else return null;
      case GoalMetric.bestSeriesPoints:
        final allSeries = sessions.expand((s)=> s.series).toList();
        if (allSeries.isNotEmpty) return allSeries.map((s)=> s.points.toDouble()).reduce((a,b)=> a>b?a:b);
        return null;
      case GoalMetric.bestSessionPoints:
        double best = 0; for (final s in sessions){ if (s.series.isEmpty) continue; final total = s.series.map((e)=> e.points.toDouble()).reduce((a,b)=> a+b); if (total>best) best = total; }
        return best;
      case GoalMetric.bestGroupSize:
        final allSeries2 = sessions.expand((s)=> s.series).toList();
        if (allSeries2.isNotEmpty) return allSeries2.map((s)=> s.groupSize).reduce((a,b)=> a<b?a:b);
        return null;
    }
  }
}
