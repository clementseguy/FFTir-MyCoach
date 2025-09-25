// Modèle de données pour une session de tir
class ShootingSession {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'weapon': weapon,
      'caliber': caliber,
      'series': series.map((s) => s.toMap()).toList(),
    };
  }

  static ShootingSession fromMap(Map<String, dynamic> map) {
    return ShootingSession(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      weapon: map['weapon'] as String,
      caliber: map['caliber'] as String,
      series: (map['series'] as List<dynamic>).map((e) => Series.fromMap(Map<String, dynamic>.from(e))).toList(),
    );
  }
  int? id;
  DateTime date;
  String weapon;
  String caliber;
  List<Series> series;

  ShootingSession({
    this.id,
    required this.date,
    required this.weapon,
    required this.caliber,
    required this.series,
  });
}

// Modèle de données pour une série
class Series {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shot_count': shotCount,
      'distance': distance,
      'points': points,
      'group_size': groupSize,
      'comment': comment,
    };
  }

  static Series fromMap(Map<String, dynamic> map) {
    return Series(
      id: map['id'] as int?,
      shotCount: map['shot_count'] as int? ?? 5,
      distance: (map['distance'] as num?)?.toDouble() ?? 0,
      points: map['points'] as int? ?? 0,
      groupSize: (map['group_size'] as num?)?.toDouble() ?? 0,
      comment: map['comment'] as String? ?? '',
    );
  }
  int? id;
  int shotCount;
  double distance;
  int points;
  double groupSize;
  String comment;

  Series({
    this.id,
    this.shotCount = 5,
    required this.distance,
    required this.points,
    required this.groupSize,
    this.comment = '',
  });
}
