import 'package:flutter/material.dart';
import '../../models/shooting_session.dart';
import '../../models/series.dart';
import '../../services/session_service.dart';
import '../../constants/session_constants.dart';
import '../../services/exercise_service.dart';
import '../../models/exercise.dart';
import '../../services/goal_service.dart';
import '../../models/goal.dart';
import 'package:hive/hive.dart';
import '../../services/preferences_service.dart';
import '../../utils/caliber_autocomplete.dart';
import 'wizard_steps.dart';

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
  late TextEditingController _caliberCtrl;
  final FocusNode _caliberFocus = FocusNode();
  String _lastCalTxt = '';
  bool _showAll = false;
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
  _caliberDraft = pickInitialCaliber(existing: _session.caliber, defaultCaliber: PreferencesService().getDefaultCaliber());
    _caliberCtrl = TextEditingController(text: _caliberDraft ?? '');
    _lastCalTxt = _caliberCtrl.text;
    _caliberFocus.addListener((){
      if (_caliberFocus.hasFocus) {
        setState(()=> _showAll = true);
      } else {
        if (_showAll) setState(()=> _showAll = false);
      }
    });
    _categoryDraft = _session.category;
    _syntheseDraft = _session.synthese; // peut contenir "Session créée à partir de ..."
    _loadExerciseAndGoals();
  }

  @override
  void dispose() {
    _caliberCtrl.dispose();
    _caliberFocus.dispose();
    super.dispose();
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
    // Validation obligatoire: points, groupSize, shotCount, distance, comment (non vide)
    final missing = <String>[];
    if (controller.points <= 0) missing.add('Points');
    if (controller.groupSize <= 0) missing.add('Groupement');
    if (controller.shotCount <= 0) missing.add('Coups');
    if (controller.distance <= 0) missing.add('Distance');
    if ((controller.comment == null) || controller.comment!.trim().isEmpty) missing.add('Commentaire');
    if (missing.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Champs requis: ${missing.join(', ')}')),
        );
      }
      setState(()=> controller.showErrors = true);
      return;
    }
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
    return PopScope(
      canPop: false, // contrôle manuel
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // déjà géré
        if (await _confirmCancel()) {
            if (mounted) Navigator.of(context).pop(false);
        }
      },
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
    return WizardIntroStep(
      formKey: _formIntro,
      loadingExercise: _loadingExercise,
      linkedExercise: _linkedExercise,
      goals: _goals,
      weaponDraft: _weaponDraft,
      caliberController: _caliberCtrl,
      caliberFocusNode: _caliberFocus,
      categoryDraft: _categoryDraft,
      onCaliberChanged: (txt) {
        final wasDeletion = txt.length < _lastCalTxt.length;
        _lastCalTxt = txt;
        if (!wasDeletion) {
          final res = suggestFor(txt);
          if (res.autoReplacement != null && _caliberCtrl.text != res.autoReplacement) {
            _caliberCtrl.value = TextEditingValue(
              text: res.autoReplacement!,
              selection: TextSelection.collapsed(offset: res.autoReplacement!.length),
            );
            _lastCalTxt = res.autoReplacement!;
          }
        }
        _caliberDraft = _caliberCtrl.text;
      },
      onWeaponSaved: (v) => _weaponDraft = v ?? '',
      onCaliberSaved: (v) => _caliberDraft = v ?? '',
      onCategorySaved: (v) => _categoryDraft = v ?? SessionConstants.categoryEntrainement,
      onValidate: _onValidateIntro,
    );
  }

  // Contrôleurs séries (simple implémentation basique)
  final List<SeriesStepController> _seriesControllers = [];
  void _ensureSeriesControllers() {
    if (_seriesControllers.length == _session.series.length) return;
    _seriesControllers.clear();
    // Préférence prise par défaut
    String defaultHand = 'two';
    try { final box = Hive.box('app_preferences'); defaultHand = box.get('default_hand_method', defaultValue: 'two'); } catch(_){ }
    for (int i = 0; i < _session.series.length; i++) {
      final s = _session.series[i];
      final consigneText = s.comment;
      double defaultDistance;
      int defaultShot;
      HandMethod hand;
      if (i == 0) {
        defaultDistance = 25;
        defaultShot = 5;
        hand = (s.handMethod == HandMethod.twoHands && defaultHand == 'one') ? HandMethod.oneHand : s.handMethod;
      } else {
        // Utiliser les valeurs déjà déterminées du contrôleur précédent
        final prevCtrl = _seriesControllers[i-1];
        defaultDistance = prevCtrl.distance > 0 ? prevCtrl.distance : 25;
        defaultShot = prevCtrl.shotCount > 0 ? prevCtrl.shotCount : 5;
        hand = s.handMethod; // conserve la prise existante; on pourrait hériter du prev si besoin
      }
      _seriesControllers.add(SeriesStepController(
        points: 0,
        groupSize: 0,
        comment: '',
        shotCount: defaultShot,
        distance: defaultDistance,
        handMethod: hand,
        consigne: consigneText,
      ));
    }
  }

  Widget _buildSeries(int index) {
    _ensureSeriesControllers();
    final controller = _seriesControllers[index];
    return WizardSeriesStep(
      seriesIndex: index,
      controller: controller,
      isLastSeries: index == _seriesCount - 1,
      onValidate: () => _onValidateSeries(index + 1),
    );
  }

  Widget _buildSynthese() {
    return WizardSyntheseStep(
      formKey: _formSynthese,
      initialSynthese: _normalizedSyntheseInitial(),
      saving: _saving,
      onSaved: (v) => _syntheseDraft = v ?? '',
      onFinish: _onFinish,
    );
  }

  // Helper to normaliser synthèse initiale (ajout newline après phrase origine)
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
