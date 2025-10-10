import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';

/// Widget affichant la comparaison des moyennes 30j vs 90j
class EvolutionComparisonWidget extends StatelessWidget {
  final EvolutionComparisonData? data;
  final bool isLoading;

  const EvolutionComparisonWidget({
    super.key,
    this.data,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    final evolutionData = data ?? const EvolutionComparisonData.empty('Évolution 30j vs 90j');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              evolutionData.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildComparisonContent(context, evolutionData),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Card(
      child: Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'Calcul des évolutions...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonContent(BuildContext context, EvolutionComparisonData data) {
    if (data.avg30Days == 0 && data.avg90Days == 0) {
      return Container(
        height: 150,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Pas assez de données pour calculer les évolutions',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Barres de comparaison
        Row(
          children: [
            Expanded(
              child: _buildComparisonBar(
                context,
                '30 jours',
                data.avg30Days,
                data.avg30Days >= data.avg90Days ? Colors.green : Colors.blue,
                data.avg30Days,
                max(data.avg30Days, data.avg90Days),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildComparisonBar(
                context,
                '90 jours',
                data.avg90Days,
                data.avg90Days >= data.avg30Days ? Colors.green : Colors.grey,
                data.avg90Days,
                max(data.avg30Days, data.avg90Days),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Delta
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getDeltaColor(data.delta).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getDeltaColor(data.delta).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Évolution',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Icon(
                    _getDeltaIcon(data.delta),
                    color: _getDeltaColor(data.delta),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDelta(data.delta),
                    style: TextStyle(
                      color: _getDeltaColor(data.delta),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonBar(
    BuildContext context,
    String label,
    double value,
    Color color,
    double actualValue,
    double maxValue,
  ) {
    final progress = maxValue > 0 ? (actualValue / maxValue).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getDeltaColor(double delta) {
    if (delta > 0) return Colors.green;
    if (delta < 0) return Colors.red;
    return Colors.orange;
  }

  IconData _getDeltaIcon(double delta) {
    if (delta > 0) return Icons.trending_up;
    if (delta < 0) return Icons.trending_down;
    return Icons.trending_flat;
  }

  String _formatDelta(double delta) {
    if (delta > 0) {
      return '+${delta.toStringAsFixed(1)} pts';
    } else if (delta < 0) {
      return '${delta.toStringAsFixed(1)} pts';
    } else {
      return '±0.0 pts';
    }
  }

  double max(double a, double b) => a > b ? a : b;
}