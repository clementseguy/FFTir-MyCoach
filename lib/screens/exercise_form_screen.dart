import 'package:flutter/material.dart';
import '../services/exercise_service.dart';
import '../services/goal_service.dart';
import '../models/exercise.dart';
import '../models/goal.dart';

/// Formulaire de création/édition d'un exercice
/// Séparé de ExercisesListScreen pour réduire la taille du fichier et clarifier les responsabilités
/// 
/// Architecture:
/// - État formulaire isolé
/// - Validation inline
/// - Sauvegarde asynchrone avec feedback
class ExerciseFormScreen extends StatefulWidget {
  final Exercise? editing;
  
  const ExerciseFormScreen({super.key, this.editing});

  @override
  State<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends State<ExerciseFormScreen> {
  final ExerciseService _service = ExerciseService();
  final GoalService _goalService = GoalService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _equipmentCtrl = TextEditingController();
  final List<TextEditingController> _consigneCtrls = [];
  
  // State
  ExerciseCategory _category = ExerciseCategory.technique;
  ExerciseType _type = ExerciseType.stand;
  final Set<String> _selectedGoals = {};
  List<Goal> _allGoals = [];
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    _equipmentCtrl.dispose();
    for (final c in _consigneCtrls) { c.dispose(); }
    super.dispose();
  }

  void _addConsigneField([String initial='']) {
    final c = TextEditingController(text: initial);
    setState(()=> _consigneCtrls.add(c));
  }

  void _removeConsigneField(int index) {
    if (index <0 || index>=_consigneCtrls.length) return;
    setState(()=> _consigneCtrls.removeAt(index));
  }

  Future<void> _initGoals() async {
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
              decoration: const InputDecoration(labelText: 'Nom de l\'exercice'),
              validator: (v) => (v==null||v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Objectifs, bénéfices attendus...',
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Durée',
                      suffixText: 'min',
                    ),
                    keyboardType: TextInputType.number,
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
              initialValue: _category,
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
              initialValue: _type,
              items: ExerciseType.values.map((t) => DropdownMenuItem(
                value: t,
                child: Text(Exercise(
                  id: '_tmp',
                  name: '',
                  categoryEnum: ExerciseCategory.technique,
                  type: t,
                  createdAt: DateTime.now(),
                ).typeLabelFr),
              )).toList(),
              onChanged: (v) => setState(()=> _type = v ?? ExerciseType.stand),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.list_alt, size: 20, color: Colors.amberAccent),
                const SizedBox(width: 8),
                const Text('Consignes / Étapes', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  onPressed: ()=> _addConsigneField(),
                  tooltip: 'Ajouter une étape',
                  icon: const Icon(Icons.add_circle_outline, color: Colors.amberAccent),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._consigneCtrls.asMap().entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Text('${e.key+1}.', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: e.value,
                        decoration: InputDecoration(
                          hintText: 'Consigne étape ${e.key+1}',
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_consigneCtrls.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                        onPressed: () => _removeConsigneField(e.key),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.flag, size: 20, color: Colors.amberAccent),
                const SizedBox(width: 8),
                const Text('Objectifs liés', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            if (_allGoals.isEmpty)
              const Text('Aucun objectif disponible', style: TextStyle(color: Colors.white54))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allGoals.map((g) {
                  final selected = _selectedGoals.contains(g.id);
                  return FilterChip(
                    label: Text(g.title),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedGoals.add(g.id);
                        } else {
                          _selectedGoals.remove(g.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
