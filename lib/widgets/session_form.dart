import '../forms/series_form_controllers.dart';
import 'package:flutter/material.dart';
import '../forms/series_form_data.dart';
import '../services/preferences_service.dart';
import '../utils/caliber_autocomplete.dart';
import '../config/app_config.dart';
import 'series_cards.dart';
import '../models/shooting_session.dart';
import '../constants/session_constants.dart';
import '../models/series.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';

class SessionForm extends StatefulWidget {
  final Map<String, dynamic>? initialSessionData;
  final void Function(ShootingSession session) onSave;
  final bool isEdit;
  const SessionForm({Key? key, this.initialSessionData, required this.onSave, this.isEdit = false}) : super(key: key);

  static SessionFormState? of(BuildContext context) {
    return context.findAncestorStateOfType<SessionFormState>();
  }

  @override
  State<SessionForm> createState() => SessionFormState();
}

class SessionFormState extends State<SessionForm> {
  late TextEditingController _syntheseController;
  final _formKey = GlobalKey<FormState>();
  DateTime? _date;
  late TextEditingController _weaponController;
  late TextEditingController _caliberController;
  final FocusNode _caliberFocus = FocusNode();
  bool _showAllCaliberOptions = false;
  String _lastCaliberText = '';
  late List<SeriesFormData> _series;
  late List<SeriesFormControllers> _seriesControllers;
  String _category = SessionConstants.categoryEntrainement;
  String _status = SessionConstants.statusRealisee; // allow planned
  // Exercises selection
  final ExerciseService _exerciseService = ExerciseService();
  List<Exercise> _allExercises = [];
  final Set<String> _selectedExerciseIds = <String>{};
  bool _loadingExercises = true;

  @override
  void initState() {
    super.initState();
    _weaponController = TextEditingController();
    _caliberController = TextEditingController();
  if (widget.initialSessionData != null) {
      final session = widget.initialSessionData!['session'];
      final seriesRaw = widget.initialSessionData!['series'];
      final List<dynamic> series = (seriesRaw is List) ? seriesRaw : [];
      _date = session['date'] != null && session['date'] != '' ? DateTime.tryParse(session['date']) : null;
      _weaponController.text = session['weapon'] ?? '';
      final existingCal = (session['caliber'] as String?);
      _caliberController.text = pickInitialCaliber(existing: existingCal, defaultCaliber: PreferencesService().getDefaultCaliber());
  _syntheseController = TextEditingController(text: session['synthese'] ?? '');
  _category = session['category'] ?? SessionConstants.categoryEntrainement;
  _status = session['status'] ?? SessionConstants.statusRealisee;
      // Preload existing exercises list from session map if any
      final existingEx = session['exercises'];
      if (existingEx is List) {
        for (final e in existingEx) {
          if (e is String) _selectedExerciseIds.add(e);
        }
      }
      _series = series.map((s) => SeriesFormData(
        shotCount: s['shot_count'] ?? 5,
        distance: (s['distance'] as num?)?.toDouble() ?? 25,
        points: s['points'] ?? 0,
        groupSize: (s['group_size'] as num?)?.toDouble() ?? 0,
        comment: s['comment'] ?? '',
      )).toList();
      if (_series.isEmpty) _series = [SeriesFormData(distance: 25)];
    } else {
  _caliberController.text = pickInitialCaliber(existing: null, defaultCaliber: PreferencesService().getDefaultCaliber());
      _series = [SeriesFormData(distance: 25)];
      _date = null;
  _syntheseController = TextEditingController();
  _category = SessionConstants.categoryEntrainement;
  _status = SessionConstants.statusRealisee;
    }
    final defaultMethod = PreferencesService().getDefaultHandMethod();
    _seriesControllers = _series.map((s) => SeriesFormControllers(
      shotCount: s.shotCount,
      distance: s.distance,
      points: s.points,
      groupSize: s.groupSize,
      comment: s.comment,
      handMethod: 'two',
    )).toList();
    for (int i=0;i<_seriesControllers.length;i++) {
      // Try detect existing map method using initialSessionData raw map if provided
      if (widget.initialSessionData != null) {
        final rawSeries = widget.initialSessionData!['series'];
        if (rawSeries is List && i < rawSeries.length) {
          final raw = rawSeries[i];
          if (raw is Map && raw['hand_method'] == 'one') {
            _seriesControllers[i].handMethod = 'one';
            continue;
          }
          if (raw is Map && raw['hand_method'] == 'two') {
            _seriesControllers[i].handMethod = 'two';
            continue;
          }
        }
      }
      _seriesControllers[i].handMethod = defaultMethod == HandMethod.oneHand ? 'one' : 'two';
    }
    _lastCaliberText = _caliberController.text;
    _caliberFocus.addListener(() {
      if (_caliberFocus.hasFocus) {
        setState(() => _showAllCaliberOptions = true);
        final val = _caliberController.value;
        _caliberController.value = val.copyWith(text: val.text, selection: val.selection);
      } else {
        if (_showAllCaliberOptions) setState(() => _showAllCaliberOptions = false);
      }
    });
    // Load exercises asynchronously
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      final list = await _exerciseService.listAll();
      if (mounted) {
        setState(() {
          _allExercises = list..sort((a,b)=> a.priority.compareTo(b.priority));
          _loadingExercises = false;
        });
      }
    } catch (_) {
      if (mounted) setState(()=> _loadingExercises = false);
    }
  }

  @override
  void dispose() {
    for (final c in _seriesControllers) {
      c.dispose();
    }
    _weaponController.dispose();
    _caliberController.dispose();
    _caliberFocus.dispose();
    _syntheseController.dispose();
    super.dispose();
  }

  void _addSeries() {
    setState(() {
      // Propager la distance de la dernière série si disponible, sinon 25m
      double propagatedDistance = 25;
      if (_seriesControllers.isNotEmpty) {
        final txt = _seriesControllers.last.distanceController.text.trim();
        final parsed = double.tryParse(txt.replaceAll(',', '.'));
        if (parsed != null && parsed > 0) propagatedDistance = parsed;
      }
      _series.add(SeriesFormData(distance: propagatedDistance));
      _seriesControllers.add(SeriesFormControllers(
        shotCount: 5,
        distance: propagatedDistance,
        points: 0,
        groupSize: 0,
        comment: '',
        handMethod: PreferencesService().getDefaultHandMethod() == HandMethod.oneHand ? 'one' : 'two',
      ));
    });
    // Après rebuild, focus précis via FocusNodes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = _seriesControllers.last;
      final ordered = [
        {'ctrl': c.shotCountController, 'focus': c.shotCountFocus},
        {'ctrl': c.distanceController, 'focus': c.distanceFocus},
        {'ctrl': c.pointsController, 'focus': c.pointsFocus},
        {'ctrl': c.groupSizeController, 'focus': c.groupSizeFocus},
        {'ctrl': c.commentController, 'focus': c.commentFocus},
      ];
      for (final item in ordered) {
        final TextEditingController ctrl = item['ctrl'] as TextEditingController;
        final FocusNode node = item['focus'] as FocusNode;
        final text = ctrl.text.trim();
        if (text.isEmpty || text == '0') {
          FocusScope.of(context).requestFocus(node);
          ctrl.selection = TextSelection(baseOffset: 0, extentOffset: text.length);
          break;
        }
      }
    });
  }

  // _save supprimé (logique de validation déplacée dans callback externe si nécessaire)
  bool validateAndBuild() {
    if (!_formKey.currentState!.validate()) return false;
    if (_status == SessionConstants.statusRealisee) {
      if (_series.isEmpty || _series.every((s) => s.shotCount == 0 && s.distance == 0 && s.points == 0 && s.groupSize == 0 && s.comment.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veuillez ajouter au moins une série à la session réalisée.')),
        );
        return false;
      }
    }
    if (_date == null && _status == SessionConstants.statusRealisee) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La date est obligatoire.')),
      );
      return false;
    }
    // Conserver l'id session si édition
    int? existingId;
    if (widget.initialSessionData != null) {
      final sess = widget.initialSessionData!['session'];
      if (sess is Map && sess['id'] != null) {
        existingId = sess['id'] as int?;
      }
    }
    final session = ShootingSession(
      id: existingId,
      date: _date,
      weapon: _weaponController.text,
      caliber: _caliberController.text,
  status: _status,
      series: List.generate(_series.length, (i) => Series(
        shotCount: int.tryParse(_seriesControllers[i].shotCountController.text) ?? 0,
        distance: double.tryParse(_seriesControllers[i].distanceController.text) ?? 0,
        points: int.tryParse(_seriesControllers[i].pointsController.text) ?? 0,
        groupSize: double.tryParse(_seriesControllers[i].groupSizeController.text) ?? 0,
        comment: _seriesControllers[i].commentController.text.trim(),
        handMethod: _seriesControllers[i].handMethod == 'one' ? HandMethod.oneHand : HandMethod.twoHands,
      )),
      synthese: _syntheseController.text,
      category: _category,
      exercises: _selectedExerciseIds.toList(),
    );
    widget.onSave(session);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final totalPoints = _seriesControllers.fold<int>(0, (a,c){
      final v = int.tryParse(c.pointsController.text) ?? 0;
      return a + v;
    });
    final double avgPoints = _seriesControllers.isEmpty ? 0.0 : totalPoints / _seriesControllers.length;
    double? dominantDistance;
    if (_seriesControllers.isNotEmpty) {
      final distances = <double,int>{};
      for (final c in _seriesControllers) {
        final d = double.tryParse(c.distanceController.text) ?? 0;
        if (d>0) distances[d] = (distances[d]??0)+1;
      }
      if (distances.isNotEmpty) {
        dominantDistance = distances.entries.reduce((a,b)=> a.value>=b.value? a:b).key;
      }
    }
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _FormSummaryHeader(
            date: _date,
            onPickDate: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(()=> _date = picked);
            },
            seriesCount: _seriesControllers.length,
            totalPoints: totalPoints,
            avgPoints: avgPoints,
            dominantDistance: dominantDistance,
          ),
          SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _weaponController,
                  decoration: InputDecoration(labelText: 'Arme (optionnel si prévue)'),
                  validator: (v){
                    if (_status == SessionConstants.statusPrevue) return null; // optional
                    if (v==null||v.isEmpty) return 'Requis';
                    return null;
                  },
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: RawAutocomplete<String>(
                  textEditingController: _caliberController,
                  focusNode: _caliberFocus,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final list = AppConfig.I.calibers;
                    if (_showAllCaliberOptions) return list;
                    final q = textEditingValue.text.trim();
                    if (q.isEmpty) return list; // show all when empty
                    return list.where((c) => c.toLowerCase().contains(q.toLowerCase()));
                  },
                  fieldViewBuilder: (context, ctrl, focus, onFieldSubmitted) {
                    return TextFormField(
                      controller: ctrl,
                      focusNode: focus,
                      decoration: const InputDecoration(labelText: 'Calibre'),
                      validator: (v)=> v==null||v.isEmpty? 'Requis': null,
                      onChanged: (txt) {
                        if (_showAllCaliberOptions) setState(() => _showAllCaliberOptions = false);
                        final wasDeletion = txt.length < _lastCaliberText.length;
                        _lastCaliberText = txt;
                        if (wasDeletion) return;
                        final res = suggestFor(txt);
                        if (res.autoReplacement != null && ctrl.text != res.autoReplacement) {
                          ctrl.value = ctrl.value.copyWith(
                            text: res.autoReplacement,
                            selection: TextSelection.collapsed(offset: res.autoReplacement!.length),
                          );
                          _lastCaliberText = res.autoReplacement!;
                        }
                      },
                      onFieldSubmitted: (_) => onFieldSubmitted(),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    final opts = options.toList();
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        color: Theme.of(context).cardColor,
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220, minWidth: 220),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: opts.length,
                            itemBuilder: (context, index) {
                              final opt = opts[index];
                              return ListTile(
                                dense: true,
                                title: Text(opt),
                                onTap: () {
                                  if (opt == 'Autre') {
                                    final val = 'Autre : ';
                                    _caliberController.value = TextEditingValue(text: val, selection: TextSelection.collapsed(offset: val.length));
                                  } else {
                                    onSelected(opt);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: InputDecoration(labelText: 'Catégorie'),
            items: SessionConstants.categories.map((c)=> DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v)=> setState(()=> _category = v ?? SessionConstants.categoryEntrainement),
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: InputDecoration(labelText: 'Statut'),
            items: [
              DropdownMenuItem(value: SessionConstants.statusRealisee, child: Text('Réalisée')),
              DropdownMenuItem(value: SessionConstants.statusPrevue, child: Text('Prévue')),
            ],
            onChanged: (v)=> setState(()=> _status = v ?? SessionConstants.statusRealisee),
          ),
          // No direct goal link; exercises link goals indirectly.
          SizedBox(height: 24),
          // ---- Exercises selection ----
          _ExercisesSelector(
            loading: _loadingExercises,
            exercises: _allExercises,
            selectedIds: _selectedExerciseIds,
            onToggle: (id) {
              setState(() {
                if (_selectedExerciseIds.contains(id)) {
                  _selectedExerciseIds.remove(id);
                } else {
                  _selectedExerciseIds.add(id);
                }
              });
            },
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.list_alt, size: 18, color: Colors.amberAccent),
              SizedBox(width: 8),
              Text('Séries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Spacer(),
              Text('${_seriesControllers.length}', style: TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
          SizedBox(height: 8),
          ..._series.asMap().entries.map((entry) {
            final i = entry.key;
            final c = _seriesControllers[i];
            return SeriesEditCard(
              index: i,
              controllers: c,
              canDelete: _series.length > 1,
              onDelete: () {
                setState(() {
                  _series.removeAt(i);
                  _seriesControllers[i].dispose();
                  _seriesControllers.removeAt(i);
                });
              },
              onDuplicate: () {
                setState(() {
                  final newData = SeriesFormData(
                    shotCount: int.tryParse(c.shotCountController.text) ?? 5,
                    distance: double.tryParse(c.distanceController.text) ?? 25,
                    points: int.tryParse(c.pointsController.text) ?? 0,
                    groupSize: double.tryParse(c.groupSizeController.text) ?? 0,
                    comment: c.commentController.text,
                  );
                  _series.insert(i + 1, newData);
                  _seriesControllers.insert(i + 1, SeriesFormControllers(
                    shotCount: newData.shotCount,
                    distance: newData.distance,
                    points: newData.points,
                    groupSize: newData.groupSize,
                    comment: newData.comment,
                    handMethod: c.handMethod,
                  ));
                });
              },
            );
          }),
          SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _addSeries,
            icon: Icon(Icons.add),
            label: Text('Ajouter une série'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.amberAccent,
              side: BorderSide(color: Colors.amberAccent.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
          SizedBox(height: 28),
          _SyntheseCard(controller: _syntheseController),
        ],
      ),
    );
  }
}

class _FormSummaryHeader extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onPickDate;
  final int seriesCount;
  final int totalPoints;
  final double avgPoints;
  final double? dominantDistance;
  const _FormSummaryHeader({required this.date, required this.onPickDate, required this.seriesCount, required this.totalPoints, required this.avgPoints, required this.dominantDistance});
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: Colors.amberAccent),
                SizedBox(width: 8),
                Text(date!=null? '${date!.day}/${date!.month}/${date!.year}':'Date ?', style: TextStyle(fontWeight: FontWeight.w600)),
                Spacer(),
                TextButton.icon(onPressed: onPickDate, icon: Icon(Icons.calendar_month, size: 18), label: Text('Choisir')),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                _MiniStat(label: 'Séries', value: seriesCount.toString(), icon: Icons.list_alt, color: Colors.lightBlueAccent),
                _DividerV(),
                _MiniStat(label: 'Total', value: totalPoints.toString(), icon: Icons.score, color: Colors.pinkAccent),
                _DividerV(),
                _MiniStat(label: 'Moy.', value: avgPoints.toStringAsFixed(1), icon: Icons.stacked_line_chart, color: Colors.greenAccent),
                _DividerV(),
                _MiniStat(label: 'Dist.', value: dominantDistance!=null? '${dominantDistance!.toStringAsFixed(0)}m':'-', icon: Icons.social_distance, color: Colors.tealAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label; final String value; final IconData icon; final Color color;
  const _MiniStat({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Text(label, style: TextStyle(fontSize: 9.5, color: Colors.white60)),
                    ),
                    SizedBox(height: 2),
                    FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DividerV extends StatelessWidget { @override Widget build(BuildContext context)=> Container(width:1, height:40, color: Colors.white12, margin: EdgeInsets.symmetric(horizontal:8)); }


class _SyntheseCard extends StatelessWidget {
  final TextEditingController controller;
  const _SyntheseCard({required this.controller});
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize, color: Colors.amberAccent),
                SizedBox(width: 8),
                Text('Synthèse tireur', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Récapitulatif',
                hintText: 'Ressenti, axes travaillés, contexte...',
              ),
              minLines: 3,
              maxLines: 8,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for selecting multiple exercises inside the session form.
class _ExercisesSelector extends StatelessWidget {
  final bool loading;
  final List<Exercise> exercises;
  final Set<String> selectedIds;
  final void Function(String id) onToggle;
  const _ExercisesSelector({required this.loading, required this.exercises, required this.selectedIds, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: Colors.amberAccent),
                SizedBox(width: 8),
                Text('Exercices liés', style: TextStyle(fontWeight: FontWeight.w600)),
                Spacer(),
                if (!loading) Text('${selectedIds.length}', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
            SizedBox(height: 12),
            if (loading)
              Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)))
            else if (exercises.isEmpty)
              Text('Aucun exercice créé pour le moment.', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.white70))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: exercises.map((e) {
                  final selected = selectedIds.contains(e.id);
                  return FilterChip(
                    selected: selected,
                    label: Text(e.name, style: TextStyle(fontSize: 12)),
                    avatar: Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                      color: selected ? Colors.greenAccent : Colors.white54,
                    ),
                    onSelected: (_) => onToggle(e.id),
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    selectedColor: Colors.greenAccent.withValues(alpha: 0.25),
                    shape: StadiumBorder(side: BorderSide(color: selected ? Colors.greenAccent : Colors.white12)),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
