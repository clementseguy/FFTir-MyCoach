import 'package:flutter/material.dart';
import '../services/goal_service.dart';

/// Panel affichant les 6 indicateurs macro (Lot B)
class GoalsMacroStatsPanel extends StatefulWidget {
  const GoalsMacroStatsPanel({super.key});
  @override
  GoalsMacroStatsPanelState createState() => GoalsMacroStatsPanelState();
}

class GoalsMacroStatsPanelState extends State<GoalsMacroStatsPanel> {
  final _service = GoalService();
  bool _loading = true;
  MacroAchievementStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.init();
    await _service.recomputeAllProgress();
    final stats = await _service.macroAchievementStats();
    if (!mounted) return;
    setState(() { _stats = stats; _loading = false; });
  }

  void refresh() => _load();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: _loading
            ? const SizedBox(height: 56, child: Center(child: SizedBox(width:22,height:22,child: CircularProgressIndicator(strokeWidth: 2))))
            : _buildCompact(),
      ),
    );
  }

  Widget _buildCompact() {
    final s = _stats!;
    final items = [
      _StatChip(label: 'Réalisés', value: s.totalCompleted),
      _StatChip(label: 'Actifs', value: s.totalActive),
      _StatChip(label: '7j', value: s.completedLast7),
      _StatChip(label: '30j', value: s.completedLast30),
      _StatChip(label: '60j', value: s.completedLast60),
      _StatChip(label: '90j', value: s.completedLast90),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Statistiques Objectifs', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        if (s.totalCompleted == 0 && s.totalActive == 0)
          const Text('Aucun objectif défini.', style: TextStyle(fontSize: 12))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items,
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  const _StatChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.35), width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
