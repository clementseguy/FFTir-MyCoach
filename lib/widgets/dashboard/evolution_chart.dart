import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/dashboard_data.dart';
import '../../utils/mobile_utils.dart';

/// Widget réutilisable pour afficher l'évolution des scores ou groupements
class EvolutionChart extends StatelessWidget {
  final EvolutionData data;
  final bool isLoading;
  
  const EvolutionChart({
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
        height: 300,
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
            const SizedBox(height: 8),
            // Légende pour améliorer la lisibilité
            _buildLegend(context),
            const SizedBox(height: 12),
            Expanded(
              child: isLoading ? _buildLoadingChart() : _buildChart(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingChart() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    if (data.dataPoints.isEmpty) {
      return _buildEmptyState();
    }

    return LineChart(
      LineChartData(
        backgroundColor: Colors.transparent,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (data.maxY - data.minY) / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        // Configuration des tooltips améliorés
        lineTouchData: LineTouchData(
          enabled: !MobileUtils.isMobile(context), // Désactiver sur mobile pour éviter les interactions non voulues
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                // Déterminer quelle courbe est touchée
                final isMainData = touchedSpot.barIndex == 0;
                final curveName = isMainData 
                    ? (data.unit == 'pts' ? 'Points' : 'Groupement')
                    : 'Tendance SMA3';
                
                return LineTooltipItem(
                  '$curveName\n${touchedSpot.y.toStringAsFixed(1)}${data.unit}',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}${data.unit}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: data.dataPoints.length > 10 
                  ? (data.dataPoints.length / 5).ceil().toDouble()
                  : 1,
              getTitlesWidget: (value, meta) {
                return _buildDateLabel(value.toInt());
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        minX: 0,
        maxX: (data.dataPoints.length - 1).toDouble(),
        minY: data.minY,
        maxY: data.maxY,
        lineBarsData: [
          // Courbe principale (données)
          LineChartBarData(
            spots: data.dataPoints,
            isCurved: false,
            color: _getPrimaryColor(),
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 3,
                color: _getPrimaryColor(),
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(show: false),
          ),
          // Courbe SMA3 (tendance) - temporairement désactivée pour Evolution Score
          if (data.sma3Points.isNotEmpty && data.title != 'Évolution Score')
            LineChartBarData(
              spots: data.sma3Points,
              isCurved: true,
              color: _getSecondaryColor(),
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: _getSecondaryColor().withValues(alpha: 0.1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
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
              Icons.show_chart,
              size: 48,
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
            SizedBox(height: 4),
            Text(
              'Ajoutez des séries pour voir l\'évolution',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la légende pour améliorer la lisibilité
  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(
          color: _getPrimaryColor(),
          label: data.unit == 'pts' ? 'Points' : 'Groupement',
        ),
        const SizedBox(width: 16),
        if (data.sma3Points.isNotEmpty && data.title != 'Évolution Score')
          _LegendItem(
            color: _getSecondaryColor(),
            label: 'Tendance SMA3',
          ),
      ],
    );
  }

  Color _getPrimaryColor() {
    return data.unit == 'pts' ? Colors.amber : Colors.blue;
  }

  Color _getSecondaryColor() {
    // Amélioration du contraste pour meilleure lisibilité - SMA3 plus contrastée
    return data.unit == 'pts' ? Colors.deepOrange : Colors.red.shade700;
  }

  /// Construit l'étiquette de date avec déduplication intelligente
  Widget _buildDateLabel(int index) {
    if (index < 0 || index >= data.seriesDates.length) {
      return const SizedBox.shrink();
    }
    
    final currentDate = data.seriesDates[index];
    
    // Afficher la date seulement si c'est la première série de cette date
    bool shouldShowDate = true;
    if (index > 0) {
      final previousDate = data.seriesDates[index - 1];
      // Si même jour que la série précédente, ne pas afficher
      if (_isSameDay(currentDate, previousDate)) {
        shouldShowDate = false;
      }
    }
    
    if (!shouldShowDate) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '${currentDate.day}/${currentDate.month}',
        style: const TextStyle(fontSize: 9),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  /// Vérifie si deux dates sont le même jour
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }



}

/// Widget pour un élément de légende
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}