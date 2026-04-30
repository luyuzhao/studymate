// AI生成 - 番茄钟记录状态管理，支持中断记录、每日目标
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/pomodoro_record.dart';
import 'user_provider.dart';

final pomodoroRecordProvider =
    StateNotifierProvider<PomodoroRecordNotifier, List<PomodoroRecord>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return PomodoroRecordNotifier(userId);
});

/// 每日专注目标（分钟数），存在 settings box
final dailyGoalProvider = StateNotifierProvider<DailyGoalNotifier, int>((ref) {
  return DailyGoalNotifier();
});

class DailyGoalNotifier extends StateNotifier<int> {
  DailyGoalNotifier() : super(60) {
    final settings = Hive.box('settings');
    state = settings.get('daily_focus_goal', defaultValue: 60) as int;
  }

  Future<void> setGoal(int minutes) async {
    state = minutes;
    await Hive.box('settings').put('daily_focus_goal', minutes);
  }
}

class PomodoroRecordNotifier extends StateNotifier<List<PomodoroRecord>> {
  PomodoroRecordNotifier(this._userId) : super([]) { _loadRecords(); }

  final String _userId;
  final _box = Hive.box<PomodoroRecord>('pomodoro_records');
  final _uuid = const Uuid();

  void _loadRecords() {
    state = _box.values.where((r) => r.userId == _userId).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  Future<void> addRecord({
    required int durationMinutes, required DateTime startTime, required DateTime endTime,
    String? courseId, String? taskId, bool completed = true,
    int interruptions = 0, String? focusNote,
  }) async {
    final record = PomodoroRecord(id: _uuid.v4(), durationMinutes: durationMinutes,
        startTime: startTime, endTime: endTime, courseId: courseId, taskId: taskId,
        completed: completed, userId: _userId,
        interruptions: interruptions, focusNote: focusNote);
    await _box.put(record.id, record);
    _loadRecords();
  }

  int get todayMinutes {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return state.where((r) => r.completed && r.startTime.isAfter(today))
        .fold(0, (sum, r) => sum + r.durationMinutes);
  }

  int get todaySessions {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return state.where((r) => r.completed && r.startTime.isAfter(today)).length;
  }

  int get todayInterruptions {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return state.where((r) => r.startTime.isAfter(today))
        .fold(0, (sum, r) => sum + r.interruptions);
  }

  int get weekMinutes {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return state.where((r) => r.completed && r.startTime.isAfter(start))
        .fold(0, (sum, r) => sum + r.durationMinutes);
  }

  Map<int, int> getWeeklyDistribution() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final map = <int, int>{for (int i = 1; i <= 7; i++) i: 0};
    for (final r in state) {
      if (r.completed && r.startTime.isAfter(start)) {
        map[r.startTime.weekday] = (map[r.startTime.weekday] ?? 0) + r.durationMinutes;
      }
    }
    return map;
  }
}
