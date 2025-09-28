/// Basic exercise definition (no generated adapter yet; stored as Map in box initially).
class Exercise {
  final String id;
  final String name;
  final String category; // e.g. "précision", "vitesse", etc.
  final String? description;
  final DateTime createdAt;
  final int priority; // ordering / future grouping

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    required this.createdAt,
    this.priority = 9999,
  });

  Exercise copyWith({
    String? name,
    String? category,
    String? description,
    DateTime? createdAt,
    int? priority,
  }) => Exercise(
    id: id,
    name: name ?? this.name,
    category: category ?? this.category,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
    priority: priority ?? this.priority,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'priority': priority,
  };

  static Exercise fromMap(Map<String, dynamic> map) => Exercise(
    id: map['id'] as String,
    name: map['name'] as String,
    category: map['category'] as String,
    description: map['description'] as String?,
    createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    priority: (map['priority'] as int?) ?? 9999,
  );
}