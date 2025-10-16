import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:developer' as developer;
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
              interval: 5, // Afficher 1 label sur 5
              getTitlesWidget: (value, meta) {
                return _buildDateIndexLabel(value.toInt());
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
          // Courbe SMA3 (tendance)
          if (data.sma3Points.isNotEmpty)
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
        if (data.sma3Points.isNotEmpty)
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

  /// Construit un label au format DD/MM[index] pour l'axe X.
  ///
  /// Affiche 1 label sur 5 (géré par `interval`) et échoue rapidement
  /// si `seriesDates` est manquant ou incohérent (log + throw).
  Widget _buildDateIndexLabel(int index) {
    // Vérification stricte : on doit avoir des dates pour chaque série
    if (data.seriesDates.isEmpty) {
      developer.log(
        'EvolutionChart: seriesDates is empty for "${data.title}"',
        level: 900, // error
      );
      throw StateError('EvolutionChart: seriesDates missing for "${data.title}"');
    }

    if (data.seriesIndices.isEmpty) {
      developer.log(
        'EvolutionChart: seriesIndices is empty for "${data.title}"',
        level: 900, // error
      );
      throw StateError('EvolutionChart: seriesIndices missing for "${data.title}"');
    }

    if (index < 0 || index >= data.dataPoints.length) {
      return const SizedBox.shrink();
    }

    // Ne pas afficher le dernier label pour éviter l'overflow
    if (index >= data.dataPoints.length - 1) {
      return const SizedBox.shrink();
    }

    if (index >= data.seriesDates.length) {
      developer.log(
        'EvolutionChart: seriesDates length (${data.seriesDates.length}) < required index (${index}) for "${data.title}"',
        level: 900,
      );
      throw RangeError.index(index, data.seriesDates, 'seriesDates',
          'Index out of range for seriesDates');
    }

    if (index >= data.seriesIndices.length) {
      developer.log(
        'EvolutionChart: seriesIndices length (${data.seriesIndices.length}) < required index (${index}) for "${data.title}"',
        level: 900,
      );
      throw RangeError.index(index, data.seriesIndices, 'seriesIndices',
          'Index out of range for seriesIndices');
    }

    final dt = data.seriesDates[index];
    final seriesIndexInSession = data.seriesIndices[index];
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final label = '$day/$month[$seriesIndexInSession]';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        label,
        style: const TextStyle(fontSize: 9),
        textAlign: TextAlign.center,
      ),
    );
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