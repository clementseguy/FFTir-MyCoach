import '../models/shooting_session.dart';

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

class StatsService {
  final List<ShootingSession> sessions;
  late final List<SeriesStat> _series; // séries aplaties

  StatsService(this.sessions) {
    _series = _flatten();
  }

  List<SeriesStat> _flatten() {
    final List<SeriesStat> list = [];
    for (final s in sessions) {
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
    final cutoff = DateTime.now().subtract(d);
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
    final now = DateTime.now();
    return sessions.where((s) =>
      s.date != null &&
      s.date!.year == now.year &&
      s.date!.month == now.month
    ).length;
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
}
