import 'package:flutter/material.dart';
import '../services/exercise_service.dart';
import '../models/exercise.dart';

/// Carte simple affichant le nombre total d'exercices.
/// Rafraîchissable via un FutureBuilder interne.
class ExercisesTotalCard extends StatefulWidget {
  final EdgeInsetsGeometry? padding;
  const ExercisesTotalCard({super.key, this.padding});
  @override
  State<ExercisesTotalCard> createState() => _ExercisesTotalCardState();
}

class _ExercisesTotalCardState extends State<ExercisesTotalCard> {
  final ExerciseService _service = ExerciseService();
  late Future<List<Exercise>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.listAll();
  }

  Future<void> refresh() async {
    setState(() { _future = _service.listAll(); });
  }

  @override
  Widget build(BuildContext context) {
    final pad = widget.padding ?? const EdgeInsets.all(0);
    return Padding(
      padding: pad,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<List<Exercise>>(
            future: _future,
            builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 64,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                final total = snap.data?.length ?? 0;
                return Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(14),
                      child: const Icon(Icons.fitness_center, color: Colors.lightBlueAccent, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Exercices', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text('$total au total', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                );
            },
          ),
        ),
      ),
    );
  }
}
