import 'package:flutter/material.dart';
import '../services/goal_service.dart';
import '../models/goal.dart';
import '../screens/goals_list_screen.dart';

/// Carte récap Objectifs (Lot A): Top3 actifs + compteurs réalisés / en cours.
class GoalsAtGlanceCard extends StatefulWidget {
  const GoalsAtGlanceCard({super.key});
  @override
  State<GoalsAtGlanceCard> createState() => _GoalsAtGlanceCardState();
}

class _GoalsAtGlanceCardState extends State<GoalsAtGlanceCard> {
  final _service = GoalService();
  bool _loading = true;
  List<Goal> _top3 = [];
  int _active = 0;
  int _achieved = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.init();
    await _service.recomputeAllProgress();
    final top = await _service.topActiveGoals(3);
    final act = await _service.countActiveGoals();
    final ach = await _service.countAchievedGoals();
    if (!mounted) return;
    setState(() { _top3 = top; _active = act; _achieved = ach; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.amber),
                      const SizedBox(width: 8),
                      const Text('Objectifs', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoalsListScreen()))
                            .then((_) => _load()),
                        icon: const Icon(Icons.list_alt),
                        label: const Text('Tous'),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  _CountersRow(active: _active, achieved: _achieved),
                  const SizedBox(height: 12),
                  if (_top3.isEmpty)
                    const Text('Aucun objectif actif.', style: TextStyle(fontSize: 13))
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Top 3 (progression)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        ..._top3.map((g) => _GoalLine(goal: g)).toList(),
                      ],
                    ),
                ],
              ),
      ),
    );
  }
}

class _CountersRow extends StatelessWidget {
  final int active;
  final int achieved;
  const _CountersRow({required this.active, required this.achieved});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CountChip(label: 'En cours', value: active, color: Colors.blueGrey),
        const SizedBox(width: 8),
        _CountChip(label: 'Réalisés', value: achieved, color: Colors.green),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _CountChip({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
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

class _GoalLine extends StatelessWidget {
  final Goal goal;
  const _GoalLine({required this.goal});
  @override
  Widget build(BuildContext context) {
  final double progress = (goal.lastProgress ?? 0).clamp(0, 1).toDouble();
    final percent = (progress * 100).toStringAsFixed(0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(child: Text(goal.title, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey[850],
              color: _colorFor(progress),
            ),
          ),
          const SizedBox(width: 6),
          Text('$percent%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
