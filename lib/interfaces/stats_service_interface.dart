import '../services/stats_service.dart';

/// Interface pour le service de calcul des statistiques
abstract class IStatsService {
  /// Moyenne des points sur les 30 derniers jours
  double averagePointsLast30Days();
  
  /// Moyenne de la taille des groupes sur les 30 derniers jours
  double averageGroupSizeLast30Days();
  
  /// Meilleure série par points
  SeriesStat? bestSeriesByPoints();
  
  /// Nombre de sessions dans le mois courant
  int sessionsCountCurrentMonth();
  
  /// Index de consistance sur les 30 derniers jours
  double consistencyIndexLast30Days();
  
  /// Pourcentage de progression sur 30 jours
  double progressionPercent30Days();
  
  /// Distribution des distances
  Map<double, int> distanceDistribution({bool last30 = true});
  
  /// Distribution des catégories
  Map<String, int> categoryDistribution({bool sessionsOnly = true});
  
  /// Buckets de points
  List<dynamic> pointBuckets({int bucketSize = 10, bool last30 = true});
  
  /// Série actuelle de jours consécutifs
  int currentDayStreak();
  
  /// Vérifie si la dernière série est un record de points
  bool lastSeriesIsRecordPoints();
  
  /// Vérifie si la dernière série est un record de groupement
  bool lastSeriesIsRecordGroup();
  
  /// Delta de charge hebdomadaire
  int weeklyLoadDelta();
  
  /// Sessions cette semaine
  int sessionsThisWeek();
  
  /// Sessions la semaine précédente  
  int sessionsPreviousWeek();
  
  /// Meilleure taille de groupe
  double bestGroupSize();
  
  /// Dernières N séries triées par date
  List<SeriesStat> lastNSortedSeriesAsc(int n);
  
  /// Moyenne mobile des points
  List<double> movingAveragePoints({int window = 3});
}