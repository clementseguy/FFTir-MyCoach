import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';

class GoalsListScreen extends StatefulWidget {
  const GoalsListScreen({super.key});
  @override
  State<GoalsListScreen> createState() => _GoalsListScreenState();
}

class _GoalsListScreenState extends State<GoalsListScreen> {
  final _service = GoalService();
  bool _loading = true;
  List<Goal> _goals = [];

  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  GoalMetric _metric = GoalMetric.averagePoints;
  GoalComparator _comparator = GoalComparator.greaterOrEqual;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _service.init();
    await _service.recomputeAllProgress();
    final g = await _service.listAll();
    setState(() {
      _goals = g;
      _loading = false;
    });
  }

  Future<void> _addGoal() async {
    final title = _titleCtrl.text.trim();
    final target = double.tryParse(_targetCtrl.text.trim());
    if (title.isEmpty || target == null) return;
    final goal = Goal(
      title: title,
      metric: _metric,
      comparator: _comparator,
      targetValue: target,
    );
    await _service.addGoal(goal);
    await _service.recomputeAllProgress();
    final g = await _service.listAll();
    setState(() {
      _goals = g;
      _titleCtrl.clear();
      _targetCtrl.clear();
    });
  }

  Color _progressColor(double p) {
    if (p >= 0.9) return Colors.green;
    if (p >= 0.6) return Colors.amber;
    return Colors.blueGrey;
  }

  String _metricLabel(Goal g) {
    switch (g.metric) {
      case GoalMetric.averagePoints: return 'Moy. points';
      case GoalMetric.sessionCount: return 'Sessions';
      case GoalMetric.totalPoints: return 'Total points';
      case GoalMetric.groupSize: return 'Groupement';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Objectifs')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: () async {
          await _service.recomputeAllProgress();
          final g = await _service.listAll();
          setState(() => _goals = g);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nouvel objectif', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(labelText: 'Titre'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<GoalMetric>(
                            value: _metric,
                            items: GoalMetric.values.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                            onChanged: (v) => setState(() => _metric = v ?? _metric),
                            decoration: const InputDecoration(labelText: 'Métrique'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<GoalComparator>(
                            value: _comparator,
                            items: GoalComparator.values.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                            onChanged: (v) => setState(() => _comparator = v ?? _comparator),
                            decoration: const InputDecoration(labelText: 'Comparateur'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _targetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Valeur cible'),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _addGoal,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter'),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ..._goals.map((g) {
              final p = g.lastProgress ?? 0;
              final valueStr = g.lastMeasuredValue?.toStringAsFixed(1) ?? '-';
              return Card(
                child: ListTile(
                  title: Text(g.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_metricLabel(g)}: $valueStr / cible ${g.targetValue}'),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: p,
                        color: _progressColor(p),
                        backgroundColor: Colors.grey[800],
                        minHeight: 6,
                      ),
                    ],
                  ),
                  trailing: Text('${(p*100).toStringAsFixed(0)}%'),
                ),
              );
            })
          ],
        ),
      ),
    );
  }
}
