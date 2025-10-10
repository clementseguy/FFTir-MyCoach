import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';

/// Widget pour afficher les répartitions sous forme de barres horizontales (flat bar)
class DistributionBar extends StatelessWidget {
  final DistributionData data;
  final bool isLoading;
  
  const DistributionBar({
    super.key,
    required this.data,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              data.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (isLoading)
              _buildLoadingBars()
            else if (data.data.isEmpty)
              _buildEmptyState()
            else
              _buildDistributionBars(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBars() {
    return Column(
      children: List.generate(3, (index) => 
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart,
              size: 32,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'Aucune donnée disponible',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionBars() {
    final entries = data.data.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value)); // Tri par valeur décroissante
    
    return Column(
      children: entries.map((entry) => _buildBar(entry.key, entry.value)).toList(),
    );
  }

  Widget _buildBar(String label, double value) {
    final percentage = data.isPercentage ? value : (value / _getTotalValue()) * 100;
    final color = _getColorForLabel(label);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                data.isPercentage 
                    ? '${percentage.toStringAsFixed(1)}%'
                    : '${value.toInt()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: percentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _getTotalValue() {
    return data.data.values.fold(0.0, (sum, value) => sum + value);
  }

  Color _getColorForLabel(String label) {
    // Couleurs pour les différents types de données
    if (label.contains('Entraînement')) return Colors.blue;
    if (label.contains('Match')) return Colors.red;
    if (label.contains('Test')) return Colors.orange;
    if (label.contains('10m')) return Colors.green;
    if (label.contains('25m')) return Colors.orange;
    if (label.contains('50m')) return Colors.red;
    
    // Couleurs par défaut basées sur l'index (hash du label)
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    
    return colors[label.hashCode % colors.length];
  }
}