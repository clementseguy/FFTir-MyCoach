import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../utils/mobile_utils.dart';
import 'stat_card.dart';

/// Widget affichant les 5 cartes de récapitulatif du dashboard
class StatsSummaryCards extends StatelessWidget {
  final DashboardSummary summary;
  final bool isLoading;
  
  const StatsSummaryCards({
    super.key,
    required this.summary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _LoadingCards();
    }
    
    // Adaptation responsive pour optimiser l'espace écran
    final spacing = MobileUtils.getSpacing(context);
    final isMobile = MobileUtils.isMobile(context);
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isMobile ? 2.2 : 1.6, // Encore plus compactes pour maximiser l'espace
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      children: [
        StatCard(
          title: 'Meilleur Score',
          value: summary.hasBestScore ? '${summary.bestScore}' : '-',
          unit: summary.hasBestScore ? 'pts' : '',
          icon: Icons.star,
          color: Colors.orange,
        ),
        StatCard(
          title: 'Meilleur Groupement',
          value: summary.hasBestGroupSize ? '${summary.bestGroupSize.toStringAsFixed(1)}' : '-',
          unit: summary.hasBestGroupSize ? 'cm' : '',
          icon: Icons.track_changes,
          color: Colors.green,
        ),
        StatCard(
          title: 'Moyenne Points 30j',
          value: '${summary.avgPoints30Days.toStringAsFixed(1)}',
          unit: 'pts',
          icon: Icons.trending_up,
          color: Colors.amber,
        ),
        StatCard(
          title: 'Groupement Moy. 30j', 
          value: '${summary.avgGroupSize30Days.toStringAsFixed(1)}',
          unit: 'cm',
          icon: Icons.center_focus_strong,
          color: Colors.blue,
        )
      ],
    );
  }
}

class _LoadingCards extends StatelessWidget {
  const _LoadingCards();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: List.generate(4, (index) => const StatCardLoading()),
    );
  }
}