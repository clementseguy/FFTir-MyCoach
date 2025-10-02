import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';
import '../widgets/goals_macro_stats_panel.dart';
import '../widgets/multi_goal_card.dart';

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
  final _formKey = GlobalKey<FormState>();
  GoalMetric _metric = GoalMetric.averagePoints;
  GoalComparator _comparator = GoalComparator.greaterOrEqual;
  GoalPeriod _period = GoalPeriod.none;
  Goal? _editingGoal;
  final _scrollCtrl = ScrollController();
  String? _recentAddedGoalId;
  final GlobalKey<GoalsMacroStatsPanelState> _statsKey = GlobalKey<GoalsMacroStatsPanelState>();
  final GlobalKey<MultiGoalCardState> _multiKey = GlobalKey<MultiGoalCardState>();

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
    if (_editingGoal == null) {
      final goal = Goal(
        title: title,
        metric: _metric,
        comparator: _comparator,
        targetValue: target,
        period: _period,
      );
      await _service.addGoal(goal);
      await _assignDefaultPriorityIfNeeded(goal);
      _recentAddedGoalId = goal.id;
    } else {
      // Mise à jour
      final updated = _editingGoal!.copyWith(
        title: title,
        metric: _metric,
        comparator: _comparator,
        targetValue: target,
        period: _period,
      );
      await _service.updateGoal(updated);
    }
    await _service.recomputeAllProgress();
    final g = await _service.listAll();
    setState(() {
      _goals = g;
      _titleCtrl.clear();
      _targetCtrl.clear();
      _editingGoal = null;
    });
    if (_recentAddedGoalId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final idx = _goals.indexWhere((goal) => goal.id == _recentAddedGoalId);
        if (idx >= 0) {
          final offset = 380 + (idx * 130);
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.animateTo(
              offset.toDouble(),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOut,
            );
          }
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _recentAddedGoalId = null);
          });
        }
      });
    }
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
  case GoalMetric.groupSize: return 'Groupement moyen';
      case GoalMetric.bestSeriesPoints: return 'Score série';
      case GoalMetric.bestSessionPoints: return 'Score session';
      case GoalMetric.bestGroupSize: return 'Taille du groupement';
    }
  }

  String _shortMetricName(GoalMetric m) {
    switch (m) {
      case GoalMetric.averagePoints: return 'Score moyen par série';
      case GoalMetric.averageSessionPoints: return 'Score moyen par session';
      case GoalMetric.sessionCount: return 'Nombre de sessions';
      case GoalMetric.totalPoints: return 'Points cumulés';
  case GoalMetric.groupSize: return 'Groupement moyen';
      case GoalMetric.bestSeriesPoints: return 'Score série';
      case GoalMetric.bestSessionPoints: return 'Score session';
      case GoalMetric.bestGroupSize: return 'Taille du groupement';
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

  String? _metricExample(GoalMetric m) {
    switch (m) {
      case GoalMetric.averagePoints:
        return 'Ex: moyenne des séries des 7 derniers jours: (45 + 47 + 46 + 44) / 4 = 45.';
      case GoalMetric.averageSessionPoints:
        return 'Ex: Session A moy=45, Session B moy=46 → moyenne session = (45 + 46)/2 = 45.';
      case GoalMetric.sessionCount:
        return 'Ex: 5 sessions effectuées sur les 30 derniers jours.';
      case GoalMetric.totalPoints:
        return 'Ex: Somme de tous les points (obsolète, préférer les moyennes).';
      case GoalMetric.groupSize:
        return 'Ex: Séries groupements: 32mm, 28mm, 30mm → moyenne = 30mm.';
      case GoalMetric.bestSeriesPoints:
        return 'Ex: Série maximale atteinte: 50.';
      case GoalMetric.bestSessionPoints:
        return 'Ex: Meilleure session totale: 548.';
      case GoalMetric.bestGroupSize:
        return 'Ex: Meilleur (plus petit) groupement atteint: 22mm.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Objectifs'),
        actions: [
          IconButton(
            tooltip: 'Recharger stats & objectifs',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _statsKey.currentState?.refresh();
              _multiKey.currentState?.refresh();
            },
          ),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: () async {
          await _service.recomputeAllProgress();
          final g = await _service.listAll();
          setState(() => _goals = g);
        },
        child: ListView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.all(16),
          children: [
            GoalsMacroStatsPanel(key: _statsKey),
            const SizedBox(height: 16),
            MultiGoalCard(key: _multiKey),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nouvel objectif', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(labelText: 'Titre'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Titre requis';
                          if (v.trim().length < 3) return 'Minimum 3 caractères';
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<GoalMetric>(
                              initialValue: _metric,
                              isExpanded: true,
                              items: GoalMetric.values.where((m) => m != GoalMetric.totalPoints)
                                  .map((m) => DropdownMenuItem(value: m, child: Text(_shortMetricName(m)))).toList(),
                              onChanged: (v) => setState(() {
                                if (v == null) return;
                                _metric = v;
                                if (v == GoalMetric.bestSeriesPoints || v == GoalMetric.bestSessionPoints) {
                                  _comparator = GoalComparator.greaterOrEqual;
                                } else if (v == GoalMetric.bestGroupSize) {
                                  _comparator = GoalComparator.lessOrEqual;
                                }
                              }),
                              decoration: InputDecoration(
                                labelText: 'Métrique',
                                suffixIcon: IconButton(
                                  tooltip: 'Explication',
                                  icon: const Icon(Icons.info_outline),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      showDragHandle: true,
                                      backgroundColor: Colors.grey[900],
                                      builder: (_) => Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(_shortMetricName(_metric), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 12),
                                              Text(_metricExplanation(_metric), style: const TextStyle(fontSize: 13, height: 1.3)),
                                              const SizedBox(height: 16),
                                              if (_metricExample(_metric) != null) ...[
                                                const Text('Exemples', style: TextStyle(fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 8),
                                                Text(_metricExample(_metric)!, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                              ],
                                              const SizedBox(height: 12),
                                              Text('Comparateur utilisé: ${_shortComparatorName(_comparator)}', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<GoalComparator>(
                              initialValue: _comparator,
                              isExpanded: true,
                              items: GoalComparator.values
                                  .map((m) => DropdownMenuItem(value: m, child: Text(_shortComparatorName(m)))).toList(),
                              onChanged: (v) => setState(() {
                                if (v == null) return;
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
                      const SizedBox(height: 20),
                      DropdownButtonFormField<GoalPeriod>(
                        initialValue: _period,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Période'),
                        items: const [
                          DropdownMenuItem(value: GoalPeriod.none, child: Text('Aucune (objectif absolu)')),
                          DropdownMenuItem(value: GoalPeriod.rollingWeek, child: Text('7 derniers jours')),
                          DropdownMenuItem(value: GoalPeriod.rollingMonth, child: Text('30 derniers jours')),
                        ],
                        onChanged: (v) => setState(() => _period = v ?? _period),
                      ),
                      const SizedBox(height: 16),
                      Text(_metricExplanation(_metric), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      if (_period != GoalPeriod.none) ...[
                        const SizedBox(height: 8),
                        Text(
                          _period == GoalPeriod.rollingWeek
                              ? 'Calcul limité aux 7 derniers jours.'
                              : 'Calcul limité aux 30 derniers jours.',
                          style: const TextStyle(fontSize: 11, color: Colors.white54),
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _targetCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Valeur cible'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Valeur requise';
                          final d = double.tryParse(v.replaceAll(',', '.'));
                          if (d == null) return 'Nombre invalide';
                          if (d <= 0) return 'Doit être > 0';
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _formKey.currentState?.validate() == true ? _addGoal : null,
                          icon: Icon(_editingGoal == null ? Icons.add : Icons.save),
                          label: Text(_editingGoal == null ? 'Ajouter' : 'Mettre à jour'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_editingGoal != null)
              Padding(
                padding: const EdgeInsets.only(top:8.0,bottom:16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _editingGoal = null;
                        _titleCtrl.clear();
                        _targetCtrl.clear();
                        _metric = GoalMetric.averagePoints;
                        _comparator = GoalComparator.greaterOrEqual;
                        _period = GoalPeriod.none;
                      });
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Annuler modification'),
                  ),
                ),
              ),
            // Fin carte formulaire + éventuel bouton annuler
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
  final valueStr = g.lastMeasuredValue != null
    ? g.lastMeasuredValue!.round().toString()
    : '-';
    final achieved = g.status == GoalStatus.achieved;
    String achievedDateLabel = '';
    if (achieved && g.achievementDate != null) {
      final d = g.achievementDate!;
      achievedDateLabel = 'Atteint le ${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    }
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
    final isNew = g.id == _recentAddedGoalId;
    return AnimatedContainer(
      key: ValueKey(g.id),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: achieved
            ? Colors.green.withValues(alpha: 0.08)
            : (isNew ? Colors.amber.withValues(alpha: 0.18) : Theme.of(context).cardColor),
        borderRadius: BorderRadius.circular(8),
        border: isNew ? Border.all(color: Colors.amberAccent, width: 1.2) : null,
      ),
      child: ListTile(
        leading: achieved
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
                ],
              )
            : ReorderableDragStartListener(
                index: index,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.drag_handle, size: 20),
                    Text('#${index + 1}', style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
        title: Row(
          children: [
            Expanded(child: Text(g.title)),
            if (g.improvementDelta != null && g.period != GoalPeriod.none) _buildTrendChip(g),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_metricLabel(g)}$periodLabel: $valueStr / cible ${g.targetValue.round()}',
              style: achieved
                  ? const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.white70)
                  : null,
            ),
            if (achievedDateLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(achievedDateLabel, style: const TextStyle(fontSize: 11, color: Colors.greenAccent)),
              ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: p,
              color: achieved ? Colors.green : _progressColor(p),
              backgroundColor: achieved ? Colors.green.withValues(alpha: 0.2) : Colors.grey[800],
              minHeight: 6,
            ),
          ],
        ),
        trailing: IntrinsicWidth(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '${(p * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 12, color: achieved ? Colors.green : null),
                  overflow: TextOverflow.fade,
                  softWrap: false,
                ),
              ),
              const SizedBox(width: 4),
              if (!achieved)
                InkWell(
                  onTap: () {
                    setState(() {
                      _editingGoal = g;
                      _titleCtrl.text = g.title;
                      _targetCtrl.text = g.targetValue.round().toString();
                      _metric = g.metric;
                      _comparator = g.comparator;
                      _period = g.period;
                    });
                    Future.delayed(const Duration(milliseconds: 150), () {
                      Scrollable.ensureVisible(_formKey.currentContext!, duration: const Duration(milliseconds: 300));
                    });
                  },
                  child: const Icon(Icons.edit, size: 20, color: Colors.amber),
                ),
              if (!achieved) const SizedBox(width: 4),
              InkWell(
                onTap: () => _deleteGoal(g),
                child: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendChip(Goal g) {
    final delta = g.improvementDelta ?? 0;
    if (delta == 0) {
      return const Icon(Icons.horizontal_rule, size: 16, color: Colors.grey);
    }
    final positive = delta > 0;
    // Pour comparateur lessOrEqual un delta positif signifie diminution (amélioration) => flèche verte vers le bas.
    bool lessIsBetter = g.comparator == GoalComparator.lessOrEqual;
    IconData icon;
    Color color;
    if (lessIsBetter) {
      if (positive) { // previous - value > 0 => value plus basse
        icon = Icons.arrow_downward; color = Colors.green;}
      else { icon = Icons.arrow_upward; color = Colors.redAccent; }
    } else {
      if (positive) { icon = Icons.arrow_upward; color = Colors.green; }
      else { icon = Icons.arrow_downward; color = Colors.redAccent; }
    }
    final magnitude = delta.abs();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(magnitude.toStringAsFixed(0), style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
