import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';

/// Carte listant tous les objectifs actifs avec progression (Lot B)
class MultiGoalCard extends StatefulWidget {
  const MultiGoalCard({super.key});
  @override
  MultiGoalCardState createState() => MultiGoalCardState();
}

class MultiGoalCardState extends State<MultiGoalCard> {
  final _service = GoalService();
  bool _loading = true;
  List<Goal> _activeGoals = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    await _service.init();
    await _service.recomputeAllProgress();
    final all = await _service.listAll();
    final active = all.where((g) => g.status == GoalStatus.active).toList();
    active.sort((a,b){
      final pa = a.lastProgress ?? 0; final pb = b.lastProgress ?? 0;
      if (pb.compareTo(pa) != 0) return pb.compareTo(pa);
      return a.priority.compareTo(b.priority);
    });
    if (!mounted) return;
    setState(() { _activeGoals = active; _loading = false; });
  }

  void refresh() => _load();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
            : _activeGoals.isEmpty
                ? const Text('Aucun objectif actif.', style: TextStyle(fontSize: 13))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.flag_circle, color: Colors.orangeAccent),
                          SizedBox(width: 8),
                          Text('Objectifs actifs', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._activeGoals.map((g) => _GoalRow(goal: g)).toList(),
                      if (_activeGoals.length > 10)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text('${_activeGoals.length} objectifs actifs', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                        ),
                    ],
                  ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final Goal goal; const _GoalRow({required this.goal});
  @override
  Widget build(BuildContext context) {
    final progress = (goal.lastProgress ?? 0).clamp(0,1).toDouble();
    final pct = (progress * 100).toStringAsFixed(0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.title, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey[850],
                  color: _colorFor(progress),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('$pct%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _colorFor(double p) {
    if (p >= 0.9) return Colors.green;
    if (p >= 0.6) return Colors.amber;
    return Colors.blueGrey;
  }
}
