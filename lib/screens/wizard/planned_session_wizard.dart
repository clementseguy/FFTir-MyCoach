import 'package:flutter/material.dart';
import '../../models/shooting_session.dart';
import '../../models/series.dart';
import '../../services/session_service.dart';
import '../../constants/session_constants.dart';

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

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _weaponDraft = _session.weapon;
    _caliberDraft = _session.caliber;
    _categoryDraft = _session.category;
    _syntheseDraft = _session.synthese; // peut contenir "Session créée à partir de ..."
  }

  int get _seriesCount => _session.series.length;
  int get _lastStepIndex => 1 + _seriesCount; // intro=0, séries=1..n, synthèse = n+1

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
    final ok = controller.validate();
    if (!ok) return;
    final updated = controller.build();
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
          title: Text(_step == 0 ? 'Session prévue' : _step == _lastStepIndex ? 'Synthèse' : 'Série ${_step} / $_seriesCount'),
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
    // Exercice associé ?
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
                    if (!hasExercise) const Text('Pas d\'exercice associé', style: TextStyle(color: Colors.white60)) else Text('Associé à ${_session.exercises.length} exercice(s)'),
                    const SizedBox(height: 12),
                    // Placeholder objectifs / description: dépendrait du chargement Exercise (non chargé ici pour MVP)
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
    for (final s in _session.series) {
      _seriesControllers.add(_SeriesStepController.fromSeries(s));
    }
  }

  Widget _buildSeries(int index) {
    _ensureSeriesControllers();
    final c = _seriesControllers[index];
    final consigne = c.comment?.trim().isEmpty ?? true ? 'Pas de consigne' : c.comment!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(consigne, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(children:[
            Expanded(child: TextFormField(
              initialValue: c.points.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Points'),
              onChanged: (v){ c.points = int.tryParse(v) ?? 0; },
            )),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(
              initialValue: c.groupSize.toString(),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Groupement'),
              onChanged: (v){ c.groupSize = double.tryParse(v) ?? 0; },
            )),
          ]),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: c.comment,
            decoration: const InputDecoration(labelText: 'Commentaire série'),
            onChanged: (v)=> c.comment = v,
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              onPressed: ()=> _onValidateSeries(index+1),
              child: Text(index == _seriesCount-1 ? 'Suite' : 'Suivant'),
            ),
          )
        ],
      ),
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
                initialValue: _syntheseDraft,
                maxLines: null,
                expands: true,
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

  _SeriesStepController({
    required this.points,
    required this.groupSize,
    required this.comment,
    required this.shotCount,
    required this.distance,
    required this.handMethod,
  });

  factory _SeriesStepController.fromSeries(Series s) => _SeriesStepController(
    points: s.points,
    groupSize: s.groupSize,
    comment: s.comment,
    shotCount: s.shotCount,
    distance: s.distance,
    handMethod: s.handMethod,
  );

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
