// AI生成 - 任务/待办数据模型
import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  TaskStatus status;

  @HiveField(4)
  DateTime? dueDate;

  @HiveField(5)
  String? courseId;

  @HiveField(6)
  int priority; // 0: 低, 1: 中, 2: 高

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime? completedAt;

  @HiveField(9)
  List<String> tags;

  @HiveField(10)
  String userId;

  @HiveField(11)
  List<SubTask> subtasks; // 子任务清单

  @HiveField(12)
  int repeatType; // 0: 不重复, 1: 每天, 2: 每周

  @HiveField(13)
  int repeatInterval; // 重复间隔天数（repeatType>0时有效）

  @HiveField(14)
  String? parentId; // 由重复任务生成时，指向母任务id

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.status = TaskStatus.todo,
    this.dueDate,
    this.courseId,
    this.priority = 1,
    DateTime? createdAt,
    this.completedAt,
    this.tags = const [],
    this.userId = 'guest',
    this.subtasks = const [],
    this.repeatType = 0,
    this.repeatInterval = 1,
    this.parentId,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isOverdue =>
      dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      status != TaskStatus.done;

  bool get isRecurring => repeatType > 0;

  int get subtasksDone => subtasks.where((s) => s.done).length;
  double get subtaskProgress => subtasks.isEmpty ? 0 : subtasksDone / subtasks.length;
}

@HiveType(typeId: 12)
class SubTask {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool done;

  SubTask({required this.id, required this.title, this.done = false});
}

@HiveType(typeId: 2)
enum TaskStatus {
  @HiveField(0)
  todo,
  @HiveField(1)
  inProgress,
  @HiveField(2)
  done,
}
