import 'package:flutter/material.dart';
import '../models/series.dart';
import 'series_cards.dart';

/// Liste des séries tirées pour une session.
/// Responsable seulement de l'affichage (pas de logique métier).
class SeriesList extends StatelessWidget {
  final List<Series> series;
  const SeriesList({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const Text('Aucune série.');
    }
    // Determine best points and best (smallest) group size indices
    int? bestPointsIndex;
    int? bestGroupIndex;
    int maxPoints = -1;
    double? minGroup;
    for (var i = 0; i < series.length; i++) {
      final s = series[i];
      if (s.points > maxPoints) { maxPoints = s.points; bestPointsIndex = i; }
      if (s.groupSize > 0) {
        if (minGroup == null || s.groupSize < minGroup) { minGroup = s.groupSize; bestGroupIndex = i; }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...series.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          return SeriesDisplayCard(
            series: s,
            index: i,
            highlightBestPoints: i == bestPointsIndex,
            highlightBestGroup: i == bestGroupIndex,
          );
        }),
      ],
    );
  }
}
