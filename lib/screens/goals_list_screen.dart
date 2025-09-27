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
  GoalPeriod _period = GoalPeriod.none;

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
      period: _period,
    );
    await _service.addGoal(goal);
    await _assignDefaultPriorityIfNeeded(goal);
    await _service.recomputeAllProgress();
    final g = await _service.listAll();
    setState(() {
      _goals = g;
      _titleCtrl.clear();
      _targetCtrl.clear();
    });
  }

  Future<void> _assignDefaultPriorityIfNeeded(Goal goal) async {
    // Si l'objectif vient d'être créé avec priorité par défaut élevée, on lui attribue la dernière position.
    if (goal.priority >= 9999) {
      final maxPriority = _goals.isEmpty ? -1 : _goals.map((g) => g.priority).fold<int>(-1, (p, c) => c > p ? c : p);
      final updated = goal.copyWith(priority: maxPriority + 1);
      await _service.updateGoal(updated);
    }
  }

  Future<void> _persistOrder() async {
    for (int i = 0; i < _goals.length; i++) {
      final g = _goals[i];
      if (g.priority != i) {
        final updated = g.copyWith(priority: i);
        await _service.updateGoal(updated);
      }
    }
  }

  Future<void> _deleteGoal(Goal g) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'objectif?'),
        content: Text('"${g.title}" sera définitivement supprimé.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.delete),
            label: const Text('Supprimer'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.deleteGoal(g.id);
    // Retirer localement et réindexer priorités restantes
    setState(() => _goals.removeWhere((e) => e.id == g.id));
    await _persistOrder();
    // Recharger depuis service pour cohérence
    final refreshed = await _service.listAll();
    setState(() => _goals = refreshed);
  }

  Color _progressColor(double p) {
    if (p >= 0.9) return Colors.green;
    if (p >= 0.6) return Colors.amber;
    return Colors.blueGrey;
  }

  String _metricLabel(Goal g) {
    switch (g.metric) {
      case GoalMetric.averagePoints: return 'Score moyen par série';
      case GoalMetric.averageSessionPoints: return 'Score moyen par session';
      case GoalMetric.sessionCount: return 'Nombre de sessions';
      case GoalMetric.totalPoints: return '(Ancien) Points cumulés';
      case GoalMetric.groupSize: return 'Moy/groupement';
      case GoalMetric.bestSeriesPoints: return 'Score d\'une série';
      case GoalMetric.bestSessionPoints: return 'Score d\'une session';
      case GoalMetric.bestGroupSize: return 'Taille du groupement';
    }
  }

  String _shortMetricName(GoalMetric m) {
    switch (m) {
      case GoalMetric.averagePoints: return 'Moy/série';
      case GoalMetric.averageSessionPoints: return 'Moy/session';
      case GoalMetric.sessionCount: return 'Sessions';
      case GoalMetric.totalPoints: return 'Cumul';
      case GoalMetric.groupSize: return 'Moy grp';
      case GoalMetric.bestSeriesPoints: return 'Score série';
      case GoalMetric.bestSessionPoints: return 'Score sess';
      case GoalMetric.bestGroupSize: return 'Grp min';
    }
  }

  String _shortComparatorName(GoalComparator c) {
    switch (c) {
      case GoalComparator.greaterOrEqual: return '≥';
      case GoalComparator.lessOrEqual: return '≤';
    }
  }

  String _metricExplanation(GoalMetric m) {
    switch (m) {
      case GoalMetric.averagePoints:
        return 'Score moyen par série (moyenne des points des séries dans la période).';
      case GoalMetric.averageSessionPoints:
        return 'Score moyen par session (moyenne des moyennes de chaque session).';
      case GoalMetric.sessionCount:
        return 'Nombre de sessions réalisées sur la période.';
      case GoalMetric.totalPoints:
        return '(Ancien) cumul de tous les points; utiliser de préférence une moyenne.';
      case GoalMetric.groupSize:
        return 'Groupement moyen (objectif: descendre sous une valeur).';
      case GoalMetric.bestSeriesPoints:
        return 'Atteindre au moins une fois un score de série (ex: 49 ou 50).';
      case GoalMetric.bestSessionPoints:
        return 'Atteindre au moins une fois un score total de session donné.';
      case GoalMetric.bestGroupSize:
        return 'Réaliser au moins une série avec un groupement ≤ cible.';
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
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<GoalMetric>(
                            value: _metric,
                            isExpanded: true,
                            items: GoalMetric.values
                                .where((m) => m != GoalMetric.totalPoints) // masquer métrique obsolète création
                                .map((m) => DropdownMenuItem(value: m, child: Text(_shortMetricName(m)))).toList(),
                            onChanged: (v) => setState(() {
                              if (v == null) return;
                              _metric = v;
                              // Forcer comparateur cohérent pour hauts faits
                              if (v == GoalMetric.bestSeriesPoints || v == GoalMetric.bestSessionPoints) {
                                _comparator = GoalComparator.greaterOrEqual; // atteindre au moins cette valeur
                              } else if (v == GoalMetric.bestGroupSize) {
                                _comparator = GoalComparator.lessOrEqual; // groupement <= cible
                              }
                            }),
                            decoration: const InputDecoration(labelText: 'Métrique'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<GoalComparator>(
                            value: _comparator,
                            isExpanded: true,
                            items: GoalComparator.values.map((m) => DropdownMenuItem(value: m, child: Text(_shortComparatorName(m)))).toList(),
                            onChanged: (v) => setState(() {
                              if (v == null) return;
                              // Empêcher sélection d'un comparateur incohérent avec un haut fait
                              if (_metric == GoalMetric.bestSeriesPoints || _metric == GoalMetric.bestSessionPoints) {
                                _comparator = GoalComparator.greaterOrEqual;
                              } else if (_metric == GoalMetric.bestGroupSize) {
                                _comparator = GoalComparator.lessOrEqual;
                              } else {
                                _comparator = v;
                              }
                            }),
                            decoration: const InputDecoration(labelText: 'Cmp'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<GoalPeriod>(
                      value: _period,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Période'),
                      items: [
                        DropdownMenuItem(value: GoalPeriod.none, child: Text('Aucune (objectif absolu)')),
                        DropdownMenuItem(value: GoalPeriod.rollingWeek, child: Text('7 derniers jours')),
                        DropdownMenuItem(value: GoalPeriod.rollingMonth, child: Text('30 derniers jours')),
                      ],
                      onChanged: (v) => setState(() => _period = v ?? _period),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _metricExplanation(_metric),
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    if (_period != GoalPeriod.none) ...[
                      const SizedBox(height: 4),
                      Text(
                        _period == GoalPeriod.rollingWeek
                            ? 'Calcul limité aux 7 derniers jours.'
                            : 'Calcul limité aux 30 derniers jours.',
                        style: const TextStyle(fontSize: 11, color: Colors.white54),
                      )
                    ],
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
            if (_goals.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4),
                child: Row(
                  children: const [
                    Icon(Icons.drag_indicator, size: 18, color: Colors.white70),
                    SizedBox(width: 6),
                    Expanded(child: Text('Priorité: faites glisser pour réordonner (haut = plus prioritaire).', style: TextStyle(fontSize: 12, color: Colors.white70))),
                  ],
                ),
              ),
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorder: (oldIndex, newIndex) async {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _goals.removeAt(oldIndex);
                    _goals.insert(newIndex, item);
                  });
                  await _persistOrder();
                  // recharger pour garantir tri propre
                  final g = await _service.listAll();
                  setState(() => _goals = g);
                },
                children: [
                  for (int i = 0; i < _goals.length; i++) _buildReorderableTile(_goals[i], i)
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildReorderableTile(Goal g, int index) {
    final p = g.lastProgress ?? 0;
    final valueStr = g.lastMeasuredValue?.toStringAsFixed(1) ?? '-';
    String periodLabel = '';
    switch (g.period) {
      case GoalPeriod.none:
        periodLabel = '';
        break;
      case GoalPeriod.rollingWeek:
        periodLabel = ' (7j)';
        break;
      case GoalPeriod.rollingMonth:
        periodLabel = ' (30j)';
        break;
    }
    return Card(
      key: ValueKey(g.id),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: index,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.drag_handle, size: 20),
              Text('#${index+1}', style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
        title: Text(g.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_metricLabel(g)}$periodLabel: $valueStr / cible ${g.targetValue}'),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: p,
              color: _progressColor(p),
              backgroundColor: Colors.grey[800],
              minHeight: 6,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${(p*100).toStringAsFixed(0)}%'),
            const SizedBox(height: 4),
            InkWell(
              onTap: () => _deleteGoal(g),
              child: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}
