import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';

/// Widget affichant les 3 cartes statistiques avancées
/// - Consistency
/// - Progression  
/// - Catégorie dominante
class AdvancedStatsCards extends StatelessWidget {
  final AdvancedStatsData? data;
  final bool isLoading;

  const AdvancedStatsCards({
    super.key,
    this.data,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    final statsData = data ?? const AdvancedStatsData.empty();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Sur mobile : layout vertical si width < 600, sinon horizontal
        final isMobile = constraints.maxWidth < 600;
        
        if (isMobile) {
          return Column(
            children: [
              _buildCard(
                context,
                'Consistency',
                _formatConsistency(statsData.consistency),
                _getConsistencyColor(statsData.consistency),
                Icons.track_changes,
              ),
              const SizedBox(height: 12),
              _buildCard(
                context,
                'Progression',
                _formatProgression(statsData.progression),
                _getProgressionColor(statsData.progression),
                Icons.trending_up,
              ),
              const SizedBox(height: 12),
              _buildCard(
                context,
                'Catégorie dominante',
                _formatDominantCategory(statsData.dominantCategory, statsData.dominantCategoryCount),
                Theme.of(context).colorScheme.primary,
                Icons.category,
              ),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(
                child: _buildCard(
                  context,
                  'Consistency',
                  _formatConsistency(statsData.consistency),
                  _getConsistencyColor(statsData.consistency),
                  Icons.track_changes,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCard(
                  context,
                  'Progression',
                  _formatProgression(statsData.progression),
                  _getProgressionColor(statsData.progression),
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCard(
                  context,
                  'Catégorie dominante',
                  _formatDominantCategory(statsData.dominantCategory, statsData.dominantCategoryCount),
                  Theme.of(context).colorScheme.primary,
                  Icons.category,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 140,
      child: Card(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'Chargement des statistiques...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      height: 140,
      child: Card(
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    icon,
                    color: color.withOpacity(0.7),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
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