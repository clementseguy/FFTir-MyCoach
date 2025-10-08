import '../models/shooting_session.dart';
import '../utils/session_filters.dart';
import '../interfaces/stats_service_interface.dart';

class SeriesStat {
  final DateTime date; // date de la session associée
  final int points;
  final double groupSize;
  final double distance;
  final String category;
  SeriesStat({
    required this.date,
    required this.points,
    required this.groupSize,
    required this.distance,
    required this.category,
  });
}

class StatsService implements IStatsService {
  final List<ShootingSession> sessions;
  late final List<SeriesStat> _series; // séries aplaties
  // Freeze a reference "now" to ensure deterministic date-based computations (useful for tests)
  final DateTime _now;

  StatsService(this.sessions, {DateTime? now}) : _now = now ?? DateTime.now() {
    // Lot C (F24): central filter to exclude planned sessions globally
    final realized = SessionFilters.realizedWithDate(sessions);
    _series = _flatten(realized);
  }

  List<SeriesStat> _flatten(List<ShootingSession> realized) {
    final List<SeriesStat> list = [];
    // Strict chronological ordering: by date then by intra-session order (F14)
    final ordered = List<ShootingSession>.from(realized)
      ..sort((a, b) => (a.date ?? DateTime(1970)).compareTo(b.date ?? DateTime(1970)));
    for (final s in ordered) {
      final date = s.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      for (final serie in s.series) {
        list.add(SeriesStat(
          date: date,
          points: serie.points,
          groupSize: serie.groupSize,
          distance: serie.distance,
          category: s.category,
        ));
      }
    }
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  // Filtre séries sur une période (ex: 30 derniers jours)
  List<SeriesStat> _filterLast(Duration d) {
    final cutoff = _now.subtract(d);
    return _series.where((s) => s.date.isAfter(cutoff)).toList();
  }

  double _avgPoints(List<SeriesStat> list) {
    if (list.isEmpty) return 0;
    final sum = list.fold<int>(0, (acc, e) => acc + e.points);
    return sum / list.length;
  }

  double _avgGroupSize(List<SeriesStat> list) {
    if (list.isEmpty) return 0;
    final sum = list.fold<double>(0, (acc, e) => acc + e.groupSize);
    return sum / list.length;
  }

  // Public KPIs
  double averagePointsLast30Days() => _avgPoints(_filterLast(const Duration(days: 30)));
  double averageGroupSizeLast30Days() => _avgGroupSize(_filterLast(const Duration(days: 30)));

  SeriesStat? bestSeriesByPoints() {
    if (_series.isEmpty) return null;
    SeriesStat best = _series.first;
    for (final s in _series) {
      if (s.points > best.points) best = s;
    }
    return best;
  }

  int sessionsCountCurrentMonth() {
    final now = _now;
    final realized = SessionFilters.realizedWithDate(sessions);
    return realized.where((s) => s.date!.year == now.year && s.date!.month == now.month).length;
  }

  // Moyenne mobile des points (window par défaut 3)
  List<double> movingAveragePoints({int window = 3}) {
    if (_series.isEmpty || window <= 1) return _series.map((e) => e.points.toDouble()).toList();
    final List<double> result = [];
    final values = _series.map((e) => e.points.toDouble()).toList();
    for (int i = 0; i < values.length; i++) {
      final start = (i - window + 1) < 0 ? 0 : i - window + 1;
      final subset = values.sublist(start, i + 1);
      final avg = subset.reduce((a, b) => a + b) / subset.length;
      result.add(avg);
    }
    return result;
  }

  // ===== Phase 2 Metrics =====
  double _stdDev(List<SeriesStat> list) {
    if (list.length < 2) return 0;
    final mean = list.fold<int>(0, (a,b)=> a + b.points) / list.length;
    final variance = list.fold<double>(0, (acc, e) {
      final diff = e.points - mean;
      return acc + diff * diff;
    }) / list.length;
    return variance <= 0 ? 0 : variance.sqrtNewton();
  }

  double consistencyIndexLast30Days() {
    final data = _filterLast(const Duration(days: 30));
    if (data.length < 3) return 0; // insuffisant
    final mean = _avgPoints(data);
    if (mean <= 0) return 0;
    final sd = _stdDev(data);
    final ci = (1 - (sd / mean)) * 100;
    if (ci.isNaN || ci.isInfinite) return 0;
    return ci.clamp(0, 100);
  }

  double progressionPercent30Days() {
    final now = _now;
    final currentWindow = now.subtract(const Duration(days: 30));
    final previousWindowStart = now.subtract(const Duration(days: 60));
    final curr = _series.where((s) => s.date.isAfter(currentWindow)).toList();
    final prev = _series.where((s) => s.date.isAfter(previousWindowStart) && s.date.isBefore(currentWindow)).toList();
    if (curr.length < 5 || prev.length < 5) return double.nan; // insuffisant
    final avgCurr = _avgPoints(curr);
    final avgPrev = _avgPoints(prev);
    if (avgPrev <= 0) return double.nan;
    return ((avgCurr - avgPrev) / avgPrev) * 100;
  }

  Map<double,int> distanceDistribution({bool last30 = true}) {
    final list = last30 ? _filterLast(const Duration(days:30)) : _series;
    final Map<double,int> counts = {};
    for (final s in list) {
      final d = double.parse(s.distance.toStringAsFixed(0));
      counts[d] = (counts[d] ?? 0) + 1;
    }
    return counts;
  }

  Map<String,int> categoryDistribution({bool sessionsOnly = true}) {
    // sessionsOnly = true : compte par session (pas par série)
    if (sessionsOnly) {
      final Map<String,int> counts = {};
      for (final sess in SessionFilters.realizedWithDate(sessions)) {
        final cat = sess.category;
        counts[cat] = (counts[cat] ?? 0) + 1;
      }
      return counts;
    } else {
      final Map<String,int> counts = {};
      for (final s in _series) {
        counts[s.category] = (counts[s.category] ?? 0) + 1;
      }
      return counts;
    }
  }

  List<_PointBucket> pointBuckets({int bucketSize = 10, bool last30 = true}) {
    final list = last30 ? _filterLast(const Duration(days:30)) : _series;
    if (list.isEmpty) return [];
    final maxP = list.map((e)=> e.points).reduce((a,b)=> a>b?a:b);
    final List<_PointBucket> buckets = [];
    for (int start = 0; start <= maxP; start += bucketSize) {
      final end = start + bucketSize - 1;
      final count = list.where((e) => e.points >= start && e.points <= end).length;
      buckets.add(_PointBucket(start: start, end: end, count: count));
    }
    return buckets;
  }

  // ===== Phase 3 Metrics =====
  /// Returns the last [n] series from the full chronological series list (ASC order).
  /// If fewer than [n] exist, returns all. Used by UI graphs to ensure newest on the right.
  List<SeriesStat> lastNSortedSeriesAsc(int n) {
    if (n <= 0 || _series.isEmpty) return const [];
    final len = _series.length;
    final start = (len - n) < 0 ? 0 : (len - n);
    // _series is already sorted by date ASC
    return _series.sublist(start, len);
  }
  int currentDayStreak() {
    final dates = <DateTime>{};
    for (final s in SessionFilters.realizedWithDate(sessions)) {
      if (s.date != null) {
        final d = s.date!;
        dates.add(DateTime(d.year, d.month, d.day));
      }
    }
    if (dates.isEmpty) return 0;
    final sorted = dates.toList()..sort((a,b)=> b.compareTo(a)); // desc
    int streak = 1;
    for (int i=0; i<sorted.length-1; i++) {
      final diff = sorted[i].difference(sorted[i+1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break; // streak stops
      }
    }
    return streak;
  }

  double bestGroupSize() {
    if (_series.isEmpty) return 0;
    final positives = _series.where((s)=> s.groupSize > 0).map((e)=> e.groupSize).toList();
    if (positives.isEmpty) return 0;
    positives.sort();
    return positives.first;
  }

  bool lastSeriesIsRecordPoints() {
    if (_series.length < 2) return false;
    final last = _series.last;
    final prevMax = _series.sublist(0, _series.length -1).map((e)=> e.points).fold<int>(0, (a,b)=> b>a? b: a);
    return last.points > prevMax;
  }

  bool lastSeriesIsRecordGroup() {
    if (_series.length < 2) return false;
    final last = _series.last;
    if (last.groupSize <= 0) return false;
    final previous = _series.sublist(0, _series.length -1).where((e)=> e.groupSize > 0).map((e)=> e.groupSize);
    if (previous.isEmpty) return false;
    final prevMin = previous.reduce((a,b)=> a<b? a:b);
    return last.groupSize < prevMin;
  }

  int sessionsThisWeek() {
    final now = _now;
    final start = _startOfWeek(now);
    final end = start.add(const Duration(days:7));
    return SessionFilters.realizedWithDate(sessions)
      .where((s)=> s.date!.isAfter(start.subtract(const Duration(milliseconds:1))) && s.date!.isBefore(end))
      .length;
  }

  int sessionsPreviousWeek() {
    final now = _now;
    final startCurrent = _startOfWeek(now);
    final startPrev = startCurrent.subtract(const Duration(days:7));
    final endPrev = startCurrent;
    return SessionFilters.realizedWithDate(sessions)
      .where((s)=> s.date!.isAfter(startPrev.subtract(const Duration(milliseconds:1))) && s.date!.isBefore(endPrev))
      .length;
  }

  int weeklyLoadDelta() => sessionsThisWeek() - sessionsPreviousWeek();

  DateTime _startOfWeek(DateTime d) {
    // Start Monday
    final int diff = d.weekday - DateTime.monday; // 0 for Monday
    final start = DateTime(d.year, d.month, d.day).subtract(Duration(days: diff));
    return start;
  }

  // Filtered series for charts (distance & category optional)
  // filteredSeries supprimé (filtres retirés de l'UI)
}

extension _SqrtExt on double {
  double sqrtNewton() {
    if (this <= 0) return 0;
    double x = this;
    double guess = this / 2.0;
    for (int i=0;i<6;i++) {
      guess = 0.5 * (guess + x / guess);
    }
    return guess;
  }
}

class _PointBucket {
  final int start;
  final int end;
  final int count;
  _PointBucket({required this.start, required this.end, required this.count});
}
