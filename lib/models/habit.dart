// AI生成 - 习惯打卡数据模型
import 'package:hive/hive.dart';

part 'habit.g.dart';

@HiveType(typeId: 4)
class Habit extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? icon;

  @HiveField(3)
  int colorValue;

  @HiveField(4)
  List<HabitRecord> records;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  int targetDays;

  @HiveField(7)
  List<int> reminderWeekdays;

  @HiveField(8)
  String userId;

  Habit({
    required this.id,
    required this.name,
    this.icon,
    this.colorValue = 0xFF16A085,
    this.records = const [],
    DateTime? createdAt,
    this.targetDays = 21,
    this.reminderWeekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.userId = 'guest',
  }) : createdAt = createdAt ?? DateTime.now();

  int get currentStreak {
    if (records.isEmpty) return 0;
    final sorted = List<HabitRecord>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    DateTime checkDate = DateTime.now();
    for (final record in sorted) {
      final recordDate = DateTime(record.date.year, record.date.month, record.date.day);
      final check = DateTime(checkDate.year, checkDate.month, checkDate.day);
      if (recordDate == check || recordDate == check.subtract(const Duration(days: 1))) {
        streak++;
        checkDate = recordDate;
      } else {
        break;
      }
    }
    return streak;
  }

  int get totalCheckins => records.length;
}

@HiveType(typeId: 5)
class HabitRecord {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  String? note;

  HabitRecord({required this.date, this.note});
}
