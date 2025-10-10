import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/dashboard_data.dart';

/// Widget réutilisable pour afficher les graphiques Points/Groupement spécifiques à une méthode de prise
class HandSpecificChart extends StatelessWidget {
  final HandSpecificData data;
  final bool isLoading;

  const HandSpecificChart({
    super.key,
    required this.data,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              _buildLoadingState()
            else if (!data.hasData)
              _buildEmptyState()
            else
              _buildChart(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 250,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'Analyse des séries...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final methodName = data.title.contains('1 main') ? '1 main' : '2 mains';
    
    return Container(
      height: 250,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              data.title.contains('1 main') ? Icons.front_hand : Icons.back_hand,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune donnée disponible',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pas de séries à $methodName dans les 30 dernières',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: data.pointsData.isNotEmpty 
              ? data.pointsData.length.toDouble() - 1
              : 10,
          minY: 0,
          maxY: data.maxY,
          lineBarsData: [
            // Courbe des points
            LineChartBarData(
              spots: data.pointsData,
              isCurved: true,
              color: Colors.amber,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 3,
                  color: Colors.amber,
                  strokeColor: Colors.amber.withOpacity(0.8),
                  strokeWidth: 1,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.amber.withOpacity(0.2),
                    Colors.amber.withOpacity(0.05),
                  ],
                ),
              ),
            ),
            // Courbe des groupements (axe Y secondaire simulé)
            if (data.groupSizeData.isNotEmpty)
              LineChartBarData(
                spots: data.groupSizeData.map((spot) {
                  // Normaliser le groupement pour l'afficher sur le même graphique
                  // Convertir range groupement vers range points
                  final normalizedY = (spot.y / data.maxY2) * data.maxY;
                  return FlSpot(spot.x, normalizedY);
                }).toList(),
                isCurved: true,
                color: Colors.blue,
                barWidth: 2,
                dashArray: [5, 3], // Ligne pointillée pour différencier
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 2,
                    color: Colors.blue,
                    strokeColor: Colors.blue.withOpacity(0.8),
                    strokeWidth: 1,
                  ),
                ),
              ),
          ],
          titlesData: FlTitlesData(
            rightTitles: data.groupSizeData.isNotEmpty 
                ? AxisTitles(
                    axisNameWidget: Text(
                      'Groupement (cm)',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: data.maxY2 / 5,
                      getTitlesWidget: (value, meta) {
                        // Convertir la valeur normalisée vers la valeur groupement réelle
                        final realValue = (value / data.maxY) * data.maxY2;
                        if (realValue % (data.maxY2 / 5) == 0) {
                          return Text(
                            realValue.toStringAsFixed(0),
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  )
                : const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              axisNameWidget: Text(
                'Points',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 10,
                getTitlesWidget: (value, meta) {
                  if (value % 10 == 0) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            bottomTitles: AxisTitles(
              axisNameWidget: Text(
                'Séries (chronologique)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  if (value % 5 == 0 && value <= data.pointsData.length) {
                    return Text(
                      (value.toInt() + 1).toString(),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: true,
            horizontalInterval: 10,
            verticalInterval: 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 0.5,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 0.5,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final isPoints = spot.barIndex == 0;
                  if (isPoints) {
                    return LineTooltipItem(
                      'Points: ${spot.y.toInt()}',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  } else {
                    // Reconvertir la valeur normalisée vers groupement réel
                    final realGroupSize = (spot.y / data.maxY) * data.maxY2;
                    return LineTooltipItem(
                      'Groupement: ${realGroupSize.toStringAsFixed(1)} cm',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}