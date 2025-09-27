import 'package:flutter/material.dart';
import '../services/goal_service.dart';
import '../models/goal.dart';
import '../screens/goals_list_screen.dart';

class GoalsSummaryCard extends StatefulWidget {
  const GoalsSummaryCard({super.key});
  @override
  State<GoalsSummaryCard> createState() => _GoalsSummaryCardState();
}

class _GoalsSummaryCardState extends State<GoalsSummaryCard> {
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
    all.sort((a,b){
      final pa = a.lastProgress ?? 0;
      final pb = b.lastProgress ?? 0;
      return pb.compareTo(pa);
    });
    setState(() {
      _top = all.isNotEmpty ? all.first : null;
      _loading = false;
    });
  }

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
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(_top!.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      _ProgressBar(progress: _top!.lastProgress ?? 0),
                      const SizedBox(height: 4),
                      Text(_subtitleFor(_top!), style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoalsListScreen())),
                          child: const Text('Tous les objectifs'),
                        ),
                      )
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
