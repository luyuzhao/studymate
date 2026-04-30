// AI生成 - 应用入口文件，初始化 Hive + SQLite 数据库
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'utils/data_migration.dart';
import 'utils/user_database.dart';
import 'providers/user_provider.dart';
import 'models/course.dart';
import 'models/task.dart';
import 'models/note.dart';
import 'models/habit.dart';
import 'models/expense.dart';
import 'models/flashcard.dart';
import 'models/pomodoro_record.dart';
import 'models/user_profile.dart';
import 'models/achievement.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日期格式化（中文locale）
  await initializeDateFormatting('zh_CN', null);

  // 初始化 Hive 本地数据库（业务数据）
  await Hive.initFlutter();

  // 注册 Hive 类型适配器 (每个模型对应一个 Adapter)
  Hive.registerAdapter(CourseAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(SubTaskAdapter());
  Hive.registerAdapter(TaskStatusAdapter());
  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(HabitAdapter());
  Hive.registerAdapter(HabitRecordAdapter());
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(ExpenseCategoryAdapter());
  Hive.registerAdapter(FlashcardDeckAdapter());
  Hive.registerAdapter(FlashcardAdapter());
  Hive.registerAdapter(PomodoroRecordAdapter());
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(AchievementAdapter());

  // 并行打开 Hive 盒子（业务数据）+ 初始化 SQLite（用户账户）
  await Future.wait([
    Hive.openBox<Course>('courses'),
    Hive.openBox<Task>('tasks'),
    Hive.openBox<Note>('notes'),
    Hive.openBox<Habit>('habits'),
    Hive.openBox<Expense>('expenses'),
    Hive.openBox<FlashcardDeck>('flashcard_decks'),
    Hive.openBox<PomodoroRecord>('pomodoro_records'),
    Hive.openBox('settings'),
    Hive.openBox<Achievement>('achievements'),
    Hive.openBox<UserProfile>('users'), // 保留，用于迁移旧数据
    UserDatabase.initialize(),          // SQLite 用户数据库
  ]);

  // Hive → SQLite 用户数据迁移（仅首次执行）
  await _migrateHiveUsersToSqlite();

  // 运行数据迁移（旧数据回填 userId 等）
  await DataMigration.run();

  // 从 SQLite 恢复登录会话（重启后自动登录）
  await UserNotifier.init();

  runApp(const ProviderScope(child: StudyMateApp()));
}

/// 将 Hive 中的旧用户数据一次性迁移到 SQLite
Future<void> _migrateHiveUsersToSqlite() async {
  final migrated = await UserDatabase.getSetting('hive_users_migrated');
  if (migrated == 'true') return; // 已迁移过

  final hiveUsersBox = Hive.box<UserProfile>('users');
  if (hiveUsersBox.isNotEmpty) {
    for (final user in hiveUsersBox.values) {
      final existing = await UserDatabase.getUserById(user.id);
      if (existing == null) {
        await UserDatabase.insertUser(user);
      }
    }
    // 同时迁移登录会话
    final settings = Hive.box('settings');
    final currentUserId = settings.get('current_user_id') as String?;
    if (currentUserId != null) {
      await UserDatabase.putSetting('current_user_id', currentUserId);
    }
  }

  await UserDatabase.putSetting('hive_users_migrated', 'true');
}
