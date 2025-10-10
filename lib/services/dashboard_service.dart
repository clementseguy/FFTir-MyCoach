import 'package:fl_chart/fl_chart.dart';
import '../models/shooting_session.dart';
import '../models/dashboard_data.dart';
import '../services/stats_service.dart';

/// Service responsable de l'agrégation des données pour le dashboard
/// Utilise StatsService existant et transforme les données pour les widgets
class DashboardService {
  final StatsService _statsService;
  
  DashboardService(List<ShootingSession> sessions, {DateTime? now})
      : _statsService = StatsService(sessions, now: now);
  
  /// Génère les données du récapitulatif (5 cartes)
  DashboardSummary generateSummary() {
    final avgPoints = _statsService.averagePointsLast30Days();
    final avgGroupSize = _statsService.averageGroupSizeLast30Days();
    final bestSerie = _statsService.bestSeriesByPoints();
    final bestGroupSize = _statsService.bestGroupSize();
    final sessionsMonth = _statsService.sessionsCountCurrentMonth();
    
    return DashboardSummary(
      avgPoints30Days: avgPoints,
      avgGroupSize30Days: avgGroupSize,
      bestScore: bestSerie?.points ?? 0,
      bestGroupSize: bestGroupSize,
      sessionsThisMonth: sessionsMonth,
      hasBestScore: bestSerie != null,
      hasBestGroupSize: bestGroupSize > 0,
    );
  }
  
  /// Génère les données d'évolution des scores (30 dernières séries)
  EvolutionData generateScoreEvolution() {
    final series = _statsService.lastNSortedSeriesAsc(30);
    if (series.isEmpty) {
      return const EvolutionData.empty('Évolution Score', 'pts');
    }
    
    final dataPoints = series.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.points.toDouble());
    }).toList();
    
    final sma3Values = _statsService.movingAveragePoints(window: 3);
    final sma3Points = sma3Values.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
    
    final minY = _calculateMinY(series.map((s) => s.points.toDouble()).toList(), buffer: 5.0);
    final maxY = _calculateMaxY(series.map((s) => s.points.toDouble()).toList(), buffer: 5.0);
    
    return EvolutionData(
      dataPoints: dataPoints,
      sma3Points: sma3Points,
      title: 'Évolution Score',
      unit: 'pts',
      minY: minY,
      maxY: maxY,
    );
  }
  
  /// Génère les données d'évolution du groupement (30 dernières séries)
  EvolutionData generateGroupSizeEvolution() {
    final series = _statsService.lastNSortedSeriesAsc(30);
    if (series.isEmpty) {
      return const EvolutionData.empty('Évolution Groupement', 'cm');
    }
    
    final dataPoints = series.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.groupSize);
    }).toList();
    
    // TODO: Implémenter movingAverageGroupSize dans StatsService
    final sma3Values = _calculateGroupSizeSMA3(series);
    final sma3Points = sma3Values.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
    
    final minY = _calculateMinY(series.map((s) => s.groupSize).toList(), buffer: 1.0);
    final maxY = _calculateMaxY(series.map((s) => s.groupSize).toList(), buffer: 1.0);
    
    return EvolutionData(
      dataPoints: dataPoints,
      sma3Points: sma3Points,
      title: 'Évolution Groupement',
      unit: 'cm',
      minY: minY,
      maxY: maxY,
    );
  }
  
  /// Génère la répartition des catégories (toutes sessions)
  DistributionData generateCategoryDistribution() {
    final distribution = _statsService.categoryDistribution(sessionsOnly: true);
    if (distribution.isEmpty) {
      return const DistributionData.empty('Répartition Catégories');
    }
    
    final total = distribution.values.fold(0, (sum, count) => sum + count);
    final percentageData = <String, double>{};
    
    distribution.forEach((category, count) {
      percentageData[_formatCategoryLabel(category)] = (count / total) * 100;
    });
    
    return DistributionData(
      data: percentageData,
      title: 'Répartition Catégories',
      isPercentage: true,
    );
  }
  
  /// Génère la distribution des points (30 dernières séries, buckets de 10)
  PointsHistogramData generatePointsDistribution() {
    final buckets = _statsService.pointBuckets(bucketSize: 10, last30: true);
    if (buckets.isEmpty) {
      return const PointsHistogramData.empty('Distribution Points');
    }
    
    final histogramBuckets = buckets.map<HistogramBucket>((bucket) {
      final start = bucket.start.toDouble();
      final end = bucket.end.toDouble();
      final label = '${bucket.start}-${bucket.end}';
      
      return HistogramBucket(
        label: label,
        count: bucket.count,
        startValue: start,
        endValue: end,
      );
    }).toList();
    
    return PointsHistogramData(
      buckets: histogramBuckets,
      title: 'Distribution Points',
    );
  }
  
  /// Génère la répartition des distances (30 derniers jours)
  DistributionData generateDistanceDistribution() {
    final distribution = _statsService.distanceDistribution(last30: true);
    if (distribution.isEmpty) {
      return const DistributionData.empty('Répartition Distances');
    }
    
    final total = distribution.values.fold(0, (sum, count) => sum + count);
    final percentageData = <String, double>{};
    
    distribution.forEach((distance, count) {
      percentageData['${distance.toInt()}m'] = (count / total) * 100;
    });
    
    return DistributionData(
      data: percentageData,
      title: 'Répartition Distances',
      isPercentage: true,
    );
  }
  
  // Méthodes utilitaires
  
  double _calculateMinY(List<double> values, {double buffer = 0.0}) {
    if (values.isEmpty) return 0.0;
    final min = values.reduce((a, b) => a < b ? a : b);
    return (min - buffer).clamp(0.0, double.infinity);
  }
  
  double _calculateMaxY(List<double> values, {double buffer = 0.0}) {
    if (values.isEmpty) return 50.0;
    final max = values.reduce((a, b) => a > b ? a : b);
    return max + buffer;
  }
  
  String _formatCategoryLabel(String category) {
    switch (category) {
      case 'entraînement':
        return 'Entraînement';
      case 'match':
        return 'Match';
      case 'test matériel':
        return 'Test Matériel';
      default:
        return category.isNotEmpty 
            ? category[0].toUpperCase() + category.substring(1)
            : category;
    }
  }
  
  /// Calcule SMA3 pour le groupement (temporaire jusqu'à ajout dans StatsService)
  List<double> _calculateGroupSizeSMA3(List<SeriesStat> series) {
    if (series.isEmpty || series.length <= 1) {
      return series.map((s) => s.groupSize).toList();
    }
    
    final List<double> result = [];
    final values = series.map((s) => s.groupSize).toList();
    
    for (int i = 0; i < values.length; i++) {
      final start = (i - 2) < 0 ? 0 : i - 2; // window de 3
      final subset = values.sublist(start, i + 1);
      final avg = subset.reduce((a, b) => a + b) / subset.length;
      result.add(avg);
    }
    return result;
  }
}