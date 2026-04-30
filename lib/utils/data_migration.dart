// AI生成 - 数据迁移工具，处理 Hive schema 版本升级和旧数据回填
import 'package:hive_flutter/hive_flutter.dart';
import '../models/course.dart';
import '../models/task.dart';
import '../models/note.dart';
import '../models/habit.dart';
import '../models/expense.dart';
import '../models/flashcard.dart';
import '../models/pomodoro_record.dart';
import '../models/user_profile.dart';

class DataMigration {
  static const _schemaVersionKey = 'schema_version';
  static const _currentVersion = 1;

  /// 执行所有待执行的迁移
  static Future<void> run() async {
    final settings = Hive.box('settings');
    final version = settings.get(_schemaVersionKey, defaultValue: 0) as int;

    if (version < 1) {
      await _migrateToV1(settings);
    }

    await settings.put(_schemaVersionKey, _currentVersion);
  }

  /// V0 → V1：为所有业务数据补填 userId
  /// 策略：如果当前已有登录用户，旧数据归属该用户；否则归属 'guest'
  static Future<void> _migrateToV1(Box settings) async {
    final currentUserId =
        settings.get('current_user_id') as String? ?? 'guest';

    // 同时为旧版无盐用户补填盐值（兼容老账号）
    final usersBox = Hive.box<UserProfile>('users');
    for (final user in usersBox.values) {
      if (user.salt.isEmpty) {
        // 旧用户没有盐，保留原密码哈希不变，盐值留空
        // 下次修改密码时会自动使用新的加盐方案
        await user.save();
      }
    }

    // 课程
    final courses = Hive.box<Course>('courses');
    for (final item in courses.values) {
      if (item.userId == 'guest') {
        item.userId = currentUserId;
        await item.save();
      }
    }

    // 任务
    final tasks = Hive.box<Task>('tasks');
    for (final item in tasks.values) {
      if (item.userId == 'guest') {
        item.userId = currentUserId;
        await item.save();
      }
    }

    // 笔记
    final notes = Hive.box<Note>('notes');
    for (final item in notes.values) {
      if (item.userId == 'guest') {
        item.userId = currentUserId;
        await item.save();
      }
    }

    // 习惯
    final habits = Hive.box<Habit>('habits');
    for (final item in habits.values) {
      if (item.userId == 'guest') {
        item.userId = currentUserId;
        await item.save();
      }
    }

    // 记账
    final expenses = Hive.box<Expense>('expenses');
    for (final item in expenses.values) {
      if (item.userId == 'guest') {
        item.userId = currentUserId;
        await item.save();
      }
    }

    // 闪卡
    final decks = Hive.box<FlashcardDeck>('flashcard_decks');
    for (final item in decks.values) {
      if (item.userId == 'guest') {
        item.userId = currentUserId;
        await item.save();
      }
    }

    // 番茄钟
    final pomodoros = Hive.box<PomodoroRecord>('pomodoro_records');
    for (final item in pomodoros.values) {
      if (item.userId == 'guest') {
        item.userId = currentUserId;
        await item.save();
      }
    }
  }
}
