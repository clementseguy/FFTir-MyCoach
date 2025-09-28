import 'package:flutter/material.dart';
import '../services/exercise_service.dart';
import '../models/exercise.dart';
import '../constants/exercises.dart';
import '../services/goal_service.dart';
import '../models/goal.dart';

class ExercisesListScreen extends StatefulWidget {
  const ExercisesListScreen({super.key});
  @override
  State<ExercisesListScreen> createState() => _ExercisesListScreenState();
}

class _ExercisesListScreenState extends State<ExercisesListScreen> {
  final ExerciseService _service = ExerciseService();
  late Future<List<Exercise>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() { _future = _service.listAll(); });
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
          IconButton(
            onPressed: _openCreate,
            icon: const Icon(Icons.add),
            tooltip: 'Nouvel exercice',
          ),
        ],
      ),
      body: FutureBuilder<List<Exercise>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
            final data = snap.data ?? const [];
          if (data.isEmpty) {
            return Center(
              child: TextButton.icon(
                onPressed: _openCreate,
                icon: const Icon(Icons.add),
                label: const Text('Créer le premier exercice'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final ex = data[i];
              return Card(
                child: ListTile(
                  title: Text(ex.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${ex.category} • ${ex.goalIds.length} objectif(s)'),
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
                    ],
                  ),
                  leading: Icon(
                    ex.description != null && ex.description!.trim().isNotEmpty ? Icons.description : Icons.fitness_center,
                    color: ex.description != null && ex.description!.trim().isNotEmpty ? Colors.amberAccent : null,
                  ),
                  trailing: const Icon(Icons.edit, size: 18),
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
  String _category = ExerciseCategories.technique;
  final GoalService _goalService = GoalService();
  List<Goal> _allGoals = [];
  final Set<String> _selectedGoals = {};
  bool _saving = false;
  final ExerciseService _service = ExerciseService();

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
      _category = widget.editing!.category;
      _selectedGoals.addAll(widget.editing!.goalIds);
      _descCtrl.text = widget.editing!.description ?? '';
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
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          goalIds: _selectedGoals.toList(),
        );
      } else {
        final updated = widget.editing!.copyWith(
          name: _nameCtrl.text,
          category: _category,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          goalIds: _selectedGoals.toList(),
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
      appBar: AppBar(title: Text(widget.editing == null ? 'Nouvel exercice' : 'Modifier exercice')),
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
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: ExerciseCategories.all.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(()=> _category = v ?? ExerciseCategories.technique),
              decoration: const InputDecoration(labelText: 'Catégorie'),
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
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.save),
              label: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}