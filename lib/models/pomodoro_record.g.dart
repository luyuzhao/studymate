// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pomodoro_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PomodoroRecordAdapter extends TypeAdapter<PomodoroRecord> {
  @override
  final int typeId = 10;

  @override
  PomodoroRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PomodoroRecord(
      id: fields[0] as String,
      durationMinutes: fields[1] as int,
      startTime: fields[2] as DateTime,
      endTime: fields[3] as DateTime,
      courseId: fields[4] as String?,
      taskId: fields[5] as String?,
      completed: fields[6] as bool,
      userId: fields[7] as String,
      interruptions: fields[8] as int,
      focusNote: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PomodoroRecord obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.durationMinutes)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.courseId)
      ..writeByte(5)
      ..write(obj.taskId)
      ..writeByte(6)
      ..write(obj.completed)
      ..writeByte(7)
      ..write(obj.userId)
      ..writeByte(8)
      ..write(obj.interruptions)
      ..writeByte(9)
      ..write(obj.focusNote);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PomodoroRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
