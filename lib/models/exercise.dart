/// Basic exercise definition (no generated adapter yet; stored as Map in box initially).
class Exercise {
  final String id;
  final String name;
  final String category; // e.g. "précision", "vitesse", etc.
  final String? description;
  final int? durationMinutes; // estimated duration in minutes
  final String? equipment; // required equipment list / free text
  final DateTime createdAt;
  final int priority; // ordering / future grouping
  final List<String> goalIds; // Goals this exercise helps achieve

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    this.description,
  this.durationMinutes,
  this.equipment,
    required this.createdAt,
    this.priority = 9999,
    List<String>? goalIds,
  }) : goalIds = goalIds ?? const [];

  Exercise copyWith({
    String? name,
    String? category,
    String? description,
    DateTime? createdAt,
    int? priority,
    List<String>? goalIds,
    int? durationMinutes,
    String? equipment,
  }) => Exercise(
    id: id,
    name: name ?? this.name,
    category: category ?? this.category,
    description: description ?? this.description,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    equipment: equipment ?? this.equipment,
    createdAt: createdAt ?? this.createdAt,
    priority: priority ?? this.priority,
    goalIds: goalIds ?? this.goalIds,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'description': description,
  'durationMinutes': durationMinutes,
  'equipment': equipment,
    'createdAt': createdAt.toIso8601String(),
    'priority': priority,
    'goalIds': goalIds,
  };

  static Exercise fromMap(Map<String, dynamic> map) => Exercise(
    id: map['id'] as String,
    name: map['name'] as String,
    category: map['category'] as String,
    description: map['description'] as String?,
  durationMinutes: map['durationMinutes'] as int?,
  equipment: map['equipment'] as String?,
    createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    priority: (map['priority'] as int?) ?? 9999,
    goalIds: (map['goalIds'] is List) ? (map['goalIds'] as List).whereType<String>().toList() : const [],
  );
}