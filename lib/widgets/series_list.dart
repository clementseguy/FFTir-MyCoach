import 'package:flutter/material.dart';
import '../models/series.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...series.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          return Card(
            color: Colors.blueGrey[900],
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Série ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Nombre de coups : ${s.shotCount}') ,
                  Text('Distance : ${s.distance} m'),
                  Text('Points : ${s.points}'),
                  Text('Groupement : ${s.groupSize} cm'),
                  if (s.comment.toString().isNotEmpty)
                    Text('Commentaire : ${s.comment}'),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
