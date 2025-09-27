// GENERATED MANUALLY FOR MVP (Normally via build_runner)
// ignore_for_file: type=lint

part of 'goal.dart';

class GoalMetricAdapter extends TypeAdapter<GoalMetric> {
  @override
  final int typeId = 40;
  @override
  GoalMetric read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GoalMetric.averagePoints;
      case 1:
        return GoalMetric.sessionCount;
      case 2:
        return GoalMetric.totalPoints;
      case 3:
        return GoalMetric.groupSize;
      default:
        return GoalMetric.averagePoints;
    }
  }

  @override
  void write(BinaryWriter writer, GoalMetric obj) {
    switch (obj) {
      case GoalMetric.averagePoints:
        writer.writeByte(0);
        break;
      case GoalMetric.sessionCount:
        writer.writeByte(1);
        break;
      case GoalMetric.totalPoints:
        writer.writeByte(2);
        break;
      case GoalMetric.groupSize:
        writer.writeByte(3);
        break;
    }
  }
}

class GoalComparatorAdapter extends TypeAdapter<GoalComparator> {
  @override
  final int typeId = 41;
  @override
  GoalComparator read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GoalComparator.greaterOrEqual;
      case 1:
        return GoalComparator.lessOrEqual;
      default:
        return GoalComparator.greaterOrEqual;
    }
  }

  @override
  void write(BinaryWriter writer, GoalComparator obj) {
    switch (obj) {
      case GoalComparator.greaterOrEqual:
        writer.writeByte(0);
        break;
      case GoalComparator.lessOrEqual:
        writer.writeByte(1);
        break;
    }
  }
}

class GoalStatusAdapter extends TypeAdapter<GoalStatus> {
  @override
  final int typeId = 42;
  @override
  GoalStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GoalStatus.active;
      case 1:
        return GoalStatus.achieved;
      case 2:
        return GoalStatus.failed;
      case 3:
        return GoalStatus.archived;
      default:
        return GoalStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, GoalStatus obj) {
    switch (obj) {
      case GoalStatus.active:
        writer.writeByte(0);
        break;
      case GoalStatus.achieved:
        writer.writeByte(1);
        break;
      case GoalStatus.failed:
        writer.writeByte(2);
        break;
      case GoalStatus.archived:
        writer.writeByte(3);
        break;
    }
  }
}

class GoalPeriodAdapter extends TypeAdapter<GoalPeriod> {
  @override
  final int typeId = 43;
  @override
  GoalPeriod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GoalPeriod.none;
      case 1:
        return GoalPeriod.rollingWeek;
      case 2:
        return GoalPeriod.rollingMonth;
      default:
        return GoalPeriod.none;
    }
  }

  @override
  void write(BinaryWriter writer, GoalPeriod obj) {
    switch (obj) {
      case GoalPeriod.none:
        writer.writeByte(0);
        break;
      case GoalPeriod.rollingWeek:
        writer.writeByte(1);
        break;
      case GoalPeriod.rollingMonth:
        writer.writeByte(2);
        break;
    }
  }
}

class GoalAdapter extends TypeAdapter<Goal> {
  @override
  final int typeId = 44;
  @override
  Goal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Goal(
      id: fields[0] as String?,
      title: fields[1] as String,
      description: fields[2] as String?,
      metric: fields[3] as GoalMetric,
      comparator: fields[4] as GoalComparator,
      targetValue: (fields[5] as num).toDouble(),
      status: fields[6] as GoalStatus,
      period: fields[7] as GoalPeriod,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
      lastProgress: (fields[10] as num?)?.toDouble(),
      lastMeasuredValue: (fields[11] as num?)?.toDouble(),
      // Backward compat: si champ absent (anciennes données), valeur par défaut élevée.
      priority: (fields[12] as num?)?.toInt() ?? 9999,
    );
  }

  @override
  void write(BinaryWriter writer, Goal obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.metric)
      ..writeByte(4)
      ..write(obj.comparator)
      ..writeByte(5)
      ..write(obj.targetValue)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.period)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.lastProgress)
      ..writeByte(11)
      ..write(obj.lastMeasuredValue)
      ..writeByte(12)
      ..write(obj.priority);
  }
}
