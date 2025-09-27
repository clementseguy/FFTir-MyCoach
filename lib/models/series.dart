class Series {
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
}
