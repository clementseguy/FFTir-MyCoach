import '../services/stats_contract.dart';

/// Interface pour le service de calcul des statistiques roulantes
abstract class IRollingStatsService extends RollingStatsCalculator {
  /// Calcule les statistiques roulantes (30j vs 60j)
  @override
  Future<RollingStatsSnapshot> compute();
}