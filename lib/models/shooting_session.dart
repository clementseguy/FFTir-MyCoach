import 'series.dart';

class ShootingSession {
  int? id;
  DateTime? date;
  String weapon;
  String caliber;
  List<Series> series;
  String status; // "prévue" ou "réalisée"
  String? analyse;
  String? synthese;

  ShootingSession({
    this.id,
    this.date,
    required this.weapon,
    required this.caliber,
    required this.series,
    this.status = 'réalisée',
    this.analyse,
    this.synthese,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date?.toIso8601String(),
      'weapon': weapon,
      'caliber': caliber,
      'series': series.map((s) => s.toMap()).toList(),
      'status': status,
      'analyse': analyse,
      'synthese': synthese,
    };
  }

  static ShootingSession fromMap(Map<String, dynamic> map) {
    final rawSeries = map['series'];
    final List<Series> seriesList =
        (rawSeries is List)
            ? rawSeries.map((e) => Series.fromMap(Map<String, dynamic>.from(e))).toList()
            : <Series>[];
    return ShootingSession(
      id: map['id'] as int?,
      date: map['date'] != null ? DateTime.tryParse(map['date']) : null,
      weapon: map['weapon'] as String,
      caliber: map['caliber'] as String,
      series: seriesList,
      status: map['status'] as String? ?? 'réalisée',
      analyse: map['analyse'] as String?,
      synthese: map['synthese'] as String?,
    );
  }
}
