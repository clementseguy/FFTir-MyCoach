import 'package:flutter/material.dart';
import '../services/exercise_service.dart';
import '../models/exercise.dart';
import '../services/session_service.dart';
import '../widgets/exercises_total_card.dart';
import 'session_detail_screen.dart';
import 'exercise_form_screen.dart';
import '../utils/exercise_sorting.dart';

/// Liste des exercices avec filtrage et tri
/// Refactorisé pour séparer la logique de listing du formulaire (voir exercise_form_screen.dart)
/// 
/// Architecture:
/// - Liste avec filtres repliables (catégorie, type)
/// - Badge indicateur sessions prévues
/// - Navigation vers formulaire extraction dans fichier séparé
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
  ExerciseSortMode _sortMode = ExerciseSortMode.defaultOrder;

  List<Exercise> _applySort(List<Exercise> list) => sortExercises(list, _sortMode);

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
          PopupMenuButton<ExerciseSortMode>(
            tooltip: 'Trier',
            icon: const Icon(Icons.sort),
            onSelected: (m)=> setState(()=> _sortMode = m),
            itemBuilder: (ctx) => [
              _menuItem(ExerciseSortMode.defaultOrder, 'Défaut'),
              _menuItem(ExerciseSortMode.nameAsc, 'Nom A→Z'),
              _menuItem(ExerciseSortMode.nameDesc, 'Nom Z→A'),
              _menuItem(ExerciseSortMode.category, 'Catégorie'),
              _menuItem(ExerciseSortMode.type, 'Type'),
              _menuItem(ExerciseSortMode.newest, 'Plus récents'),
            ],
          ),
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
          final data = _applySort(_applyFilters(raw));
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

PopupMenuItem<ExerciseSortMode> _menuItem(ExerciseSortMode m, String label) {
  return PopupMenuItem(value: m, child: Text(label));
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
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 8, top: 8, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
                  tooltip: expanded ? 'Replier' : 'Déplier',
                  icon: Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 22),
                  onPressed: onToggleExpanded,
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => SizeTransition(sizeFactor: anim, axisAlignment: -1.0, child: child),
              child: !expanded ? const SizedBox.shrink() : Padding(
                key: const ValueKey('filters-body'),
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
            ),
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

/// Badge informatif compact pour afficher icône + texte
class _Badge extends StatelessWidget {
  final IconData icon;
  final String text;
  final double? maxWidth;
  
  const _Badge({
    required this.icon,
    required this.text,
    this.maxWidth,
  });

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
        ? ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth!),
            child: content,
          )
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
