import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'goal.g.dart';

@HiveType(typeId: 40)
enum GoalMetric {
  @HiveField(0)
  averagePoints,
  @HiveField(1)
  sessionCount,
  @HiveField(2)
  totalPoints,
  @HiveField(3)
  groupSize,
  // Nouvelle métrique: moyenne des points par session (somme points séries / nb séries par session, moyennée sur les sessions filtrées)
  @HiveField(4)
  averageSessionPoints,
}

@HiveType(typeId: 41)
enum GoalComparator {
  @HiveField(0)
  greaterOrEqual,
  @HiveField(1)
  lessOrEqual,
}

@HiveType(typeId: 42)
enum GoalStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  achieved,
  @HiveField(2)
  failed,
  @HiveField(3)
  archived,
}

@HiveType(typeId: 43)
enum GoalPeriod {
  @HiveField(0)
  none,
  @HiveField(1)
  rollingWeek,
  @HiveField(2)
  rollingMonth,
}

@HiveType(typeId: 44)
class Goal extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  String? description;
  @HiveField(3)
  GoalMetric metric;
  @HiveField(4)
  GoalComparator comparator;
  @HiveField(5)
  double targetValue;
  @HiveField(6)
  GoalStatus status;
  @HiveField(7)
  GoalPeriod period;
  @HiveField(8)
  DateTime createdAt;
  @HiveField(9)
  DateTime updatedAt;
  @HiveField(10)
  double? lastProgress; // 0..1
  @HiveField(11)
  double? lastMeasuredValue;
  // Plus la valeur est petite, plus l'objectif est prioritaire (0 = top / plus haut dans la liste)
  @HiveField(12)
  int priority;

  Goal({
    String? id,
    required this.title,
    this.description,
    required this.metric,
    required this.comparator,
    required this.targetValue,
    this.status = GoalStatus.active,
    this.period = GoalPeriod.none,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastProgress,
    this.lastMeasuredValue,
  int? priority,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now(),
    // Assigner au champ avec this.priority (éviter auto-référence paramètre -> champ resté null)
    priority = priority ?? 9999; // valeur élevée par défaut si pas encore ordonné

  Goal copyWith({
    String? title,
    String? description,
    GoalMetric? metric,
    GoalComparator? comparator,
    double? targetValue,
    GoalStatus? status,
    GoalPeriod? period,
    double? lastProgress,
    double? lastMeasuredValue,
    int? priority,
  }) {
    return Goal(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      metric: metric ?? this.metric,
      comparator: comparator ?? this.comparator,
      targetValue: targetValue ?? this.targetValue,
      status: status ?? this.status,
      period: period ?? this.period,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastProgress: lastProgress ?? this.lastProgress,
      lastMeasuredValue: lastMeasuredValue ?? this.lastMeasuredValue,
      priority: priority ?? this.priority,
    );
  }
}
