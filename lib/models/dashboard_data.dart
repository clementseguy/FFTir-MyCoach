import 'package:fl_chart/fl_chart.dart';

/// Modèle de données pour le récapitulatif dashboard (5 cartes)
class DashboardSummary {
  final double avgPoints30Days;
  final double avgGroupSize30Days;
  final int bestScore;
  final double bestGroupSize;
  final int sessionsThisMonth;
  final bool hasBestScore;
  final bool hasBestGroupSize;
  
  const DashboardSummary({
    required this.avgPoints30Days,
    required this.avgGroupSize30Days,
    required this.bestScore,
    required this.bestGroupSize,
    required this.sessionsThisMonth,
    required this.hasBestScore,
    required this.hasBestGroupSize,
  });
  
  /// Constructeur pour état vide
  const DashboardSummary.empty()
      : avgPoints30Days = 0.0,
        avgGroupSize30Days = 0.0,
        bestScore = 0,
        bestGroupSize = 0.0,
        sessionsThisMonth = 0,
        hasBestScore = false,
        hasBestGroupSize = false;
}

/// Modèle pour les données d'évolution (graphiques score/groupement)
class EvolutionData {
  final List<FlSpot> dataPoints;
  final List<FlSpot> sma3Points;
  final String title;
  final String unit;
  final double minY;
  final double maxY;
  
  const EvolutionData({
    required this.dataPoints,
    required this.sma3Points,
    required this.title,
    required this.unit,
    required this.minY,
    required this.maxY,
  });
  
  /// Constructeur pour état vide
  const EvolutionData.empty(String title, String unit)
      : dataPoints = const [],
        sma3Points = const [],
        title = title,
        unit = unit,
        minY = 0.0,
        maxY = 50.0;
}

/// Modèle pour les distributions (catégories, distances, points)
class DistributionData {
  final Map<String, double> data; // label -> valeur (% ou count)
  final String title;
  final bool isPercentage;
  
  const DistributionData({
    required this.data,
    required this.title,
    required this.isPercentage,
  });
  
  /// Constructeur pour état vide
  const DistributionData.empty(String title, {bool isPercentage = true})
      : data = const {},
        title = title,
        isPercentage = isPercentage;
}

/// Données pour l'histogramme points
class PointsHistogramData {
  final List<HistogramBucket> buckets;
  final String title;
  
  const PointsHistogramData({
    required this.buckets,
    required this.title,
  });
  
  const PointsHistogramData.empty(String title)
      : buckets = const [],
        title = title;
}

class HistogramBucket {
  final String label; // "0-10", "11-20", etc.
  final int count;
  final double startValue;
  final double endValue;
  
  const HistogramBucket({
    required this.label,
    required this.count,
    required this.startValue,
    required this.endValue,
  });
}