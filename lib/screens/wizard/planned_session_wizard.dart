import 'package:flutter/material.dart';
import '../../models/shooting_session.dart';
import '../../models/series.dart';
import '../../services/session_service.dart';
import '../../constants/session_constants.dart';
import '../../services/exercise_service.dart';
import '../../models/exercise.dart';
import '../../services/goal_service.dart';
import '../../models/goal.dart';

/// Wizard de conversion Session prévue -> réalisée
class PlannedSessionWizard extends StatefulWidget {
  final ShootingSession session; // session prévue initiale
  const PlannedSessionWizard({super.key, required this.session});

  @override
  State<PlannedSessionWizard> createState() => _PlannedSessionWizardState();
}

class _PlannedSessionWizardState extends State<PlannedSessionWizard> {
  late ShootingSession _session; // copie mutable
  int _step = 0; // 0 = intro, 1..series = séries, last = synthèse
  final _formIntro = GlobalKey<FormState>();
  final _formSynthese = GlobalKey<FormState>();
  String? _weaponDraft;
  String? _caliberDraft;
  String? _categoryDraft;
  String? _syntheseDraft;
  bool _saving = false;
  final SessionService _service = SessionService();
  final ExerciseService _exerciseService = ExerciseService();
  final GoalService _goalService = GoalService();
  Exercise? _linkedExercise; // premier exercice associé si présent
  List<Goal> _goals = [];
  bool _loadingExercise = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _weaponDraft = _session.weapon;
    _caliberDraft = _session.caliber;
    _categoryDraft = _session.category;
    _syntheseDraft = _session.synthese; // peut contenir "Session créée à partir de ..."
    _loadExerciseAndGoals();
  }

  int get _seriesCount => _session.series.length;
  int get _lastStepIndex => 1 + _seriesCount; // intro=0, séries=1..n, synthèse = n+1
  double get _progressRatio => (_step) / (_lastStepIndex.toDouble());

  Future<void> _loadExerciseAndGoals() async {
    if (_session.exercises.isEmpty) return;
    setState(()=> _loadingExercise = true);
    try {
      final exId = _session.exercises.first;
      final exercises = await _exerciseService.listAll();
      final ex = exercises.where((e)=> e.id == exId).toList();
      if (ex.isNotEmpty) {
        final exercise = ex.first;
        List<Goal> goals = [];
        if (exercise.goalIds.isNotEmpty) {
          final goalAll = await _goalService.listAll();
            goals = goalAll.where((g)=> exercise.goalIds.contains(g.id)).toList();
        }
        if (mounted) {
          setState(() {
            _linkedExercise = exercise;
            _goals = goals;
          });
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(()=> _loadingExercise = false);
    }
  }

  Future<void> _onValidateIntro() async {
    final ok = _formIntro.currentState?.validate() ?? false;
    if (!ok) return;
    _formIntro.currentState?.save();
    setState(() => _step = _seriesCount == 0 ? _lastStepIndex : 1);
  }

  Future<void> _onValidateSeries(int index) async {
    // index wizard -> série index réel = index-1
    final seriesIdx = index - 1;
    final controller = _seriesControllers[seriesIdx];
    // Validation triviale (toujours true pour MVP)
    final updated = controller.build();
    // Toujours persister même si l'utilisateur n'a rien modifié (0 / valeurs par défaut)
    await _service.updateSingleSeries(_session, seriesIdx, updated);
    setState(() {
      if (_step < _lastStepIndex) {
        _step++;
      }
    });
  }

  Future<void> _onFinish() async {
    final ok = _formSynthese.currentState?.validate() ?? false;
    if (!ok) return;
    _formSynthese.currentState?.save();
    setState(()=> _saving = true);
    try {
      await _service.convertPlannedToRealized(
        session: _session,
        weapon: _weaponDraft,
        caliber: _caliberDraft,
        category: _categoryDraft,
        synthese: _syntheseDraft,
      );
      if (mounted) Navigator.of(context).pop(true); // true => conversion effectuée
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur conversion')));
      }
    } finally {
      if (mounted) setState(()=> _saving = false);
    }
  }

  Future<bool> _confirmCancel() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Annuler la session ?'),
        content: const Text('La session restera prévue.'),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(c, false), child: const Text('Non')),
          TextButton(onPressed: ()=> Navigator.pop(c, true), child: const Text('Oui')),
        ],
      ),
    );
    return res == true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => await _confirmCancel(),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_step == 0 ? 'Session prévue' : _step == _lastStepIndex ? 'Synthèse' : 'Série ${_step} / $_seriesCount'),
              const SizedBox(height:4),
              LinearProgressIndicator(
                value: _progressRatio.clamp(0,1),
                minHeight: 4,
                backgroundColor: Colors.white24,
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _confirmCancel()) {
                if (mounted) Navigator.pop(context, false);
              }
            },
          ),
        ),
        body: _buildStep(),
      ),
    );
  }

  Widget _buildStep() {
    if (_step == 0) return _buildIntro();
    if (_step == _lastStepIndex) return _buildSynthese();
    return _buildSeries(_step - 1);
  }

  Widget _buildIntro() {
    final hasExercise = _session.exercises.isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formIntro,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Démarrage', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exercice', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (!hasExercise) const Text('Pas d\'exercice associé', style: TextStyle(color: Colors.white60))
                    else if (_loadingExercise) const Padding(
                      padding: EdgeInsets.symmetric(vertical:8.0),
                      child: SizedBox(width:24, height:24, child: CircularProgressIndicator(strokeWidth:2)),
                    )
                    else if (_linkedExercise != null) ...[
                      Text(_linkedExercise!.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (_linkedExercise!.description != null && _linkedExercise!.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(_linkedExercise!.description!, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                      if (_goals.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _goals.map((g)=> Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(g.title, style: const TextStyle(fontSize: 11)),
                          )).toList(),
                        ),
                      ],
                    ]
                    else const Text('Exercice introuvable', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Informations session', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _weaponDraft,
              decoration: const InputDecoration(labelText: 'Arme'),
              onSaved: (v)=> _weaponDraft = v ?? '',
            ),
            TextFormField(
              initialValue: _caliberDraft,
              decoration: const InputDecoration(labelText: 'Calibre'),
              onSaved: (v)=> _caliberDraft = v ?? '',
            ),
            TextFormField(
              initialValue: _categoryDraft,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              onSaved: (v)=> _categoryDraft = v ?? SessionConstants.categoryEntrainement,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _onValidateIntro,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Commencer'),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Contrôleurs séries (simple implémentation basique)
  final List<_SeriesStepController> _seriesControllers = [];
  void _ensureSeriesControllers() {
    if (_seriesControllers.length == _session.series.length) return;
    _seriesControllers.clear();
    for (int i = 0; i < _session.series.length; i++) {
      final s = _session.series[i];
      final consigneText = s.comment;
      double defaultDistance;
      if (i == 0) {
        defaultDistance = s.distance > 0 ? s.distance : 25;
      } else {
        final prev = _session.series[i-1];
        defaultDistance = prev.distance > 0 ? prev.distance : 25;
      }
      final defaultShot = (s.shotCount > 0) ? s.shotCount : 5;
      _seriesControllers.add(_SeriesStepController(
        points: 0,
        groupSize: 0,
        comment: '',
        shotCount: defaultShot,
        distance: defaultDistance,
        handMethod: s.handMethod,
        consigne: consigneText,
      ));
    }
  }

  Widget _buildSeries(int index) {
    _ensureSeriesControllers();
    final c = _seriesControllers[index];
    final consigne = c.consigne.trim().isEmpty ? 'Pas de consigne' : c.consigne;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(consigne, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Row(children:[
                  Expanded(child: TextFormField(
                    initialValue: '',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Points'),
                    onChanged: (v){ c.points = int.tryParse(v) ?? 0; },
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(
                    initialValue: '',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Groupement'),
                    onChanged: (v){ c.groupSize = double.tryParse(v) ?? 0; },
                  )),
                ]),
                const SizedBox(height: 12),
                Row(children:[
                  Expanded(child: TextFormField(
                    initialValue: c.shotCount.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Coups'),
                    onChanged: (v){ c.shotCount = int.tryParse(v) ?? c.shotCount; },
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(
                    initialValue: c.distance.toString(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Distance (m)'),
                    onChanged: (v){ c.distance = double.tryParse(v) ?? c.distance; },
                  )),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: '',
                  decoration: const InputDecoration(labelText: 'Commentaire série'),
                  onChanged: (v)=> c.comment = v,
                  maxLines: null,
                ),
                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: ()=> _onValidateSeries(index+1),
                    child: Text(index == _seriesCount-1 ? 'Suite' : 'Suivant'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSynthese() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formSynthese,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Synthèse', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Expanded(
              child: TextFormField(
                initialValue: _normalizedSyntheseInitial(),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: 'Synthèse de la session',
                  alignLabelWithHint: true,
                ),
                onSaved: (v)=> _syntheseDraft = v ?? '',
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _onFinish,
                icon: const Icon(Icons.check),
                label: _saving ? const SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth:2)) : const Text('Terminer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeriesStepController {
  int points;
  double groupSize;
  String? comment;
  int shotCount;
  double distance;
  HandMethod handMethod;
  String consigne;

  _SeriesStepController({
    required this.points,
    required this.groupSize,
    required this.comment,
    required this.shotCount,
    required this.distance,
    required this.handMethod,
    required this.consigne,
  });

  bool validate() { return true; }

  Series build() => Series(
    points: points,
    groupSize: groupSize,
    comment: comment ?? '',
    shotCount: shotCount,
    distance: distance,
    handMethod: handMethod,
  );
}

// Helper to normaliser synthèse initiale (ajout newline après phrase origine)
extension _SyntheseInit on _PlannedSessionWizardState {
  String _normalizedSyntheseInitial() {
    final base = _syntheseDraft ?? '';
    if (base.isEmpty) return base;
    final pattern = RegExp(r'^Session créée à partir de .+');
    if (pattern.hasMatch(base) && !base.endsWith('\n')) {
      return base + '\n';
    }
    return base;
  }
}
