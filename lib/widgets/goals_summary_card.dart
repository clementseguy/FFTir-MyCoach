import 'package:flutter/material.dart';
import '../services/goal_service.dart';
import '../models/goal.dart';
import '../screens/goals_list_screen.dart';

class GoalsSummaryCard extends StatefulWidget {
  const GoalsSummaryCard({super.key});
  @override
  GoalsSummaryCardState createState() => GoalsSummaryCardState();
}

class GoalsSummaryCardState extends State<GoalsSummaryCard> {
  final _service = GoalService();
  bool _loading = true;
  Goal? _top;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.init();
    await _service.recomputeAllProgress();
    final all = await _service.listAll();
    // listAll est déjà trié par priority asc, pour stabilité on re-trie par priority puis progress desc
    all.sort((a,b){
      final pr = a.priority.compareTo(b.priority);
      if (pr != 0) return pr;
      final pa = a.lastProgress ?? 0;
      final pb = b.lastProgress ?? 0;
      return pb.compareTo(pa);
    });
    setState(() {
      _top = all.isNotEmpty ? all.first : null;
      _loading = false;
    });
  }

  // Méthode publique pour rafraîchir depuis l'extérieur
  Future<void> refresh() => _load();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
            : _top == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Objectifs', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Aucun objectif actif.'),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoalsListScreen())),
                          icon: const Icon(Icons.flag),
                          label: const Text('Créer un objectif'),
                        ),
                      )
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flag, color: Colors.amber),
                          const SizedBox(width: 8),
                          const Text('Objectif prioritaire', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.amber.withOpacity(0.4))
                            ),
                            child: Text('#${(_top?.priority ?? 0)+1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber)),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(_top!.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      _ProgressBar(progress: _top!.lastProgress ?? 0),
                      const SizedBox(height: 4),
                      Text(_subtitleFor(_top!), style: TextStyle(color: Colors.white70, fontSize: 12)),
                      // Bouton "Tous les objectifs" supprimé pour éviter le doublon avec le raccourci déjà présent ailleurs.
                    ],
                  ),
      ),
    );
  }

  String _subtitleFor(Goal g) {
    final p = ((g.lastProgress ?? 0) * 100).toStringAsFixed(0);
    final value = g.lastMeasuredValue?.toStringAsFixed(1) ?? '-';
    final target = g.targetValue.toStringAsFixed(1);
    return 'Progression: $p% | Valeur: $value / $target';
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  const _ProgressBar({required this.progress});
  @override
  Widget build(BuildContext context) {
    Color color;
    if (progress >= 0.9) {
      color = Colors.green;
    } else if (progress >= 0.6) {
      color = Colors.amber;
    } else {
      color = Colors.blueGrey;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: progress.clamp(0,1),
        minHeight: 8,
        backgroundColor: Colors.grey[850],
        color: color,
      ),
    );
  }
}
