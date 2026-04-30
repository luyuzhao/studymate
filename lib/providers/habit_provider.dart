// AI生成 - 习惯打卡状态管理
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import 'user_provider.dart';

final habitProvider =
    StateNotifierProvider<HabitNotifier, List<Habit>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return HabitNotifier(userId);
});

class HabitNotifier extends StateNotifier<List<Habit>> {
  HabitNotifier(this._userId) : super([]) { _loadHabits(); }

  final String _userId;
  final _box = Hive.box<Habit>('habits');
  final _uuid = const Uuid();

  void _loadHabits() {
    state = _box.values.where((h) => h.userId == _userId).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> addHabit({
    required String name, String? icon, int colorValue = 0xFF16A085, int targetDays = 21,
  }) async {
    final habit = Habit(id: _uuid.v4(), name: name, icon: icon,
        colorValue: colorValue, targetDays: targetDays, userId: _userId);
    await _box.put(habit.id, habit);
    _loadHabits();
  }

  Future<void> checkIn(String habitId, {String? note}) async {
    final habit = _box.get(habitId);
    if (habit == null) return;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final alreadyChecked = habit.records.any((r) {
      final d = DateTime(r.date.year, r.date.month, r.date.day);
      return d == todayDate;
    });
    if (!alreadyChecked) {
      final records = List<HabitRecord>.from(habit.records);
      records.add(HabitRecord(date: today, note: note));
      habit.records = records;
      await habit.save();
      _loadHabits();
    }
  }

  Future<void> deleteHabit(String id) async { await _box.delete(id); _loadHabits(); }

  bool isCheckedToday(String habitId) {
    final habit = _box.get(habitId);
    if (habit == null) return false;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return habit.records.any((r) {
      final d = DateTime(r.date.year, r.date.month, r.date.day);
      return d == todayDate;
    });
  }
}
