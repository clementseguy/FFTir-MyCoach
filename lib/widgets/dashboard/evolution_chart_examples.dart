import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'evolution_chart.dart';
import '../../models/dashboard_data.dart';

/// Exemples d'utilisation du composant EvolutionChart réfactoré
class EvolutionChartExamples {
  
  /// Exemple d'utilisation simple (ancienne API maintenue)
  static Widget singleCurveExample(EvolutionData data) {
    return EvolutionChart.single(
      data: data,
      showTrend: true,
    );
  }
  
  /// Exemple avec deux courbes sur le même axe Y
  static Widget dualCurveSameAxisExample(EvolutionData pointsData, EvolutionData groupSizeData) {
    return EvolutionChart(
      title: 'Points vs Groupement',
      curves: [
        EvolutionCurveConfig(
          data: pointsData,
          color: Colors.amber,
          label: 'Points',
          showTrend: true,
          trendColor: Colors.deepOrange,
        ),
        EvolutionCurveConfig(
          data: groupSizeData,
          color: Colors.blue,
          label: 'Groupement',
          showTrend: true,
          trendColor: Colors.red,
        ),
      ],
    );
  }
  
  /// Exemple avec deux courbes sur des axes Y différents
  static Widget dualCurveDifferentAxisExample(EvolutionData pointsData, EvolutionData frequencyData) {
    return EvolutionChart(
      title: 'Points (gauche) vs Fréquence (droite)',
      curves: [
        EvolutionCurveConfig(
          data: pointsData,
          color: Colors.green,
          label: 'Points',
          showTrend: false,
          useRightAxis: false, // Axe gauche
        ),
        EvolutionCurveConfig(
          data: frequencyData,
          color: Colors.purple,
          label: 'Fréquence',
          showTrend: true,
          trendColor: Colors.deepPurple,
          useRightAxis: true, // Axe droit
        ),
      ],
    );
  }
  
  /// Exemple avec trois courbes (cas d'usage avancé)
  static Widget tripleCurveExample(EvolutionData pointsData, EvolutionData groupSizeData, EvolutionData confidenceData) {
    return EvolutionChart(
      title: 'Analyse complète',
      curves: [
        EvolutionCurveConfig(
          data: pointsData,
          color: Colors.amber,
          label: 'Points',
          showTrend: true,
          useRightAxis: false,
        ),
        EvolutionCurveConfig(
          data: groupSizeData,
          color: Colors.blue,
          label: 'Groupement',
          showTrend: false,
          useRightAxis: false,
        ),
        EvolutionCurveConfig(
          data: confidenceData,
          color: Colors.red,
          label: 'Confiance',
          showTrend: true,
          trendColor: Colors.pink,
          useRightAxis: true, // Axe droit pour une unité différente
        ),
      ],
    );
  }
  
  /// Crée des données de test pour les exemples
  static EvolutionData createSampleData(String title, String unit, List<double> values) {
    final dataPoints = values.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
    
    final dates = List.generate(values.length, (index) {
      return DateTime.now().subtract(Duration(days: values.length - index - 1));
    });
    
    final seriesIndices = List.generate(values.length, (index) => index);
    
    final minY = values.reduce((a, b) => a < b ? a : b) - 5;
    final maxY = values.reduce((a, b) => a > b ? a : b) + 5;
    
    return EvolutionData(
      dataPoints: dataPoints,
      sma3Points: [], // Calculé automatiquement si nécessaire
      seriesDates: dates,
      seriesIndices: seriesIndices,
      title: title,
      unit: unit,
      minY: minY,
      maxY: maxY,
    );
  }
}