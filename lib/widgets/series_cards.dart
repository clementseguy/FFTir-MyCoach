import 'package:flutter/material.dart';
import '../forms/series_form_controllers.dart';
import '../models/series.dart';

/// Chip widget for a small labeled value
class ValueChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const ValueChip({super.key, required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.white60)),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

/// Display card for a persisted series
class SeriesDisplayCard extends StatelessWidget {
  final Series series;
  final int index;
  final bool highlightBestPoints;
  final bool highlightBestGroup;
  const SeriesDisplayCard({super.key, required this.series, required this.index, this.highlightBestPoints = false, this.highlightBestGroup = false});

  @override
  Widget build(BuildContext context) {
    final borderColor = highlightBestPoints ? Colors.amberAccent : highlightBestGroup ? Colors.tealAccent : Colors.white12;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor.withOpacity(0.55), width: highlightBestPoints || highlightBestGroup ? 1.2 : 0.6),
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.amberAccent.withOpacity(0.85),
                  child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                ),
                const SizedBox(width: 10),
                Text('Série ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                if (highlightBestPoints) _Badge(label: 'Meilleurs points', icon: Icons.star, color: Colors.amberAccent),
                if (highlightBestGroup) _Badge(label: 'Meilleur groupement', icon: Icons.bubble_chart, color: Colors.tealAccent),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ValueChip(icon: Icons.bolt, label: 'Coups', value: '${series.shotCount}', color: Colors.orangeAccent),
                ValueChip(icon: Icons.social_distance, label: 'Distance', value: '${series.distance.toStringAsFixed(0)}m', color: Colors.lightBlueAccent),
                ValueChip(icon: Icons.score, label: 'Points', value: '${series.points}', color: Colors.pinkAccent),
                ValueChip(icon: Icons.circle, label: 'Groupement', value: '${series.groupSize.toStringAsFixed(1)} cm', color: Colors.tealAccent),
              ],
            ),
            if (series.comment.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(series.comment.trim(), style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label; final IconData icon; final Color color;
  const _Badge({required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

/// Editable card used in the session form
class SeriesEditCard extends StatelessWidget {
  final int index;
  final SeriesFormControllers controllers;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback? onChanged;
  const SeriesEditCard({super.key, required this.index, required this.controllers, required this.canDelete, required this.onDelete, required this.onDuplicate, this.onChanged});

  @override
  Widget build(BuildContext context) {
    InputDecoration fieldDec(String label, {String? suffix}) => InputDecoration(
      labelText: label,
      suffixText: suffix,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );

    void notify() { if (onChanged != null) onChanged!(); }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.amberAccent.withOpacity(0.85),
                  child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                ),
                const SizedBox(width: 10),
                Text('Série ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(onPressed: onDuplicate, icon: const Icon(Icons.copy, size: 18), tooltip: 'Dupliquer'),
                if (canDelete) IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), tooltip: 'Supprimer'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _StepperField(
                  controller: controllers.shotCountController,
                  focusNode: controllers.shotCountFocus,
                  label: 'Coups',
                  min: 1,
                  max: 200,
                  step: 1,
                  width: 80,
                  onChanged: notify,
                )),
                const SizedBox(width: 8),
                Expanded(child: _StepperField(
                  controller: controllers.distanceController,
                  focusNode: controllers.distanceFocus,
                  label: 'Distance',
                  min: 1,
                  max: 300,
                  step: 1,
                  width: 90,
                  suffix: 'm',
                  decimal: false,
                  onChanged: notify,
                )),
                const SizedBox(width: 8),
                Expanded(child: _StepperField(
                  controller: controllers.pointsController,
                  focusNode: controllers.pointsFocus,
                  label: 'Points',
                  min: 0,
                  max: 4000,
                  step: 1,
                  width: 90,
                  onChanged: notify,
                )),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _StepperField(
                  controller: controllers.groupSizeController,
                  focusNode: controllers.groupSizeFocus,
                  label: 'Groupement',
                  min: 0,
                  max: 200,
                  step: 1,
                  width: 140,
                  suffix: 'cm',
                  decimal: false,
                  onChanged: notify,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: controllers.commentController,
                    focusNode: controllers.commentFocus,
                    decoration: fieldDec('Commentaire'),
                    minLines: 3,
                    maxLines: 6,
                    onChanged: (_) => notify(),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final double min;
  final double max;
  final double step;
  final double width;
  final String? suffix;
  final bool decimal;
  final VoidCallback onChanged;
  const _StepperField({required this.controller, required this.focusNode, required this.label, required this.min, required this.max, required this.step, required this.width, this.suffix, this.decimal = false, required this.onChanged});
  @override
  State<_StepperField> createState() => _StepperFieldState();
}

class _StepperFieldState extends State<_StepperField> {
  late double _value;
  @override
  void initState() {
    super.initState();
    _value = double.tryParse(widget.controller.text.replaceAll(',', '.')) ?? widget.min;
    widget.controller.text = widget.decimal ? _value.toStringAsFixed( widget.step < 1 ? 1 : 0) : _value.toStringAsFixed(0);
  }

  void _apply() {
    final str = widget.decimal ? _value.toStringAsFixed( widget.step < 1 ? 1 : 0) : _value.toStringAsFixed(0);
    if (widget.controller.text != str) {
      widget.controller.text = str;
    }
    widget.onChanged();
  }

  void _inc() { setState(() { _value = (_value + widget.step).clamp(widget.min, widget.max); }); _apply(); }
  void _dec() { setState(() { _value = (_value - widget.step).clamp(widget.min, widget.max); }); _apply(); }

  @override
  Widget build(BuildContext context) {
    final decoration = InputDecoration(
      labelText: widget.label,
      isDense: true,
      suffixText: widget.suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
    return SizedBox(
      width: widget.width,
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              decoration: decoration,
              keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
              onChanged: (t) {
                final parsed = double.tryParse(t.replaceAll(',', '.'));
                if (parsed != null) {
                  _value = parsed.clamp(widget.min, widget.max);
                }
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MiniIconBtn(icon: Icons.keyboard_arrow_up, onTap: _inc),
              _MiniIconBtn(icon: Icons.keyboard_arrow_down, onTap: _dec),
            ],
          )
        ],
      ),
    );
  }
}

class _MiniIconBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _MiniIconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 26,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}
