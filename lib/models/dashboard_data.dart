import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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
  final List<DateTime> seriesDates; // dates des séries pour affichage axe X
  final List<int> seriesIndices; // indices de série dans la session (1-based)
  final String title;
  final String unit;
  final double minY;
  final double maxY;
  
  const EvolutionData({
    required this.dataPoints,
    required this.sma3Points,
    required this.seriesDates,
    required this.seriesIndices,
    required this.title,
    required this.unit,
    required this.minY,
    required this.maxY,
  });
  
  /// Constructeur pour état vide
  const EvolutionData.empty(String title, String unit)
      : dataPoints = const [],
        sma3Points = const [],
        seriesDates = const [],
        seriesIndices = const [],
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

/// ===== MODÈLES AVANCÉS =====

/// Données pour les cartes statistiques avancées
class AdvancedStatsData {
  final double consistency; // 0-100 ou -1 si pas assez de données
  final double progression; // pourcentage ou NaN si pas assez de données  
  final String? dominantCategory; // null si pas de données
  final int dominantCategoryCount;
  
  const AdvancedStatsData({
    required this.consistency,
    required this.progression,
    required this.dominantCategory,
    required this.dominantCategoryCount,
  });
  
  const AdvancedStatsData.empty()
      : consistency = -1,
        progression = double.nan,
        dominantCategory = null,
        dominantCategoryCount = 0;
}

/// Données pour la comparaison d'évolutions 30j/90j
class EvolutionComparisonData {
  final double avg30Days;
  final double avg90Days;
  final double delta; // avg30 - avg90
  final String title;
  
  const EvolutionComparisonData({
    required this.avg30Days,
    required this.avg90Days,
    required this.delta,
    required this.title,
  });
  
  const EvolutionComparisonData.empty(String title)
      : avg30Days = 0,
        avg90Days = 0,
        delta = 0,
        title = title;
}

/// Point pour le nuage de corrélation
class CorrelationPoint {
  final double x; // groupement
  final double y; // score
  final int sessionId;
  final Color sessionColor;
  final int seriesIndex;
  
  const CorrelationPoint({
    required this.x,
    required this.y,
    required this.sessionId,
    required this.sessionColor,
    required this.seriesIndex,
  });
}

/// Données pour le nuage de corrélation Points/Groupement
class CorrelationData {
  final List<CorrelationPoint> points;
  final double maxX;
  final double maxY;
  final String title;
  
  const CorrelationData({
    required this.points,
    required this.maxX,
    required this.maxY,
    required this.title,
  });
  
  const CorrelationData.empty(String title)
      : points = const [],
        maxX = 50,
        maxY = 55,
        title = title;
}

/// Données pour les graphiques spécifiques à une méthode de prise
class HandSpecificData {
  final List<FlSpot> pointsData; // courbe points
  final List<FlSpot> groupSizeData; // courbe groupement
  final String title;
  final bool hasData; // true si au moins une série avec cette méthode
  final double minY;
  final double maxY;
  final double minY2; // pour groupement
  final double maxY2; // pour groupement
  
  const HandSpecificData({
    required this.pointsData,
    required this.groupSizeData,
    required this.title,
    required this.hasData,
    required this.minY,
    required this.maxY,
    required this.minY2,
    required this.maxY2,
  });
  
  const HandSpecificData.empty(String title)
      : pointsData = const [],
        groupSizeData = const [],
        title = title,
        hasData = false,
        minY = 0,
        maxY = 50,
        minY2 = 0,
        maxY2 = 50;
}