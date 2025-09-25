import 'package:flutter/material.dart';
import '../local_db_hive.dart';
import '../forms/series_form_data.dart';

class CreateSessionScreen extends StatefulWidget {
  final Map<String, dynamic>? initialSessionData;
  const CreateSessionScreen({super.key, this.initialSessionData});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editingSessionId != null ? 'Modifier la session' : 'Nouvelle session'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
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
              TextFormField(
                controller: _weaponController,
                decoration: InputDecoration(labelText: 'Arme'),
                validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _caliberController,
                decoration: InputDecoration(labelText: 'Calibre'),
                validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
              ),
              SizedBox(height: 16),
              Text('Séries', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._series.asMap().entries.map((entry) {
                int i = entry.key;
                SeriesFormData s = entry.value;
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Série ${i + 1}', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextFormField(
                          initialValue: s.shotCount.toString(),
                          decoration: InputDecoration(labelText: 'Nombre de coups'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => s.shotCount = int.tryParse(v) ?? 0,
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          initialValue: s.distance.toString(),
                          decoration: InputDecoration(labelText: 'Distance (m)'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => s.distance = double.tryParse(v) ?? 0,
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          initialValue: s.points.toString(),
                          decoration: InputDecoration(labelText: 'Points'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => s.points = int.tryParse(v) ?? 0,
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          initialValue: s.groupSize.toString(),
                          decoration: InputDecoration(labelText: 'Groupement (cm)'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => s.groupSize = double.tryParse(v) ?? 0,
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          initialValue: s.comment,
                          decoration: InputDecoration(labelText: 'Commentaire'),
                          onChanged: (v) => s.comment = v,
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
              ElevatedButton(
                onPressed: _saveSession,
                child: Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  final _formKey = GlobalKey<FormState>();
  DateTime? _date;
  String _status = 'réalisée';
  late TextEditingController _weaponController = TextEditingController();
  late TextEditingController _caliberController = TextEditingController(text: '22LR');
  late List<SeriesFormData> _series = [SeriesFormData(distance: 25)];
  int? _editingSessionId;

  @override
  void initState() {
    super.initState();
  _date = null;
    _weaponController = TextEditingController();
    _caliberController = TextEditingController();
    if (widget.initialSessionData != null) {
      final session = widget.initialSessionData!['session'];
      final seriesRaw = widget.initialSessionData!['series'];
      final List<dynamic> series = (seriesRaw is List) ? seriesRaw : [];
      _editingSessionId = session['id'] as int?
        ?? widget.initialSessionData!['id'] as int?;
      _date = session['date'] != null && session['date'] != '' ? DateTime.tryParse(session['date']) : null;
      _status = session['status'] ?? 'réalisée';
      _weaponController.text = session['weapon'] ?? '';
      _caliberController.text = session['caliber'] ?? '22LR';
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
    }
  }

  @override
  void dispose() {
    _weaponController.dispose();
    _caliberController.dispose();
    super.dispose();
  }

  void _addSeries() {
    setState(() {
      _series.add(SeriesFormData(distance: 25));
    });
  }

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) return;
    if (_series.isEmpty || _series.every((s) => s.shotCount == 0 && s.distance == 0 && s.points == 0 && s.groupSize == 0 && s.comment.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez ajouter au moins une série à la session.')),
      );
      return;
    }
    // Validation selon le statut
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
    final session = <String, dynamic>{
      'date': _date != null ? _date!.toIso8601String() : null,
      'weapon': _weaponController.text,
      'caliber': _caliberController.text,
      'status': _status,
    };
    if (_editingSessionId != null) {
      session['id'] = _editingSessionId;
    }
    final seriesList = _series.map((s) => {
      'shot_count': s.shotCount,
      'distance': s.distance,
      'points': s.points,
      'group_size': s.groupSize,
      'comment': s.comment,
    }).toList();
    try {
      if (_editingSessionId != null) {
        await LocalDatabaseHive().updateSession(session, seriesList);
        print('Session mise à jour: id=$_editingSessionId');
      } else {
        await LocalDatabaseHive().insertSession(session, seriesList);
        print('Session insérée: data=$session, séries=$seriesList');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session enregistrée')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur à l\'enregistrement')),
        );
      }
    }
  }
  // ... rest of the CreateSessionScreen UI ...
}
