import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';

/// Écran de création / édition d'un objectif (Lot C)
/// - Formulaire séparé
/// - Sauvegarde via icône dans l'AppBar (disquette)
/// - Champ "Période" déplacé en bas
/// - Dirty guard lors de la fermeture si modifications non enregistrées
class GoalEditScreen extends StatefulWidget {
  final Goal? existing;
  const GoalEditScreen({super.key, this.existing});

  @override
  GoalEditScreenState createState() => GoalEditScreenState();
}

class GoalEditScreenState extends State<GoalEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  GoalMetric _metric = GoalMetric.averagePoints;
  GoalComparator _comparator = GoalComparator.greaterOrEqual;
  GoalPeriod _period = GoalPeriod.none;
  bool _dirty = false;
  bool _saving = false;
  final _service = GoalService();

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    if (g != null) {
      _titleCtrl.text = g.title;
      _targetCtrl.text = g.targetValue.toString();
      _metric = g.metric;
      _comparator = g.comparator;
      _period = g.period;
    }
    _titleCtrl.addListener(_markDirty);
    _targetCtrl.addListener(_markDirty);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusFirst());
  }

  void _focusFirst() {
    if (mounted) {
      FocusScope.of(context).requestFocus(FocusNode());
    }
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler les modifications ?'),
        content: const Text('Tout changement non enregistré sera perdu.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Continuer')), // rester
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.close),
            label: const Text('Quitter'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
        ],
      ),
    );
    return res == true;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await _service.init();
    if (widget.existing == null) {
      final goal = Goal(
        title: _titleCtrl.text.trim(),
        metric: _metric,
        comparator: _comparator,
        targetValue: double.parse(_targetCtrl.text.replaceAll(',', '.')),
        period: _period,
      );
      await _service.addGoal(goal);
      // priorité: ajouter à la fin (comme logique existante)
      final all = await _service.listAll();
      final maxPriority = all.isEmpty ? -1 : all.map((g) => g.priority).reduce((a,b)=> a>b?a:b);
      if (goal.priority >= 9999) {
        await _service.updateGoal(goal.copyWith(priority: maxPriority + 1));
      }
    } else {
      final updated = widget.existing!.copyWith(
        title: _titleCtrl.text.trim(),
        metric: _metric,
        comparator: _comparator,
        targetValue: double.parse(_targetCtrl.text.replaceAll(',', '.')),
        period: _period,
      );
      await _service.updateGoal(updated);
    }
    await _service.recomputeAllProgress();
    if (!mounted) return;
    Navigator.of(context).pop(true); // true => changement
  }

  void _onMetricChanged(GoalMetric? v) {
    if (v == null) return;
    setState(() {
      _metric = v;
      if (v == GoalMetric.bestSeriesPoints || v == GoalMetric.bestSessionPoints) {
        _comparator = GoalComparator.greaterOrEqual;
      } else if (v == GoalMetric.bestGroupSize) {
        _comparator = GoalComparator.lessOrEqual;
      }
      _dirty = true;
    });
  }

  void _onComparatorChanged(GoalComparator? v) {
    if (v == null) return;
    setState(() {
      if (_metric == GoalMetric.bestSeriesPoints || _metric == GoalMetric.bestSessionPoints) {
        _comparator = GoalComparator.greaterOrEqual;
      } else if (_metric == GoalMetric.bestGroupSize) {
        _comparator = GoalComparator.lessOrEqual;
      } else {
        _comparator = v;
      }
      _dirty = true;
    });
  }

  void _onPeriodChanged(GoalPeriod? v) {
    if (v == null) return;
    setState(() { _period = v; _dirty = true; });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => await _confirmDiscard(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.existing == null ? 'Nouvel objectif' : 'Modifier objectif'),
          actions: [
            IconButton(
              tooltip: 'Enregistrer',
              icon: const Icon(Icons.save), // icône disquette cohérente avec Sessions
              onPressed: _saving ? null : _save,
            ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _confirmDiscard()) {
                if (mounted) Navigator.of(context).pop(false);
              }
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Titre'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Titre requis';
                    if (v.trim().length < 3) return 'Minimum 3 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<GoalMetric>(
                  value: _metric,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Métrique'),
                  items: GoalMetric.values.where((m) => m != GoalMetric.totalPoints)
                      .map((m) => DropdownMenuItem(value: m, child: Text(_metricLabel(m)))).toList(),
                  onChanged: _onMetricChanged,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<GoalComparator>(
                  value: _comparator,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Comparateur'),
                  items: GoalComparator.values
                      .map((c) => DropdownMenuItem(value: c, child: Text(_shortComparatorName(c)))).toList(),
                  onChanged: _onComparatorChanged,
                ),
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
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<GoalPeriod>(
                  value: _period,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Période'),
                  items: const [
                    DropdownMenuItem(value: GoalPeriod.none, child: Text('Aucune (objectif absolu)')),
                    DropdownMenuItem(value: GoalPeriod.rollingWeek, child: Text('7 derniers jours')),
                    DropdownMenuItem(value: GoalPeriod.rollingMonth, child: Text('30 derniers jours')),
                  ],
                  onChanged: _onPeriodChanged,
                ),
                const SizedBox(height: 12),
                _period != GoalPeriod.none
                    ? Text(
                        _period == GoalPeriod.rollingWeek
                            ? 'Calcul limité aux 7 derniers jours.'
                            : 'Calcul limité aux 30 derniers jours.',
                        style: const TextStyle(fontSize: 11, color: Colors.white54),
                      )
                    : const SizedBox.shrink(),
                const SizedBox(height: 16),
                _buildMetricExplanation(),
                const SizedBox(height: 32),
                if (_saving) const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _metricLabel(GoalMetric m) {
    switch (m) {
      case GoalMetric.averagePoints: return 'Score moyen par série';
      case GoalMetric.averageSessionPoints: return 'Score moyen par session';
      case GoalMetric.sessionCount: return 'Nombre de sessions';
      case GoalMetric.totalPoints: return 'Points cumulés';
      case GoalMetric.groupSize: return 'Groupement moyen';
      case GoalMetric.bestSeriesPoints: return 'Score série';
      case GoalMetric.bestSessionPoints: return 'Score session';
      case GoalMetric.bestGroupSize: return 'Taille groupement';
    }
  }

  String _shortComparatorName(GoalComparator c) {
    switch (c) {
      case GoalComparator.greaterOrEqual: return '≥';
      case GoalComparator.lessOrEqual: return '≤';
    }
  }

  Widget _buildMetricExplanation() {
    String text;
    switch (_metric) {
      case GoalMetric.averagePoints:
        text = 'Score moyen par série (moyenne des points des séries dans la période).';
        break;
      case GoalMetric.averageSessionPoints:
        text = 'Score moyen par session (moyenne des moyennes de chaque session).';
        break;
      case GoalMetric.sessionCount:
        text = 'Nombre de sessions réalisées sur la période.';
        break;
      case GoalMetric.totalPoints:
        text = '(Ancien) cumul de tous les points; préférer une moyenne.';
        break;
      case GoalMetric.groupSize:
        text = 'Groupement moyen (plus petit est mieux si comparateur ≤).';
        break;
      case GoalMetric.bestSeriesPoints:
        text = 'Atteindre au moins une fois un score de série.';
        break;
      case GoalMetric.bestSessionPoints:
        text = 'Atteindre au moins une fois un score total de session.';
        break;
      case GoalMetric.bestGroupSize:
        text = 'Réaliser au moins une série avec un groupement ≤ cible.';
        break;
    }
    return Text(text, style: const TextStyle(fontSize: 12, color: Colors.white70));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }
}
