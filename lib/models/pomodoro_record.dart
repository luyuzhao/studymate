// AI生成 - 番茄钟记录数据模型
import 'package:hive/hive.dart';

part 'pomodoro_record.g.dart';

@HiveType(typeId: 10)
class PomodoroRecord extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int durationMinutes;

  @HiveField(2)
  DateTime startTime;

  @HiveField(3)
  DateTime endTime;

  @HiveField(4)
  String? courseId;

  @HiveField(5)
  String? taskId;

  @HiveField(6)
  bool completed;

  @HiveField(7)
  String userId;

  @HiveField(8)
  int interruptions; // 中断次数

  @HiveField(9)
  String? focusNote; // 专注备注

  PomodoroRecord({
    required this.id,
    required this.durationMinutes,
    required this.startTime,
    required this.endTime,
    this.courseId,
    this.taskId,
    this.completed = true,
    this.userId = 'guest',
    this.interruptions = 0,
    this.focusNote,
  });
}
