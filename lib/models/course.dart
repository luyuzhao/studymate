// AI生成 - 课程数据模型
import 'package:hive/hive.dart';

part 'course.g.dart';

@HiveType(typeId: 0)
class Course extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String teacher;

  @HiveField(3)
  String location;

  @HiveField(4)
  int colorValue;

  @HiveField(5)
  double credit;

  @HiveField(6)
  double? score;

  @HiveField(7)
  String? iconName;

  @HiveField(8)
  List<int> weekdays;

  @HiveField(9)
  String startTime;

  @HiveField(10)
  String endTime;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  String userId;

  Course({
    required this.id,
    required this.name,
    this.teacher = '',
    this.location = '',
    this.colorValue = 0xFF4A90D9,
    this.credit = 0,
    this.score,
    this.iconName,
    this.weekdays = const [],
    this.startTime = '08:00',
    this.endTime = '09:40',
    DateTime? createdAt,
    this.userId = 'guest',
  }) : createdAt = createdAt ?? DateTime.now();
}
