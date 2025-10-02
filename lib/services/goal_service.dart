import '../models/goal.dart';
import '../models/shooting_session.dart';
import '../repositories/session_repository.dart';
import '../repositories/hive_session_repository.dart';
import '../repositories/goal_repository.dart';

class GoalService {
  final SessionRepository _sessions;
  final GoalRepository _goals;

  GoalService({SessionRepository? sessionRepository, GoalRepository? goalRepository})
      : _sessions = sessionRepository ?? HiveSessionRepository(),
        _goals = goalRepository ?? HiveGoalRepository();

  Future<void> init() async {
    // Trigger box open via repository
    final list = await _goals.getAll();
    // Migration légère : attribuer des priorités séquentielles si absentes (>=9999)
    int idx = 0;
    for (final g in list) {
      if (g.priority >= 9999) {
        await _goals.put(g.copyWith(priority: idx));
      }
      idx++;
    }
  }

  Future<List<Goal>> listAll() => _goals.getAll();

  Future<void> addGoal(Goal goal) => _goals.put(goal);

  Future<void> updateGoal(Goal goal) => _goals.put(goal);

  Future<void> deleteGoal(String id) => _goals.delete(id);

  Future<void> recomputeAllProgress() async {
    final sessions = await _sessions.getAll();
    final goals = await _goals.getAll();
    for (final goal in goals) {
      final updated = _computeProgress(goal, sessions);
      await _goals.put(updated);
    }
  }

  // --- Lot A additions ---
  static const double kGoalDeltaNeutralEpsilon = 0.001;

  /// Returns active (non achieved, non archived, non failed) goals sorted by
  /// lastProgress desc then priority asc (tie-break) limited to n.
  Future<List<Goal>> topActiveGoals(int n) async {
    final all = await _goals.getAll();
    final filtered = all.where((g) => g.status == GoalStatus.active).toList();
    filtered.sort((a,b){
      final pa = a.lastProgress ?? 0;
      final pb = b.lastProgress ?? 0;
      if (pb.compareTo(pa) != 0) return pb.compareTo(pa);
      return a.priority.compareTo(b.priority);
    });
    if (filtered.length <= n) return filtered;
    return filtered.sublist(0, n);
  }

  Future<int> countActiveGoals() async {
    final all = await _goals.getAll();
    return all.where((g)=> g.status == GoalStatus.active).length;
  }

  Future<int> countAchievedGoals() async {
    final all = await _goals.getAll();
    return all.where((g)=> g.status == GoalStatus.achieved).length;
  }

  /// Count goals achieved within the last [days] days (inclusive).
  Future<int> achievementsWithin(int days) async {
    if (days <= 0) return 0;
    final all = await _goals.getAll();
    final now = DateTime.now();
    final threshold = now.subtract(Duration(days: days));
    return all.where((g) {
      if (g.status != GoalStatus.achieved) return false;
      final d = g.achievementDate;
      if (d == null) return false;
      return !d.isBefore(threshold) && !d.isAfter(now);
    }).length;
  }
  // --- End Lot A additions ---

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
