// AI生成 - 成就/勋章状态管理 + 里程碑自动检测
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/achievement.dart';
import '../models/task.dart';
import 'user_provider.dart';
import 'pomodoro_provider.dart';
import 'flashcard_provider.dart';
import 'task_provider.dart';
import 'habit_provider.dart';

final achievementProvider =
    StateNotifierProvider<AchievementNotifier, List<Achievement>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return AchievementNotifier(userId, ref);
});

class AchievementNotifier extends StateNotifier<List<Achievement>> {
  AchievementNotifier(this._userId, this._ref) : super([]) {
    _init();
  }

  final String _userId;
  final Ref _ref;
  late Box<Achievement> _box;

  /// 成就定义表
  static final _definitions = <Map<String, dynamic>>[
    // ─── 专注类 ───
    {'id': 'focus_first', 'title': '初次专注', 'desc': '完成第一次番茄钟', 'cat': 'focus', 'target': 1, 'icon': 'timer', 'color': 0xFF4A90D9},
    {'id': 'focus_10', 'title': '专注达人', 'desc': '累计完成10次番茄钟', 'cat': 'focus', 'target': 10, 'icon': 'timer', 'color': 0xFF4A90D9},
    {'id': 'focus_50', 'title': '专注大师', 'desc': '累计完成50次番茄钟', 'cat': 'focus', 'target': 50, 'icon': 'local_fire_department', 'color': 0xFFE74C3C},
    {'id': 'focus_100', 'title': '专注传奇', 'desc': '累计完成100次番茄钟', 'cat': 'focus', 'target': 100, 'icon': 'whatshot', 'color': 0xFFE74C3C},
    {'id': 'focus_1h', 'title': '一小时马拉松', 'desc': '单日专注超过60分钟', 'cat': 'focus', 'target': 60, 'icon': 'hourglass_full', 'color': 0xFF4A90D9},

    // ─── 闪卡类 ───
    {'id': 'card_first', 'title': '记忆起步', 'desc': '完成第一次闪卡复习', 'cat': 'flashcard', 'target': 1, 'icon': 'style', 'color': 0xFF27AE60},
    {'id': 'card_master_10', 'title': '小有成就', 'desc': '掌握10张闪卡', 'cat': 'flashcard', 'target': 10, 'icon': 'psychology', 'color': 0xFF27AE60},
    {'id': 'card_master_50', 'title': '记忆大师', 'desc': '掌握50张闪卡', 'cat': 'flashcard', 'target': 50, 'icon': 'psychology', 'color': 0xFF8E44AD},
    {'id': 'card_master_200', 'title': '过目不忘', 'desc': '掌握200张闪卡', 'cat': 'flashcard', 'target': 200, 'icon': 'emoji_events', 'color': 0xFFFFB300},

    // ─── 待办类 ───
    {'id': 'task_first', 'title': '行动派', 'desc': '完成第一个待办', 'cat': 'task', 'target': 1, 'icon': 'task_alt', 'color': 0xFF16A085},
    {'id': 'task_10', 'title': '效率先锋', 'desc': '累计完成10个待办', 'cat': 'task', 'target': 10, 'icon': 'task_alt', 'color': 0xFF16A085},
    {'id': 'task_50', 'title': '执行力爆表', 'desc': '累计完成50个待办', 'cat': 'task', 'target': 50, 'icon': 'verified', 'color': 0xFFF39C12},
    {'id': 'task_100', 'title': '任务终结者', 'desc': '累计完成100个待办', 'cat': 'task', 'target': 100, 'icon': 'military_tech', 'color': 0xFFE74C3C},

    // ─── 习惯类 ───
    {'id': 'habit_3', 'title': '坚持三天', 'desc': '习惯连续打卡3天', 'cat': 'habit', 'target': 3, 'icon': 'favorite', 'color': 0xFFE91E63},
    {'id': 'habit_7', 'title': '一周挑战', 'desc': '习惯连续打卡7天', 'cat': 'habit', 'target': 7, 'icon': 'favorite', 'color': 0xFFE91E63},
    {'id': 'habit_21', 'title': '习惯养成', 'desc': '习惯连续打卡21天', 'cat': 'habit', 'target': 21, 'icon': 'star', 'color': 0xFFFFB300},
    {'id': 'habit_100', 'title': '习惯大师', 'desc': '习惯连续打卡100天', 'cat': 'habit', 'target': 100, 'icon': 'diamond', 'color': 0xFF9C27B0},

    // ─── 综合类 ───
    {'id': 'all_rounder', 'title': '全能学霸', 'desc': '同一天使用专注、闪卡、待办、习惯四个模块', 'cat': 'general', 'target': 1, 'icon': 'school', 'color': 0xFFFFB300},
  ];

  Future<void> _init() async {
    _box = Hive.box<Achievement>('achievements');
    _ensureDefinitions();
    _loadAchievements();
  }

  void _ensureDefinitions() {
    for (final def in _definitions) {
      final key = '${_userId}_${def['id']}';
      if (!_box.containsKey(key)) {
        _box.put(
          key,
          Achievement(
            id: def['id'],
            title: def['title'],
            description: def['desc'],
            category: def['cat'],
            targetValue: def['target'],
            iconName: def['icon'],
            colorValue: def['color'],
          ),
        );
      }
    }
  }

  void _loadAchievements() {
    state = _box.values
        .where((a) => _definitions.any((d) => d['id'] == a.id))
        .toList()
      ..sort((a, b) {
        if (a.unlocked && !b.unlocked) return -1;
        if (!a.unlocked && b.unlocked) return 1;
        return b.progress.compareTo(a.progress);
      });
  }

  /// 检查所有成就进度（由外部调用，如 app 启动时或操作后）
  Future<void> checkAll() async {
    final pomodoros = _ref.read(pomodoroRecordProvider);
    final tasks = _ref.read(taskProvider);
    final habits = _ref.read(habitProvider);
    final decks = _ref.read(flashcardProvider);

    final completedPomodoros = pomodoros.where((r) => r.completed).length;
    final todayFocusMin = _ref.read(pomodoroRecordProvider.notifier).todayMinutes;
    final doneTasks = tasks.where((t) => t.status == TaskStatus.done).length;
    int maxStreak = 0;
    for (final h in habits) {
      if (h.currentStreak > maxStreak) maxStreak = h.currentStreak;
    }
    int totalMastered = 0;
    int totalReviewed = 0;
    for (final d in decks) {
      totalMastered += d.masteredCount;
      totalReviewed += d.cards.where((c) => c.reviewCount > 0).length;
    }

    // 更新各成就进度
    _update('focus_first', completedPomodoros);
    _update('focus_10', completedPomodoros);
    _update('focus_50', completedPomodoros);
    _update('focus_100', completedPomodoros);
    _update('focus_1h', todayFocusMin);

    _update('card_first', totalReviewed);
    _update('card_master_10', totalMastered);
    _update('card_master_50', totalMastered);
    _update('card_master_200', totalMastered);

    _update('task_first', doneTasks);
    _update('task_10', doneTasks);
    _update('task_50', doneTasks);
    _update('task_100', doneTasks);

    _update('habit_3', maxStreak);
    _update('habit_7', maxStreak);
    _update('habit_21', maxStreak);
    _update('habit_100', maxStreak);

    // 全能学霸：检查今日是否使用了4个模块
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final usedFocus = pomodoros.any((r) => r.startTime.isAfter(today));
    final usedTask = tasks.any((t) =>
        (t.completedAt != null && t.completedAt!.isAfter(today)) ||
        t.createdAt.isAfter(today));
    final usedHabit = habits.any((h) =>
        h.records.any((r) => DateTime(r.date.year, r.date.month, r.date.day) ==
            DateTime(today.year, today.month, today.day)));
    final usedFlashcard = decks.any((d) =>
        d.cards.any((c) => c.reviewCount > 0 && c.nextReviewDate != null &&
            c.nextReviewDate!.isAfter(today.subtract(const Duration(days: 1)))));
    final allRounder =
        usedFocus && usedTask && usedHabit && usedFlashcard ? 1 : 0;
    _update('all_rounder', allRounder);

    _loadAchievements();
  }

  void _update(String achievementId, int currentValue) {
    final key = '${_userId}_$achievementId';
    final a = _box.get(key);
    if (a == null) return;
    a.currentValue = currentValue;
    a.progress = (currentValue / a.targetValue).clamp(0.0, 1.0);
    if (!a.unlocked && currentValue >= a.targetValue) {
      a.unlocked = true;
      a.unlockedAt = DateTime.now();
    }
    a.save();
  }

  /// 获取新解锁的成就（用于弹窗通知）
  List<Achievement> get newlyUnlocked =>
      state.where((a) => a.unlocked && a.unlockedAt != null &&
          DateTime.now().difference(a.unlockedAt!).inSeconds < 5).toList();

  int get unlockedCount => state.where((a) => a.unlocked).length;
  int get totalCount => state.length;
}
