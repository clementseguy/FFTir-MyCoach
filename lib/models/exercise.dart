/// Exercise domain model (persisted as a Map in Hive box `exercises`).
/// Added in v0.3 (Lot 1): controlled enums category & type.
enum ExerciseCategory { precision, group, speed, technique, mental, physical }
enum ExerciseType { stand, home }

class Exercise {
  final String id;
  final String name;
  // Legacy field (string) kept for backward compatibility of older maps; we store canonically the enum.
  final ExerciseCategory categoryEnum;
  final ExerciseType type;
  final String? description;
  final int? durationMinutes; // estimated duration in minutes
  final String? equipment; // required equipment list / free text
  final DateTime createdAt;
  final int priority; // ordering / future grouping
  final List<String> goalIds; // Goals this exercise helps achieve
  final List<String> consignes; // Ordered detailed steps / instructions (0..n)

  Exercise({
    required this.id,
    required this.name,
    required this.categoryEnum,
    required this.type,
    this.description,
    this.durationMinutes,
    this.equipment,
    required this.createdAt,
    this.priority = 9999,
    List<String>? goalIds,
    List<String>? consignes,
  })  : goalIds = goalIds ?? const [],
        consignes = consignes ?? const [];

  Exercise copyWith({
    String? name,
    ExerciseCategory? category,
    ExerciseType? type,
    String? description,
    DateTime? createdAt,
    int? priority,
    List<String>? goalIds,
    int? durationMinutes,
    String? equipment,
    List<String>? consignes,
  }) => Exercise(
        id: id,
        name: name ?? this.name,
        categoryEnum: category ?? categoryEnum,
        type: type ?? this.type,
        description: description ?? this.description,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        equipment: equipment ?? this.equipment,
        createdAt: createdAt ?? this.createdAt,
        priority: priority ?? this.priority,
        goalIds: goalIds ?? this.goalIds,
        consignes: consignes ?? this.consignes,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        // Persist enum as string key (stable) for forward compatibility
        'category': categoryEnum.name,
        'type': type.name,
        'description': description,
        'durationMinutes': durationMinutes,
        'equipment': equipment,
        'createdAt': createdAt.toIso8601String(),
        'priority': priority,
        'goalIds': goalIds,
        'consignes': consignes,
      };

  static Exercise fromMap(Map<String, dynamic> map) {
    // Backward compatibility: old records had 'category' as arbitrary string and no 'type'.
    final rawCategory = (map['category'] as String?)?.toLowerCase().trim();
    ExerciseCategory cat = ExerciseCategory.precision;
    if (rawCategory != null) {
      cat = ExerciseCategory.values.firstWhere(
        (e) => e.name == rawCategory,
        orElse: () {
          // Simple mapping synonyms (legacy free-text) => enums
          switch (rawCategory) {
            case 'précision':
            case 'precision':
              return ExerciseCategory.precision;
            case 'groupement':
            case 'group':
              return ExerciseCategory.group;
            case 'vitesse':
            case 'speed':
              return ExerciseCategory.speed;
            case 'technique':
              return ExerciseCategory.technique;
            case 'mental':
              return ExerciseCategory.mental;
            case 'physique':
            case 'physical':
              return ExerciseCategory.physical;
            default:
              return ExerciseCategory.precision;
          }
        },
      );
    }
    final rawType = (map['type'] as String?)?.toLowerCase().trim();
    ExerciseType type = ExerciseType.stand; // default
    if (rawType != null) {
      type = ExerciseType.values.firstWhere(
        (e) => e.name == rawType,
        orElse: () => ExerciseType.stand,
      );
    }
    return Exercise(
      id: map['id'] as String,
      name: map['name'] as String,
      categoryEnum: cat,
      type: type,
      description: map['description'] as String?,
      durationMinutes: map['durationMinutes'] as int?,
      equipment: map['equipment'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      priority: (map['priority'] as int?) ?? 9999,
      goalIds: (map['goalIds'] is List) ? (map['goalIds'] as List).whereType<String>().toList() : const [],
      consignes: (map['consignes'] is List) ? (map['consignes'] as List).whereType<String>().toList() : const [],
    );
  }

  /// Localized label (fr) for display (keeps previous accent usage)
  String get categoryLabelFr {
    switch (categoryEnum) {
      case ExerciseCategory.precision: return 'Précision';
      case ExerciseCategory.group: return 'Groupement';
      case ExerciseCategory.speed: return 'Vitesse';
      case ExerciseCategory.technique: return 'Technique';
      case ExerciseCategory.mental: return 'Mental';
      case ExerciseCategory.physical: return 'Physique';
    }
  }

  /// Legacy string getter for backward compatibility (old code/tests referencing ex.category).
  String get category => categoryLabelFr.toLowerCase();
}

/// Parse helper to convert legacy string categories to enum.
ExerciseCategory parseExerciseCategory(String rawInput) {
  final raw = rawInput.toLowerCase().trim().replaceAll('é', 'e');
  switch (raw) {
    case 'precision': return ExerciseCategory.precision;
    case 'groupement':
    case 'group': return ExerciseCategory.group;
    case 'vitesse':
    case 'speed': return ExerciseCategory.speed;
    case 'technique': return ExerciseCategory.technique;
    case 'mental': return ExerciseCategory.mental;
    case 'physique':
    case 'physical': return ExerciseCategory.physical;
    default: return ExerciseCategory.precision;
  }
}