import 'package:flutter/material.dart';
import '../../models/series.dart';
import '../../models/exercise.dart';
import '../../models/goal.dart';

/// Étape introduction du wizard (exercice, arme, calibre, catégorie)
class WizardIntroStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool loadingExercise;
  final Exercise? linkedExercise;
  final List<Goal> goals;
  final String? weaponDraft;
  final TextEditingController caliberController;
  final FocusNode caliberFocusNode;
  final String? categoryDraft;
  final ValueChanged<String> onCaliberChanged;
  final ValueChanged<String?> onWeaponSaved;
  final ValueChanged<String?> onCaliberSaved;
  final ValueChanged<String?> onCategorySaved;
  final VoidCallback onValidate;

  const WizardIntroStep({
    super.key,
    required this.formKey,
    required this.loadingExercise,
    required this.linkedExercise,
    required this.goals,
    required this.weaponDraft,
    required this.caliberController,
    required this.caliberFocusNode,
    required this.categoryDraft,
    required this.onCaliberChanged,
    required this.onWeaponSaved,
    required this.onCaliberSaved,
    required this.onCategorySaved,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    final hasExercise = linkedExercise != null || loadingExercise;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
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
                    else if (loadingExercise) const Padding(
                      padding: EdgeInsets.symmetric(vertical:8.0),
                      child: SizedBox(width:24, height:24, child: CircularProgressIndicator(strokeWidth:2)),
                    )
                    else if (linkedExercise != null) ...[
                      Text(linkedExercise!.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (linkedExercise!.description != null && linkedExercise!.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(linkedExercise!.description!, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                      if (goals.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: goals.map((g)=> Container(
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
              initialValue: weaponDraft,
              decoration: const InputDecoration(labelText: 'Arme'),
              onSaved: onWeaponSaved,
            ),
            Focus(
              focusNode: caliberFocusNode,
              child: TextFormField(
                controller: caliberController,
                decoration: const InputDecoration(labelText: 'Calibre'),
                onChanged: onCaliberChanged,
                onSaved: onCaliberSaved,
              ),
            ),
            TextFormField(
              initialValue: categoryDraft,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              onSaved: onCategorySaved,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: onValidate,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Commencer'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// Étape série individuelle
class WizardSeriesStep extends StatelessWidget {
  final int seriesIndex; // Index réel de la série (0-based)
  final SeriesStepController controller;
  final bool isLastSeries;
  final VoidCallback onValidate;

  const WizardSeriesStep({
    super.key,
    required this.seriesIndex,
    required this.controller,
    required this.isLastSeries,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    final consigne = controller.consigne.trim().isEmpty ? 'Pas de consigne' : controller.consigne;
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
                    key: ValueKey('points_${seriesIndex}_${controller.points}'),
                    initialValue: '',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Points'),
                    onChanged: (v){ controller.points = int.tryParse(v) ?? 0; },
                    validator: (_) => (controller.showErrors && controller.points<=0) ? 'Requis' : null,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(
                    key: ValueKey('group_${seriesIndex}_${controller.groupSize}'),
                    initialValue: '',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Groupement'),
                    onChanged: (v){ controller.groupSize = double.tryParse(v) ?? 0; },
                    validator: (_) => (controller.showErrors && controller.groupSize<=0) ? 'Requis' : null,
                  )),
                ]),
                const SizedBox(height: 12),
                Row(children:[
                  Expanded(child: TextFormField(
                    key: ValueKey('shots_${seriesIndex}_${controller.shotCount}'),
                    initialValue: controller.shotCount.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Coups'),
                    onChanged: (v){ controller.shotCount = int.tryParse(v) ?? controller.shotCount; },
                    validator: (_) => (controller.showErrors && controller.shotCount<=0) ? 'Requis' : null,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(
                    key: ValueKey('dist_${seriesIndex}_${controller.distance}'),
                    initialValue: controller.distance.toString(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Distance (m)'),
                    onChanged: (v){ controller.distance = double.tryParse(v) ?? controller.distance; },
                    validator: (_) => (controller.showErrors && controller.distance<=0) ? 'Requis' : null,
                  )),
                ]),
                const SizedBox(height: 12),
                HandMethodSelector(
                  initial: controller.handMethod,
                  onChanged: (m){ controller.handMethod = m; },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: ValueKey('comment_${seriesIndex}'),
                  initialValue: '',
                  decoration: const InputDecoration(labelText: 'Commentaire série'),
                  onChanged: (v)=> controller.comment = v,
                  maxLines: null,
                  validator: (_) => (controller.showErrors && (controller.comment==null || controller.comment!.trim().isEmpty)) ? 'Requis' : null,
                ),
                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: onValidate,
                    child: Text(isLastSeries ? 'Suite' : 'Suivant'),
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

/// Étape synthèse finale
class WizardSyntheseStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String initialSynthese;
  final bool saving;
  final ValueChanged<String?> onSaved;
  final VoidCallback onFinish;

  const WizardSyntheseStep({
    super.key,
    required this.formKey,
    required this.initialSynthese,
    required this.saving,
    required this.onSaved,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Synthèse', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Expanded(
              child: TextFormField(
                initialValue: initialSynthese,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: 'Synthèse de la session',
                  alignLabelWithHint: true,
                ),
                onSaved: onSaved,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: saving ? null : onFinish,
                icon: const Icon(Icons.check),
                label: saving ? const SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth:2)) : const Text('Terminer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Controller pour données d'une série dans le wizard
class SeriesStepController {
  int points;
  double groupSize;
  String? comment;
  int shotCount;
  double distance;
  HandMethod handMethod;
  String consigne;
  bool showErrors;

  SeriesStepController({
    required this.points,
    required this.groupSize,
    required this.comment,
    required this.shotCount,
    required this.distance,
    required this.handMethod,
    required this.consigne,
  }) : showErrors = false;

  Series build() => Series(
    points: points,
    groupSize: groupSize,
    comment: comment ?? '',
    shotCount: shotCount,
    distance: distance,
    handMethod: handMethod,
  );
}

/// Sélecteur de prise (une main / deux mains)
class HandMethodSelector extends StatefulWidget {
  final HandMethod initial;
  final ValueChanged<HandMethod> onChanged;
  const HandMethodSelector({super.key, required this.initial, required this.onChanged});
  @override
  State<HandMethodSelector> createState() => _HandMethodSelectorState();
}

class _HandMethodSelectorState extends State<HandMethodSelector> {
  late HandMethod _method;
  @override
  void initState() { super.initState(); _method = widget.initial; }
  void _set(HandMethod m){ setState(()=> _method = m); widget.onChanged(m); }
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Prise', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(width: 12),
        ToggleButtons(
          isSelected: [_method == HandMethod.oneHand, _method == HandMethod.twoHands],
          borderRadius: BorderRadius.circular(12),
          constraints: const BoxConstraints(minHeight: 34, minWidth: 46),
          onPressed: (i){ _set(i==0? HandMethod.oneHand : HandMethod.twoHands); },
          children: const [
            Padding(padding: EdgeInsets.symmetric(horizontal:8), child: Icon(Icons.front_hand, size:18)),
            Padding(padding: EdgeInsets.symmetric(horizontal:8), child: TwoHandsIconMini()),
          ],
        ),
      ],
    );
  }
}

/// Icône custom pour deux mains
class TwoHandsIconMini extends StatelessWidget {
  const TwoHandsIconMini({super.key});
  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Colors.white;
    return SizedBox(width: 30, height: 18, child: Stack(children:[
      Positioned(left: 0, top:0, child: Icon(Icons.front_hand, size:14, color: color.withValues(alpha:0.8))),
      Positioned(left: 12, top:0, child: Icon(Icons.front_hand, size:16, color: color)),
    ]));
  }
}
