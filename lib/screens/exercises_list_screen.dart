import 'package:flutter/material.dart';
import '../services/exercise_service.dart';
import '../models/exercise.dart';
import '../services/goal_service.dart';
import '../models/goal.dart';
import '../services/session_service.dart';
import '../widgets/exercises_total_card.dart';
import 'session_detail_screen.dart';

class ExercisesListScreen extends StatefulWidget {
  const ExercisesListScreen({super.key});
  @override
  State<ExercisesListScreen> createState() => _ExercisesListScreenState();
}

class _ExercisesListScreenState extends State<ExercisesListScreen> {
  final ExerciseService _service = ExerciseService();
  final SessionService _sessionService = SessionService();
  late Future<List<Exercise>> _future;
  // Map des exercices ayant au moins une session prévue associée
  Map<String, bool> _plannedExerciseMap = {};
  // Filtres sélectionnés
  final Set<ExerciseCategory> _selectedCategories = {}; // vide = toutes
  final Set<ExerciseType> _selectedTypes = {}; // vide = tous
  bool _filtersExpanded = false; // replié par défaut

  List<Exercise> _applyFilters(List<Exercise> list) {
    return list.where((e) {
      if (_selectedCategories.isNotEmpty && !_selectedCategories.contains(e.categoryEnum)) return false;
      if (_selectedTypes.isNotEmpty && !_selectedTypes.contains(e.type)) return false;
      return true;
    }).toList();
  }

  void _toggleCategory(ExerciseCategory c) {
    setState(() {
      if (_selectedCategories.contains(c)) {
        _selectedCategories.remove(c);
      } else {
        _selectedCategories.add(c);
      }
    });
  }

  void _toggleType(ExerciseType t) {
    setState(() {
      if (_selectedTypes.contains(t)) {
        _selectedTypes.remove(t);
      } else {
        _selectedTypes.add(t);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() { _future = _service.listAll(); });
    // Rafraîchir aussi le mapping des exercices planifiés
    _refreshPlannedMapping();
  }

  Future<void> _refreshPlannedMapping() async {
    try {
      final sessions = await _sessionService.getAllSessions();
      final Map<String, bool> map = {};
      for (final s in sessions) {
        if (s.status == 'prévue') {
          for (final exId in s.exercises) {
            map[exId] = true;
          }
        }
      }
      if (mounted) setState(()=> _plannedExerciseMap = map);
    } catch (_) {
      // silencieux: ne pas casser l'affichage des exercices si session fetch échoue
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExerciseFormScreen()),
    );
    if (created == true) _reload();
  }

  Future<void> _openEdit(Exercise exercise) async {
    final updated = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExerciseFormScreen(editing: exercise)),
    );
    if (updated == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercices'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: FutureBuilder<List<Exercise>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final raw = snap.data ?? const [];
          final data = _applyFilters(raw);
          if (raw.isEmpty) {
            return Center(
              child: TextButton.icon(
                onPressed: _openCreate,
                icon: const Icon(Icons.add),
                label: const Text('Créer le premier exercice'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12,12,12,12),
            itemCount: data.length + 2,
            separatorBuilder: (context, i) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              if (i == 0) {
                return const ExercisesTotalCard();
              }
              if (i == 1) {
                return _FiltersBar(
                  expanded: _filtersExpanded,
                  onToggleExpanded: () => setState(()=> _filtersExpanded = !_filtersExpanded),
                  selectedCategories: _selectedCategories,
                  onToggleCategory: _toggleCategory,
                  selectedTypes: _selectedTypes,
                  onToggleType: _toggleType,
                );
              }
              final ex = data[i-2];
              return Card(
                child: ListTile(
                  title: Text(ex.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${ex.categoryLabelFr} • ${ex.goalIds.length} objectif(s)'),
                      Padding(
                        padding: const EdgeInsets.only(top:2.0),
                        child: Text('Type: ${ex.typeLabelFr}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      ),
                      if (ex.consignes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top:4.0),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _Badge(icon: Icons.list_alt, text: '${ex.consignes.length} consigne(s)'),
                            ],
                          ),
                        ),
                      if (ex.description != null && ex.description!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top:4.0),
                          child: Text(
                            ex.description!.split('\n').first.trim(),
                            style: const TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (ex.durationMinutes != null || (ex.equipment != null && ex.equipment!.trim().isNotEmpty))
                        Padding(
                          padding: const EdgeInsets.only(top:6.0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (ex.durationMinutes != null)
                                _Badge(icon: Icons.timer, text: '${ex.durationMinutes} min'),
                              if (ex.equipment != null && ex.equipment!.trim().isNotEmpty)
                                _Badge(icon: Icons.build, text: ex.equipment!.trim(), maxWidth: 140),
                            ],
                          ),
                        ),
                    ],
                  ),
                  leading: Icon(
                    ex.description != null && ex.description!.trim().isNotEmpty ? Icons.description : Icons.fitness_center,
                    color: ex.description != null && ex.description!.trim().isNotEmpty ? Colors.amberAccent : null,
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      if (ex.type == ExerciseType.stand && _plannedExerciseMap[ex.id] == true)
                        Tooltip(
                          message: 'Au moins une session prévue liée',
                          child: SizedBox(
                            height: 40, // proche de la hauteur d'un IconButton standard
                            width: 32,
                            child: Center(
                              child: Icon(Icons.schedule, size: 20, color: Colors.lightBlueAccent),
                            ),
                          ),
                        ),
                      if (ex.type == ExerciseType.stand)
                        IconButton(
                          icon: const Icon(Icons.event_available, size: 20),
                          tooltip: 'Planifier une session',
                          onPressed: () async {
                            try {
                              final sess = await _sessionService.planFromExercise(ex);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Session prévue créée (${sess.series.length} série(s))')),
                              );
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SessionDetailScreen(sessionData: {
                                    'session': sess.toMap(),
                                    'series': sess.series.map((s)=> s.toMap()).toList(),
                                  }),
                                ),
                              );
                              // Actualiser le mapping (au cas où l'utilisateur revienne en arrière sans convertir)
                              await _refreshPlannedMapping();
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Impossible de planifier: $e')),
                              );
                            }
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        tooltip: 'Modifier',
                        onPressed: () => _openEdit(ex),
                      ),
                    ],
                  ),
                  onTap: () => _openEdit(ex),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final Set<ExerciseCategory> selectedCategories;
  final void Function(ExerciseCategory) onToggleCategory;
  final Set<ExerciseType> selectedTypes;
  final void Function(ExerciseType) onToggleType;
  const _FiltersBar({
    required this.expanded,
    required this.onToggleExpanded,
    required this.selectedCategories,
    required this.onToggleCategory,
    required this.selectedTypes,
    required this.onToggleType,
  });

  @override
  Widget build(BuildContext context) {
    final cats = ExerciseCategory.values;
    final types = ExerciseType.values;
    final hasActive = selectedCategories.isNotEmpty || selectedTypes.isNotEmpty;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: AnimatedCrossFade(
        crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 250),
        firstChild: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onToggleExpanded,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 18, color: Colors.amberAccent),
                const SizedBox(width: 8),
                const Text('Filtres', style: TextStyle(fontWeight: FontWeight.w600)),
                if (hasActive) ...[
                  const SizedBox(width: 8),
                  _ActiveCountBadge(count: selectedCategories.length + selectedTypes.length),
                ],
                const Spacer(),
                Icon(Icons.expand_more, color: Colors.white70),
              ],
            ),
          ),
        ),
        secondChild: Padding(
          padding: const EdgeInsets.fromLTRB(12,12,12,8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.filter_list, size: 18, color: Colors.amberAccent),
                  const SizedBox(width: 8),
                  const Text('Filtres', style: TextStyle(fontWeight: FontWeight.w600)),
                  if (hasActive) ...[
                    const SizedBox(width: 8),
                    _ActiveCountBadge(count: selectedCategories.length + selectedTypes.length),
                  ],
                  const Spacer(),
                  IconButton(
                    tooltip: 'Replier',
                    icon: const Icon(Icons.expand_less, size: 20),
                    onPressed: onToggleExpanded,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Catégories', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in cats)
                    FilterChip(
                      label: Text(_catLabel(c)),
                      selected: selectedCategories.contains(c),
                      onSelected: (_) => onToggleCategory(c),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text('Type', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final t in types)
                    FilterChip(
                      label: Text(t == ExerciseType.stand ? 'Stand' : 'Maison'),
                      selected: selectedTypes.contains(t),
                      onSelected: (_) => onToggleType(t),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (hasActive)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _clearAll(),
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Réinitialiser'),
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  ),
                ),
            ],
          ),
        ),
        layoutBuilder: (topChild, topKey, bottomChild, bottomKey) => Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(key: bottomKey, child: bottomChild),
            Positioned(key: topKey, child: topChild),
          ],
        ),
      ),
    );
  }

  void _clearAll() {
    // On appelle les toggle uniquement pour les éléments sélectionnés pour les vider.
    final catsToClear = List<ExerciseCategory>.from(selectedCategories);
    final typesToClear = List<ExerciseType>.from(selectedTypes);
    for (final c in catsToClear) { onToggleCategory(c); }
    for (final t in typesToClear) { onToggleType(t); }
  }

  static String _catLabel(ExerciseCategory c) {
    switch (c) {
      case ExerciseCategory.precision: return 'Précision';
      case ExerciseCategory.group: return 'Groupement';
      case ExerciseCategory.speed: return 'Vitesse';
      case ExerciseCategory.technique: return 'Technique';
      case ExerciseCategory.mental: return 'Mental';
      case ExerciseCategory.physical: return 'Physique';
    }
  }
}

class _ActiveCountBadge extends StatelessWidget {
  final int count;
  const _ActiveCountBadge({required this.count});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amberAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
      ),
      child: Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amberAccent)),
    );
  }
}

class ExerciseFormScreen extends StatefulWidget {
  final Exercise? editing;
  const ExerciseFormScreen({super.key, this.editing});
  @override
  State<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends State<ExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _equipmentCtrl = TextEditingController();
  ExerciseCategory _category = ExerciseCategory.technique;
  ExerciseType _type = ExerciseType.stand;
  final GoalService _goalService = GoalService();
  List<Goal> _allGoals = [];
  final Set<String> _selectedGoals = {};
  bool _saving = false;
  final ExerciseService _service = ExerciseService();
  final List<TextEditingController> _consigneCtrls = [];

  void _addConsigneField([String initial='']) {
    final c = TextEditingController(text: initial);
    setState(()=> _consigneCtrls.add(c));
  }

  void _removeConsigneField(int index) {
    if (index <0 || index>=_consigneCtrls.length) return;
    setState(()=> _consigneCtrls.removeAt(index));
  }

  Future<void> _initGoals() async {
    // GoalService requires init for priority migration; ignore if already
    try { await _goalService.init(); } catch (_) {}
    final goals = await _goalService.listAll();
    if (mounted) setState(() => _allGoals = goals);
  }

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      _nameCtrl.text = widget.editing!.name;
      _category = widget.editing!.categoryEnum;
      _type = widget.editing!.type;
      _selectedGoals.addAll(widget.editing!.goalIds);
      _descCtrl.text = widget.editing!.description ?? '';
      if (widget.editing!.durationMinutes != null) {
        _durationCtrl.text = widget.editing!.durationMinutes.toString();
      }
      _equipmentCtrl.text = widget.editing!.equipment ?? '';
      for (final step in widget.editing!.consignes) {
        _consigneCtrls.add(TextEditingController(text: step));
      }
    }
    if (_consigneCtrls.isEmpty) {
      // Start with one empty field for usability
      _addConsigneField();
    }
    _initGoals();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(()=> _saving = true);
    try {
      if (widget.editing == null) {
        await _service.addExercise(
          name: _nameCtrl.text,
          category: _category,
          type: _type,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          goalIds: _selectedGoals.toList(),
          durationMinutes: int.tryParse(_durationCtrl.text.trim()),
          equipment: _equipmentCtrl.text.trim().isEmpty ? null : _equipmentCtrl.text.trim(),
          consignes: _consigneCtrls.map((c)=>c.text).toList(),
        );
      } else {
        final updated = widget.editing!.copyWith(
          name: _nameCtrl.text,
          category: _category,
          type: _type,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          goalIds: _selectedGoals.toList(),
          durationMinutes: int.tryParse(_durationCtrl.text.trim()),
          equipment: _equipmentCtrl.text.trim().isEmpty ? null : _equipmentCtrl.text.trim(),
          consignes: _consigneCtrls.map((c)=>c.text).toList(),
        );
        await _service.updateExercise(updated);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(()=> _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editing == null ? 'Nouvel exercice' : 'Modifier exercice'),
        actions: [
          IconButton(
            icon: _saving ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.save),
            tooltip: 'Enregistrer',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Nom requis';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              minLines: 3,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Consigne détaillée',
                hintText: 'Décris étape par étape :\nSérie 1 : ...\nSérie 2 : ...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Durée estimée (min)',
                      hintText: 'ex: 15',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v==null || v.trim().isEmpty) return null; // optional
                      final n = int.tryParse(v.trim());
                      if (n==null || n<=0) return 'Valeur invalide';
                      if (n>600) return '>600 ?';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _equipmentCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Matériel requis',
                      hintText: 'ex: timer, cibles...',
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ExerciseCategory>(
              value: _category,
              items: ExerciseCategory.values.map((c) => DropdownMenuItem(
                value: c,
                child: Text(Exercise(
                  id: '_tmp',
                  name: '',
                  categoryEnum: c,
                  type: ExerciseType.stand,
                  createdAt: DateTime.now(),
                ).categoryLabelFr),
              )).toList(),
              onChanged: (v) => setState(()=> _category = v ?? ExerciseCategory.technique),
              decoration: const InputDecoration(labelText: 'Catégorie'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ExerciseType>(
              value: _type,
              items: ExerciseType.values.map((t) => DropdownMenuItem(
                value: t,
                child: Text(t == ExerciseType.stand ? 'Stand' : 'Maison'),
              )).toList(),
              onChanged: (v) => setState(()=> _type = v ?? ExerciseType.stand),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.list_alt, size: 18, color: Colors.amberAccent),
                const SizedBox(width: 8),
                Text('Consignes', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Text('(${_consigneCtrls.where((c)=>c.text.trim().isNotEmpty).length})', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Ajouter une consigne',
                  onPressed: () => _addConsigneField(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_consigneCtrls.isEmpty)
              const Text('Aucune consigne', style: TextStyle(color: Colors.white54))
            else
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex>oldIndex) newIndex--;
                    final item = _consigneCtrls.removeAt(oldIndex);
                    _consigneCtrls.insert(newIndex, item);
                  });
                },
                children: [
                  for (int i=0;i<_consigneCtrls.length;i++)
                    Dismissible(
                      key: ValueKey('consigne_$i'),
                      background: Container(color: Colors.redAccent),
                      onDismissed: (_){ _removeConsigneField(i); },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ReorderableDragStartListener(
                              index: i,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 14, right: 8),
                                child: Icon(Icons.drag_indicator, size: 20, color: Colors.white54),
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _consigneCtrls[i],
                                decoration: InputDecoration(
                                  labelText: 'Consigne ${i+1}',
                                ),
                                minLines: 1,
                                maxLines: 4,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              tooltip: 'Supprimer',
                              onPressed: () => _removeConsigneField(i),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.flag, size: 18, color: Colors.amberAccent),
                const SizedBox(width: 8),
                Text('Objectifs associés', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Text('(${_selectedGoals.length})', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            if (_allGoals.isEmpty)
              const Text('Aucun objectif existant', style: TextStyle(color: Colors.white54))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allGoals.map((g) {
                  final selected = _selectedGoals.contains(g.id);
                  return FilterChip(
                    label: Text(g.title, overflow: TextOverflow.ellipsis),
                    selected: selected,
                    onSelected: (s) {
                      setState(() {
                        if (s) {
                          _selectedGoals.add(g.id);
                        } else {
                          _selectedGoals.remove(g.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 32),
            // Bouton de bas de page retiré (sauvegarde via AppBar)
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String text;
  final double? maxWidth;
  const _Badge({required this.icon, required this.text, this.maxWidth});
  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.amberAccent),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    final child = maxWidth != null
        ? ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth!), child: content)
        : content;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: child,
    );
  }
}