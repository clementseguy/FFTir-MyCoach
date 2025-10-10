import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/dashboard_data.dart';

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
            const SizedBox(height: 16),
            Expanded(
              child: isLoading ? _buildLoadingChart() : _buildChart(),
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

  Widget _buildChart() {
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
                final index = value.toInt();
                if (index >= 0 && index < data.dataPoints.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
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

  Color _getPrimaryColor() {
    return data.unit == 'pts' ? Colors.amber : Colors.blue;
  }

  Color _getSecondaryColor() {
    return data.unit == 'pts' ? Colors.orange : Colors.lightBlue;
  }
}