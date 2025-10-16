import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../utils/mobile_utils.dart';
import 'stat_card.dart';

/// Widget affichant les 4 cartes statistiques avancées
/// - Sessions ce mois
/// - Catégorie dominante  
/// - Régularité
/// - Progression
class AdvancedStatsCards extends StatelessWidget {
  final AdvancedStatsData? data;
  final DashboardSummary summary;
  final bool isLoading;

  const AdvancedStatsCards({
    super.key,
    this.data,
    required this.summary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    final statsData = data ?? const AdvancedStatsData.empty();
    
    // Utilisation de la même architecture que StatsSummaryCards
    final spacing = MobileUtils.getSpacing(context);
    final isMobile = MobileUtils.isMobile(context);
    
    return GridView.count(
      crossAxisCount: 2, // 2 colonnes pour 4 cartes
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isMobile ? 2.2 : 1.6, // Même ratio que StatsSummaryCards
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      children: [
        StatCard(
          title: 'Sessions ce mois',
          value: '${summary.sessionsThisMonth}',
          unit: '',
          icon: Icons.calendar_today,
          color: Colors.purple,
        ),
         StatCard(
          title: 'Catégorie dominante',
          value: _formatDominantCategory(statsData.dominantCategory, statsData.dominantCategoryCount),
          unit: '',
          icon: Icons.category,
          color: Theme.of(context).colorScheme.primary,
        ),
        StatCard(
          title: 'Régularité',
          value: _formatConsistency(statsData.consistency),
          unit: '',
          icon: Icons.track_changes,
          color: _getConsistencyColor(statsData.consistency),
        ),
        StatCard(
          title: 'Progression',
          value: _formatProgression(statsData.progression),
          unit: '',
          icon: Icons.trending_up,
          color: _getProgressionColor(statsData.progression),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = MobileUtils.getSpacing(context);
        final isMobile = MobileUtils.isMobile(context);
        
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isMobile ? 2.2 : 1.6,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          children: List.generate(4, (index) => const StatCardLoading()),
        );
      },
    );
  }

  String _formatConsistency(double consistency) {
    if (consistency < 0) return '-';
    return '${consistency.toStringAsFixed(1)}%';
  }

  String _formatProgression(double progression) {
    if (progression.isNaN) return '-';
    final sign = progression >= 0 ? '+' : '';
    return '$sign${progression.toStringAsFixed(1)}%';
  }

  String _formatDominantCategory(String? category, int count) {
    if (category == null) return '-';
    return '$category ($count)';
  }

  Color _getConsistencyColor(double consistency) {
    if (consistency < 0) return Colors.grey;
    if (consistency >= 80) return Colors.green;
    if (consistency >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getProgressionColor(double progression) {
    if (progression.isNaN) return Colors.grey;
    if (progression > 0) return Colors.green;
    if (progression == 0) return Colors.orange;
    return Colors.red;
  }
}
