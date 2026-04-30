// AI生成 - 成就/勋章数据模型
import 'package:hive/hive.dart';

part 'achievement.g.dart';

@HiveType(typeId: 20)
class Achievement extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  String iconName; // Material icon name mapping

  @HiveField(4)
  int colorValue;

  @HiveField(5)
  bool unlocked;

  @HiveField(6)
  DateTime? unlockedAt;

  @HiveField(7)
  double progress; // 0.0 ~ 1.0

  @HiveField(8)
  String category; // focus, flashcard, task, habit, general

  @HiveField(9)
  int targetValue; // 达成目标值

  @HiveField(10)
  int currentValue; // 当前值

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.iconName = 'emoji_events',
    this.colorValue = 0xFFFFB300,
    this.unlocked = false,
    this.unlockedAt,
    this.progress = 0,
    this.category = 'general',
    this.targetValue = 1,
    this.currentValue = 0,
  });
}
