import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/shooting_session.dart';
import '../models/dashboard_data.dart';
import '../models/series.dart';
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
    
    // Calculer SMA3 pour les scores (même logique que pour groupement)
    final scoreValues = series.map((s) => s.points.toDouble()).toList();
    final sma3Values = _calculateMovingAverage(scoreValues);
    final sma3Points = sma3Values.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
    
    // Extraire les dates des séries
    final seriesDates = series.map((s) => s.date).toList();
    
    // Extraire les indices de série dans la session
    final seriesIndices = series.map((s) => s.seriesIndexInSession).toList();
    
    final minY = _calculateMinY(series.map((s) => s.points.toDouble()).toList(), buffer: 5.0);
    final maxY = _calculateMaxY(series.map((s) => s.points.toDouble()).toList(), buffer: 5.0);
    
    return EvolutionData(
      dataPoints: dataPoints,
      sma3Points: sma3Points,
      seriesDates: seriesDates,
      seriesIndices: seriesIndices,
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
    
    // Calculer SMA3 pour groupement
    final groupSizeValues = series.map((s) => s.groupSize).toList();
    final sma3Values = _calculateMovingAverage(groupSizeValues);
    final sma3Points = sma3Values.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
    
    // Extraire les dates des séries
    final seriesDates = series.map((s) => s.date).toList();
    
    // Extraire les indices de série dans la session
    final seriesIndices = series.map((s) => s.seriesIndexInSession).toList();
    
    final minY = _calculateMinY(series.map((s) => s.groupSize).toList(), buffer: 1.0);
    final maxY = _calculateMaxY(series.map((s) => s.groupSize).toList(), buffer: 1.0);
    
    return EvolutionData(
      dataPoints: dataPoints,
      sma3Points: sma3Points,
      seriesDates: seriesDates,
      seriesIndices: seriesIndices,
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
  List<double> _calculateMovingAverage(List<double> values) {
    if (values.length <= 1) return values;
    
    final List<double> result = [];
    for (int i = 0; i < values.length; i++) {
      final start = (i - 2) < 0 ? 0 : i - 2; // window de 3
      final subset = values.sublist(start, i + 1);
      final avg = subset.reduce((a, b) => a + b) / subset.length;
      result.add(avg);
    }
    return result;
  }
  
  /// ===== MÉTHODES AVANCÉES =====
  
  /// Génère les données pour les cartes avancées (consistency, progression, catégorie dominante)
  AdvancedStatsData generateAdvancedStats() {
    final consistency = _statsService.consistencyIndexLast30Days();
    final progression = _statsService.progressionPercent30Days();
    
    // Catégorie dominante
    final categoryDist = _statsService.categoryDistribution();
    String? dominantCategory;
    int dominantCount = 0;
    
    if (categoryDist.isNotEmpty) {
      final sorted = categoryDist.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      dominantCategory = sorted.first.key;
      dominantCount = sorted.first.value;
    }
    
    return AdvancedStatsData(
      consistency: consistency,
      progression: progression,
      dominantCategory: dominantCategory,
      dominantCategoryCount: dominantCount,
    );
  }
  
  /// Génère les données de comparaison d'évolution 30j vs 90j
  EvolutionComparisonData generateEvolutionComparison() {
    // Calculer moyennes sur différentes périodes
    final series30 = _statsService.lastNSortedSeriesAsc(1000)
        .where((s) => DateTime.now().difference(s.date).inDays <= 30)
        .toList();
    final series90 = _statsService.lastNSortedSeriesAsc(1000)
        .where((s) => DateTime.now().difference(s.date).inDays <= 90)
        .toList();
    
    final avg30 = series30.isEmpty ? 0.0 : 
        series30.map((s) => s.points).reduce((a, b) => a + b) / series30.length.toDouble();
    final avg90 = series90.isEmpty ? 0.0 : 
        series90.map((s) => s.points).reduce((a, b) => a + b) / series90.length.toDouble();
    
    return EvolutionComparisonData(
      avg30Days: avg30,
      avg90Days: avg90,
      delta: avg30 - avg90,
      title: 'Évolution 30j vs 90j',
    );
  }
  
  /// Génère les données de corrélation Points/Groupement
  CorrelationData generateCorrelationData() {
    final series = _statsService.lastNSortedSeriesAsc(30);
    if (series.isEmpty) {
      return const CorrelationData.empty('Corrélation Points/Groupement');
    }
    
    // Couleurs par session (on utilise l'index de date comme hash simple)
    final sessionColors = <DateTime, Color>{};
    final colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple,
      Colors.teal, Colors.pink, Colors.indigo, Colors.amber, Colors.cyan,
    ];
    
    final points = <CorrelationPoint>[];
    for (int i = 0; i < series.length; i++) {
      final s = series[i];
      if (s.groupSize > 0) { // Exclure groupement invalides
        // Assigner couleur basée sur la date de session
        if (!sessionColors.containsKey(s.date)) {
          final colorIndex = sessionColors.length % colors.length;
          sessionColors[s.date] = colors[colorIndex];
        }
        
        points.add(CorrelationPoint(
          x: s.groupSize,
          y: s.points.toDouble(),
          sessionId: s.date.millisecondsSinceEpoch,
          sessionColor: sessionColors[s.date]!,
          seriesIndex: i,
        ));
      }
    }
    
    final maxX = points.isEmpty ? 50.0 : 
        (points.map((p) => p.x).reduce((a, b) => a > b ? a : b) + 5.0);
    final maxY = points.isEmpty ? 55.0 : 55.0; // Fixe selon spec
    
    return CorrelationData(
      points: points,
      maxX: maxX,
      maxY: maxY,
      title: 'Corrélation Points/Groupement',
    );
  }

  /// Génère les données d'évolution pour les séries d'une méthode de prise spécifique
  /// Retourne un tuple avec les données de points et de groupement
  (EvolutionData, EvolutionData) generateHandMethodEvolutionData(HandMethod handMethod) {
    final allSeries = _statsService.lastNSortedSeriesAsc(30);
    
    // Filtrer les séries selon la méthode de prise
    final filteredSeries = allSeries.where((stat) {
      return stat.handMethod == handMethod;
    }).toList();
    
    // Construire les données de points
    final List<FlSpot> pointsData = [];
    final List<DateTime> pointsDates = [];
    final List<int> pointsIndices = [];
    
    // Construire les données de groupement  
    final List<FlSpot> groupSizeData = [];
    final List<DateTime> groupSizeDates = [];
    final List<int> groupSizeIndices = [];
    
    for (int i = 0; i < filteredSeries.length; i++) {
      final stat = filteredSeries[i];
      
      // Points
      pointsData.add(FlSpot(i.toDouble(), stat.points.toDouble()));
      pointsDates.add(stat.date);
      pointsIndices.add(stat.seriesIndexInSession);
      
      // Groupement (seulement si > 0)
      if (stat.groupSize > 0) {
        groupSizeData.add(FlSpot(i.toDouble(), stat.groupSize));
        groupSizeDates.add(stat.date);
        groupSizeIndices.add(stat.seriesIndexInSession);
      }
    }
    
    // Créer les EvolutionData avec des titres adaptés
    final handMethodLabel = handMethod == HandMethod.oneHand ? '1 main' : '2 mains';
    final pointsEvolution = _createEvolutionData(
      pointsData, 
      pointsDates, 
      pointsIndices, 
      'Points - $handMethodLabel', 
      'pts'
    );
    
    final groupSizeEvolution = _createEvolutionData(
      groupSizeData, 
      groupSizeDates, 
      groupSizeIndices, 
      'Groupement - $handMethodLabel', 
      'cm'
    );
    
    return (pointsEvolution, groupSizeEvolution);
  }

  /// Génère les données d'évolution pour les séries à 2 mains (méthode de compatibilité)
  (EvolutionData, EvolutionData) generateTwoHandsEvolutionData() {
    return generateHandMethodEvolutionData(HandMethod.twoHands);
  }

  /// Méthode utilitaire pour créer un EvolutionData
  EvolutionData _createEvolutionData(
    List<FlSpot> dataPoints,
    List<DateTime> seriesDates,
    List<int> seriesIndices,
    String title,
    String unit,
  ) {
    if (dataPoints.isEmpty) {
      return EvolutionData.empty(title, unit);
    }
    
    final values = dataPoints.map((p) => p.y).toList();
    final minY = _calculateMinY(values, buffer: unit == 'pts' ? 2.0 : 1.0);
    final maxY = _calculateMaxY(values, buffer: unit == 'pts' ? 2.0 : 1.0);
    
    return EvolutionData(
      dataPoints: dataPoints,
      sma3Points: [], // Pas de tendance selon les contraintes
      seriesDates: seriesDates,
      seriesIndices: seriesIndices,
      title: title,
      unit: unit,
      minY: minY,
      maxY: maxY,
    );
  }
}