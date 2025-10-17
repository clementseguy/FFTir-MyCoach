import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:developer' as developer;
import '../../models/dashboard_data.dart';
import '../../utils/mobile_utils.dart';

/// Configuration pour une courbe de données
class EvolutionCurveConfig {
  final EvolutionData data;
  final Color color;
  final String label;
  final bool showTrend;
  final Color? trendColor;
  final bool useRightAxis;

  const EvolutionCurveConfig({
    required this.data,
    required this.color,
    required this.label,
    this.showTrend = false,
    this.trendColor,
    this.useRightAxis = false,
  });
}

/// Widget réutilisable pour afficher l'évolution des scores ou groupements
class EvolutionChart extends StatelessWidget {
  final String title;
  final List<EvolutionCurveConfig> curves;
  final bool isLoading;
  
  const EvolutionChart({
    super.key,
    required this.title,
    required this.curves,
    this.isLoading = false,
  });

  // Constructeur de compatibilité pour l'usage existant
  factory EvolutionChart.single({
    Key? key,
    required EvolutionData data,
    bool isLoading = false,
    bool showTrend = false,
  }) {
    return EvolutionChart(
      key: key,
      title: data.title,
      isLoading: isLoading,
      curves: [
        EvolutionCurveConfig(
          data: data,
          color: data.unit == 'pts' ? Colors.amber : Colors.blue,
          label: data.unit == 'pts' ? 'Points' : 'Groupement',
          showTrend: showTrend,
          trendColor: data.unit == 'pts' ? Colors.deepOrange : Colors.red.shade700,
        ),
      ],
    );
  }

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
              title,
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
    if (curves.isEmpty || curves.every((curve) => curve.data.dataPoints.isEmpty)) {
      return _buildEmptyState();
    }

    final hasRightAxis = curves.any((curve) => curve.useRightAxis);
    final leftCurves = curves.where((curve) => !curve.useRightAxis).toList();
    final rightCurves = curves.where((curve) => curve.useRightAxis).toList();

    // Calculer les bornes Y pour chaque axe
    final leftMinY = leftCurves.isNotEmpty 
        ? leftCurves.map((c) => c.data.minY).reduce((a, b) => a < b ? a : b)
        : 0.0;
    final leftMaxY = leftCurves.isNotEmpty
        ? leftCurves.map((c) => c.data.maxY).reduce((a, b) => a > b ? a : b)
        : 100.0;
    
    final rightMinY = rightCurves.isNotEmpty
        ? rightCurves.map((c) => c.data.minY).reduce((a, b) => a < b ? a : b)
        : 0.0;
    final rightMaxY = rightCurves.isNotEmpty
        ? rightCurves.map((c) => c.data.maxY).reduce((a, b) => a > b ? a : b)
        : 100.0;

    // Trouver la courbe avec le plus de points pour les labels X
    final mainCurve = curves.isNotEmpty ? curves.first : null;
    final maxDataPoints = curves.map((c) => c.data.dataPoints.length).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        backgroundColor: Colors.transparent,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: leftCurves.isNotEmpty ? (leftMaxY - leftMinY) / 4 : 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        lineTouchData: LineTouchData(
          enabled: !MobileUtils.isMobile(context),
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final curveIndex = _getCurveIndexFromBarIndex(touchedSpot.barIndex);
                if (curveIndex < curves.length) {
                  final curve = curves[curveIndex];
                  final isTrend = _isTrendBar(touchedSpot.barIndex);
                  final curveName = isTrend ? 'Tendance ${curve.label}' : curve.label;
                  
                  // Dénormaliser la valeur si c'est sur l'axe droit
                  double realValue = touchedSpot.y;
                  if (curve.useRightAxis) {
                    realValue = _denormalizeFromLeftAxis(touchedSpot.y, leftMinY, leftMaxY, rightMinY, rightMaxY);
                  }
                  
                  return LineTooltipItem(
                    '$curveName\n${realValue.toStringAsFixed(1)}${curve.data.unit}',
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
                return null;
              }).where((item) => item != null).cast<LineTooltipItem>().toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: leftCurves.isNotEmpty,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final unit = leftCurves.isNotEmpty ? leftCurves.first.data.unit : '';
                return Text(
                  '${value.toInt()}$unit',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: hasRightAxis && rightCurves.isNotEmpty,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (rightCurves.isEmpty) return const SizedBox.shrink();
                // Dénormaliser la valeur pour afficher la vraie valeur de l'axe droit
                final denormalizedValue = _denormalizeFromLeftAxis(value, leftMinY, leftMaxY, rightMinY, rightMaxY);
                final unit = rightCurves.first.data.unit;
                return Text(
                  '${denormalizedValue.toInt()}$unit',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return _buildDateIndexLabel(value.toInt(), mainCurve?.data);
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (maxDataPoints - 1).toDouble(),
        minY: leftMinY,
        maxY: leftMaxY,
        extraLinesData: ExtraLinesData(),
        lineBarsData: _buildLineBarsData(leftMinY, leftMaxY, rightMinY, rightMaxY),
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
    final legendItems = <Widget>[];
    
    for (final curve in curves) {
      legendItems.add(_LegendItem(
        color: curve.color,
        label: curve.label,
      ));
      
      if (curve.showTrend && curve.data.sma3Points.isNotEmpty) {
        legendItems.add(const SizedBox(width: 8));
        legendItems.add(_LegendItem(
          color: curve.trendColor ?? curve.color.withValues(alpha: 0.7),
          label: 'Tendance ${curve.label}',
        ));
      }
      
      if (curve != curves.last) {
        legendItems.add(const SizedBox(width: 16));
      }
    }
    
    return Wrap(
      alignment: WrapAlignment.center,
      children: legendItems,
    );
  }

  /// Construit les données des courbes pour le graphique
  List<LineChartBarData> _buildLineBarsData(double leftMinY, double leftMaxY, double rightMinY, double rightMaxY) {
    final lineBars = <LineChartBarData>[];
    
    for (final curve in curves) {
      // Normaliser les données selon l'axe utilisé
      final spots = curve.useRightAxis 
          ? _normalizeToLeftAxis(curve.data.dataPoints, curve.data.minY, curve.data.maxY, leftMinY, leftMaxY)
          : curve.data.dataPoints;
      
      // Courbe principale
      lineBars.add(LineChartBarData(
        spots: spots,
        isCurved: false,
        color: curve.color,
        barWidth: 2,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
            radius: 3,
            color: curve.color,
            strokeWidth: 0,
          ),
        ),
        belowBarData: BarAreaData(show: false),
      ));
      
      // Courbe de tendance si activée
      if (curve.showTrend && curve.data.sma3Points.isNotEmpty) {
        final trendSpots = curve.useRightAxis
            ? _normalizeToLeftAxis(curve.data.sma3Points, curve.data.minY, curve.data.maxY, leftMinY, leftMaxY)
            : curve.data.sma3Points;
        
        lineBars.add(LineChartBarData(
          spots: trendSpots,
          isCurved: true,
          color: curve.trendColor ?? curve.color.withValues(alpha: 0.7),
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: (curve.trendColor ?? curve.color).withValues(alpha: 0.1),
          ),
        ));
      }
    }
    
    return lineBars;
  }

  /// Normalise les données de l'axe droit vers l'axe gauche pour l'affichage
  List<FlSpot> _normalizeToLeftAxis(List<FlSpot> spots, double dataMin, double dataMax, double targetMin, double targetMax) {
    if (dataMax == dataMin) return spots; // Éviter division par zéro
    
    return spots.map((spot) {
      final normalizedY = (spot.y - dataMin) / (dataMax - dataMin);
      final targetY = targetMin + normalizedY * (targetMax - targetMin);
      return FlSpot(spot.x, targetY);
    }).toList();
  }

  /// Dénormalise une valeur de l'axe gauche vers l'axe droit pour l'affichage des titres
  double _denormalizeFromLeftAxis(double normalizedValue, double leftMin, double leftMax, double rightMin, double rightMax) {
    if (leftMax == leftMin) return rightMin; // Éviter division par zéro
    
    final normalizedRatio = (normalizedValue - leftMin) / (leftMax - leftMin);
    return rightMin + normalizedRatio * (rightMax - rightMin);
  }

  /// Détermine l'index de la courbe à partir de l'index de la barre
  int _getCurveIndexFromBarIndex(int barIndex) {
    int currentBarIndex = 0;
    for (int i = 0; i < curves.length; i++) {
      if (currentBarIndex == barIndex) return i;
      currentBarIndex++; // Courbe principale
      
      if (curves[i].showTrend && curves[i].data.sma3Points.isNotEmpty) {
        if (currentBarIndex == barIndex) return i;
        currentBarIndex++; // Courbe de tendance
      }
    }
    return 0; // Fallback
  }

  /// Détermine si la barre correspond à une tendance
  bool _isTrendBar(int barIndex) {
    int currentBarIndex = 0;
    for (int i = 0; i < curves.length; i++) {
      if (currentBarIndex == barIndex) return false; // Courbe principale
      currentBarIndex++;
      
      if (curves[i].showTrend && curves[i].data.sma3Points.isNotEmpty) {
        if (currentBarIndex == barIndex) return true; // Courbe de tendance
        currentBarIndex++;
      }
    }
    return false;
  }

  /// Construit un label au format DD/MM[index] pour l'axe X.
  ///
  /// Affiche 1 label sur 5 (géré par `interval`) et échoue rapidement
  /// si `seriesDates` est manquant ou incohérent (log + throw).
  Widget _buildDateIndexLabel(int index, EvolutionData? data) {
    if (data == null) return const SizedBox.shrink();
    
    // Vérification stricte : on doit avoir des dates pour chaque série
    if (data.seriesDates.isEmpty) {
      developer.log(
        'EvolutionChart: seriesDates is empty for "$title"',
        level: 900, // error
      );
      throw StateError('EvolutionChart: seriesDates missing for "$title"');
    }

    if (data.seriesIndices.isEmpty) {
      developer.log(
        'EvolutionChart: seriesIndices is empty for "$title"',
        level: 900, // error
      );
      throw StateError('EvolutionChart: seriesIndices missing for "$title"');
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
        'EvolutionChart: seriesDates length (${data.seriesDates.length}) < required index ($index) for "$title"',
        level: 900,
      );
      throw RangeError.index(index, data.seriesDates, 'seriesDates',
          'Index out of range for seriesDates');
    }

    if (index >= data.seriesIndices.length) {
      developer.log(
        'EvolutionChart: seriesIndices length (${data.seriesIndices.length}) < required index ($index) for "$title"',
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