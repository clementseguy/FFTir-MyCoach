import 'package:flutter/material.dart';
import '../services/exercise_service.dart';
import '../models/exercise.dart';
import '../screens/exercises_list_screen.dart';

/// Carte récap Exercices pour l'écran "Exercices & Objectifs" (EX15 / EX16):
/// - Total des exercices
/// - Répartition par type (chips)
/// - Bouton d'accès à la liste complète
class ExercisesAtGlanceCard extends StatefulWidget {
  const ExercisesAtGlanceCard({super.key});
  @override
  State<ExercisesAtGlanceCard> createState() => _ExercisesAtGlanceCardState();
}

class _ExercisesAtGlanceCardState extends State<ExercisesAtGlanceCard> {
  final ExerciseService _service = ExerciseService();
  late Future<List<Exercise>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.listAll();
  }

  Future<void> _refresh() async {
    setState(() { _future = _service.listAll(); });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Exercise>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            final list = snap.data ?? const <Exercise>[];
            final total = list.length;
            final byType = <ExerciseType, int>{};
            for (final e in list) {
              byType[e.type] = (byType[e.type] ?? 0) + 1;
            }
            List<Widget> chips = byType.entries.map((e) {
              final label = () {
                switch (e.key) {
                  case ExerciseType.stand: return 'Stand';
                  case ExerciseType.home: return 'Maison';
                }
              }();
              return _CountChip(label: label, value: e.value);
            }).toList()
              ..sort((a,b)=>0); // stable, already good order (enum order)

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fitness_center, color: Colors.lightBlueAccent),
                    const SizedBox(width: 8),
                    const Text('Exercices', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const ExercisesListScreen()))
                        .then((_) => _refresh()),
                      icon: const Icon(Icons.list_alt),
                      label: const Text('Tous'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('$total', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    const Text('au total'),
                  ],
                ),
                const SizedBox(height: 12),
                if (chips.isEmpty)
                  const Text('Aucun exercice créé.', style: TextStyle(fontSize: 13))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: chips,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int value;
  const _CountChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final color = Colors.blueAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4))
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
