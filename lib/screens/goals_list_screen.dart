import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';
import '../widgets/goals_macro_stats_panel.dart';
import '../widgets/multi_goal_card.dart';
import '../widgets/exercises_total_card.dart';
import 'goal_edit_screen.dart';
import 'package:flutter/services.dart' show rootBundle;

class GoalsListScreen extends StatefulWidget {
  const GoalsListScreen({super.key});
  @override
  State<GoalsListScreen> createState() => _GoalsListScreenState();
}

class _GoalsListScreenState extends State<GoalsListScreen> {
  final _service = GoalService();
  bool _loading = true;
  List<Goal> _goals = [];

  final _scrollCtrl = ScrollController();
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

  Future<void> _openCreate() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const GoalEditScreen()),
    );
    if (changed == true) {
      await _service.recomputeAllProgress();
      final g = await _service.listAll();
      setState(() => _goals = g);
    }
  }

  Future<void> _openEdit(Goal goal) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => GoalEditScreen(existing: goal)),
    );
    if (changed == true) {
      await _service.recomputeAllProgress();
      final g = await _service.listAll();
      setState(() => _goals = g);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Objectifs'),
        actions: [
          IconButton(
            tooltip: 'Aide tendance',
            icon: const Icon(Icons.help_outline),
            onPressed: _openTrendHelp,
          ),
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
            // Carte stats exercices (EX4)
            const ExercisesTotalCard(),
            const SizedBox(height: 16),
            MultiGoalCard(key: _multiKey),
            const SizedBox(height: 12),
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_goal_create',
        onPressed: _openCreate,
        child: const Icon(Icons.add),
        tooltip: 'Créer un objectif',
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
    return AnimatedContainer(
      key: ValueKey(g.id),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: achieved
            ? Colors.green.withValues(alpha: 0.08)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
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
                  onTap: () => _openEdit(g),
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
    if (g.previousMeasuredValue == null || g.period == GoalPeriod.none) {
      return const Text('-', style: TextStyle(fontSize: 12, color: Colors.white54));
    }
    // Classification stable si delta très faible
    if (delta.abs() <= GoalService.kGoalDeltaNeutralEpsilon) {
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

  Future<void> _openTrendHelp() async {
    // Charge doc markdown complète pour "Voir plus" si besoin
    String? fullDoc;
    try {
      fullDoc = await rootBundle.loadString('docs/objectifs_tendance.md');
    } catch (_) {}
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
            maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (_, scroll) => SingleChildScrollView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.trending_up, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('Tendance des objectifs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'La tendance compare la dernière période à la précédente. ' 
                  'En hausse: amélioration nette. Stable: variation minime. En baisse: régression.',
                  style: TextStyle(fontSize: 13, height: 1.3),
                ),
                const SizedBox(height: 20),
                const Text('Règles', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('• En hausse: progrès clair sur la métrique.\n'
                    '• Stable: variation très faible (écart négligeable).\n'
                    '• En baisse: recul sur la métrique.', style: TextStyle(fontSize: 12, height: 1.35)),
                const SizedBox(height: 20),
                if (fullDoc != null) ...[
                  const Divider(),
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (dctx) => AlertDialog(
                          backgroundColor: Colors.grey[900],
                          title: const Text('Détails complets'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: SingleChildScrollView(
                              child: Text(fullDoc!, style: const TextStyle(fontSize: 12, height: 1.35)),
                            ),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(dctx).pop(), child: const Text('Fermer')),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.description),
                    label: const Text('Voir la documentation complète'),
                  ),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Fermer'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
