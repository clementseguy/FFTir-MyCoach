import '../forms/series_form_controllers.dart';
import 'package:flutter/material.dart';
import '../forms/series_form_data.dart';
import '../models/shooting_session.dart';
import '../constants/session_constants.dart';
import '../models/series.dart';

class SessionForm extends StatefulWidget {
  final Map<String, dynamic>? initialSessionData;
  final void Function(ShootingSession session) onSave;
  final bool isEdit;
  const SessionForm({Key? key, this.initialSessionData, required this.onSave, this.isEdit = false}) : super(key: key);

  @override
  State<SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends State<SessionForm> {
  late TextEditingController _syntheseController;
  final _formKey = GlobalKey<FormState>();
  DateTime? _date;
  String _status = SessionConstants.statusRealisee;
  late TextEditingController _weaponController;
  late TextEditingController _caliberController;
  late List<SeriesFormData> _series;
  late List<SeriesFormControllers> _seriesControllers;
  int? _editingSessionId;
  String _category = SessionConstants.categoryEntrainement;

  @override
  void initState() {
    super.initState();
    _weaponController = TextEditingController();
    _caliberController = TextEditingController();
    if (widget.initialSessionData != null) {
      final session = widget.initialSessionData!['session'];
      final seriesRaw = widget.initialSessionData!['series'];
      final List<dynamic> series = (seriesRaw is List) ? seriesRaw : [];
      _editingSessionId = session['id'] as int? ?? widget.initialSessionData!['id'] as int?;
      _date = session['date'] != null && session['date'] != '' ? DateTime.tryParse(session['date']) : null;
      _status = session['status'] ?? 'réalisée';
      _weaponController.text = session['weapon'] ?? '';
      _caliberController.text = session['caliber'] ?? '22LR';
  _syntheseController = TextEditingController(text: session['synthese'] ?? '');
  _category = session['category'] ?? SessionConstants.categoryEntrainement;
      _series = series.map((s) => SeriesFormData(
        shotCount: s['shot_count'] ?? 5,
        distance: (s['distance'] as num?)?.toDouble() ?? 25,
        points: s['points'] ?? 0,
        groupSize: (s['group_size'] as num?)?.toDouble() ?? 0,
        comment: s['comment'] ?? '',
      )).toList();
      if (_series.isEmpty) _series = [SeriesFormData(distance: 25)];
    } else {
      _caliberController.text = '22LR';
      _series = [SeriesFormData(distance: 25)];
      _status = 'réalisée';
      _date = null;
  _syntheseController = TextEditingController();
  _category = SessionConstants.categoryEntrainement;
    }
    _seriesControllers = _series.map((s) => SeriesFormControllers(
      shotCount: s.shotCount,
      distance: s.distance,
      points: s.points,
      groupSize: s.groupSize,
      comment: s.comment,
    )).toList();
  }

  @override
  void dispose() {
    for (final c in _seriesControllers) {
      c.dispose();
    }
    _weaponController.dispose();
    _caliberController.dispose();
    _syntheseController.dispose();
    super.dispose();
  }

  void _addSeries() {
    setState(() {
      _series.add(SeriesFormData(distance: 25));
      _seriesControllers.add(SeriesFormControllers(
        shotCount: 5,
        distance: 25,
        points: 0,
        groupSize: 0,
        comment: '',
      ));
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_series.isEmpty || _series.every((s) => s.shotCount == 0 && s.distance == 0 && s.points == 0 && s.groupSize == 0 && s.comment.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez ajouter au moins une série à la session.')),
      );
      return;
    }
    if (_status == 'réalisée') {
      if (_date == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('La date est obligatoire pour une session réalisée.')),
        );
        return;
      }
      if (_date!.isAfter(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('La date d\'une session réalisée ne peut pas être dans le futur.')),
        );
        return;
      }
    }
    final session = ShootingSession(
      id: _editingSessionId,
      date: _date,
      weapon: _weaponController.text,
      caliber: _caliberController.text,
      status: _status,
      series: List.generate(_series.length, (i) => Series(
        shotCount: int.tryParse(_seriesControllers[i].shotCountController.text) ?? 0,
        distance: double.tryParse(_seriesControllers[i].distanceController.text) ?? 0,
        points: int.tryParse(_seriesControllers[i].pointsController.text) ?? 0,
        groupSize: double.tryParse(_seriesControllers[i].groupSizeController.text) ?? 0,
        comment: _seriesControllers[i].commentController.text,
      )),
      synthese: _syntheseController.text,
    );
    widget.onSave(session);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('SessionForm mode: ${widget.isEdit ? 'édition' : 'création'}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      debugPrint('SessionForm context size: \\n  width: \\${size.width}, height: \\${size.height}');
    });
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        children: [
          ListTile(
            title: Text('Date'),
            subtitle: _date != null ? Text('${_date!.day}/${_date!.month}/${_date!.year}') : Text('Aucune date'),
            trailing: Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _weaponController,
            decoration: InputDecoration(labelText: 'Arme'),
            validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _caliberController,
            decoration: InputDecoration(labelText: 'Calibre'),
            validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _category,
            items: SessionConstants.categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? SessionConstants.categoryEntrainement),
            decoration: InputDecoration(labelText: 'Catégorie'),
          ),
          SizedBox(height: 24),
          Text('Séries', style: TextStyle(fontWeight: FontWeight.bold)),
          ..._series.asMap().entries.map((entry) {
            int i = entry.key;
            SeriesFormControllers c = _seriesControllers[i];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Série ${i + 1}', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextFormField(
                      controller: c.shotCountController,
                      decoration: InputDecoration(labelText: 'Nombre de coups'),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: c.distanceController,
                      decoration: InputDecoration(labelText: 'Distance (m)'),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: c.pointsController,
                      decoration: InputDecoration(labelText: 'Points'),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: c.groupSizeController,
                      decoration: InputDecoration(labelText: 'Groupement (cm)'),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: c.commentController,
                      decoration: InputDecoration(labelText: 'Commentaire'),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_series.length > 1)
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _series.removeAt(i);
                                _seriesControllers[i].dispose();
                                _seriesControllers.removeAt(i);
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: 8),
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('Ajouter une série'),
            onPressed: _addSeries,
          ),
          SizedBox(height: 24),
          TextFormField(
            controller: _syntheseController,
            decoration: InputDecoration(
              labelText: 'Synthèse',
              hintText: 'Récapitulatif de la session par le tireur',
              border: OutlineInputBorder(),
            ),
            minLines: 3,
            maxLines: 6,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            child: Text(widget.isEdit ? 'Enregistrer les modifications' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }
}
