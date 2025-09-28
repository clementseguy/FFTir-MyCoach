enum HandMethod { oneHand, twoHands }

class Series {
  int? id;
  int shotCount;
  double distance;
  int points;
  double groupSize;
  String comment;
  HandMethod handMethod; // prise (1 main / 2 mains)

  Series({
    this.id,
    this.shotCount = 5,
    required this.distance,
    required this.points,
    required this.groupSize,
    this.comment = '',
    this.handMethod = HandMethod.twoHands,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shot_count': shotCount,
      'distance': distance,
      'points': points,
      'group_size': groupSize,
      'comment': comment,
      'hand_method': handMethod == HandMethod.oneHand ? 'one' : 'two',
    };
  }

  static Series fromMap(Map<String, dynamic> map) {
    final rawMethod = map['hand_method'];
    HandMethod method;
    if (rawMethod == 'one') {
      method = HandMethod.oneHand;
    } else if (rawMethod == 'two') {
      method = HandMethod.twoHands;
    } else {
      method = HandMethod.twoHands; // fallback, migration implicite
    }
    return Series(
      id: map['id'] as int?,
      shotCount: map['shot_count'] as int? ?? 5,
      distance: (map['distance'] as num?)?.toDouble() ?? 0,
      points: map['points'] as int? ?? 0,
      groupSize: (map['group_size'] as num?)?.toDouble() ?? 0,
      comment: map['comment'] as String? ?? '',
      handMethod: method,
    );
  }
}
