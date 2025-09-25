import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PointsLineChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spots = [
      FlSpot(0, 38),
      FlSpot(1, 42),
      FlSpot(2, 45),
      FlSpot(3, 44),
      FlSpot(4, 47),
      FlSpot(5, 49),
    ];
    return LineChart(
      LineChartData(
        backgroundColor: Colors.transparent,
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 24),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 5,
        minY: 35,
        maxY: 50,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.amber,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}
