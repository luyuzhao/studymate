import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/course.dart';
import 'user_database.dart';
import '../models/expense.dart';
import '../models/flashcard.dart';
import '../models/habit.dart';
import '../models/note.dart';
import '../models/pomodoro_record.dart';
import '../models/task.dart';
import '../models/user_profile.dart';

class BackupService {
  static const int backupVersion = 1;

  static Future<String> exportBackupJson() async {
    final data = {
      'version': backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': _exportSettings(),
      'users': await _exportUsers(),
      'courses': _exportCourses(),
      'tasks': _exportTasks(),
      'notes': _exportNotes(),
      'habits': _exportHabits(),
      'expenses': _exportExpenses(),
      'flashcardDecks': _exportFlashcardDecks(),
      'pomodoroRecords': _exportPomodoroRecords(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static Future<void> importBackupJson(String jsonText) async {
    final decoded = json.decode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('备份格式错误：根节点必须为对象');
    }

    final version = decoded['version'];
    if (version is! int) {
      throw const FormatException('备份格式错误：缺少 version');
    }

    await _restoreSettings(decoded['settings']);
    await _restoreUsers(decoded['users']);
    await _restoreCourses(decoded['courses']);
    await _restoreTasks(decoded['tasks']);
    await _restoreNotes(decoded['notes']);
    await _restoreHabits(decoded['habits']);
    await _restoreExpenses(decoded['expenses']);
    await _restoreFlashcardDecks(decoded['flashcardDecks']);
    await _restorePomodoroRecords(decoded['pomodoroRecords']);
  }

  static Map<String, dynamic> _exportSettings() {
    final settings = Hive.box('settings');
    return {
      'current_user_id': settings.get('current_user_id'),
      'schema_version': settings.get('schema_version'),
      'daily_focus_goal': settings.get('daily_focus_goal'),
    };
  }

  static Future<List<Map<String, dynamic>>> _exportUsers() async {
    final users = await UserDatabase.getAllUsers();
    return users
        .map(
          (u) => {
            'id': u.id,
            'username': u.username,
            'passwordHash': u.passwordHash,
            'nickname': u.nickname,
            'avatarIndex': u.avatarIndex,
            'avatarPath': u.avatarPath,
            'tags': u.tags,
            'createdAt': u.createdAt.toIso8601String(),
            'bio': u.bio,
            'salt': u.salt,
            'loginAttempts': u.loginAttempts,
            'lastAttemptTime': u.lastAttemptTime?.toIso8601String(),
          },
        )
        .toList();
  }

  static List<Map<String, dynamic>> _exportCourses() {
    final box = Hive.box<Course>('courses');
    return box.values
        .map(
          (c) => {
            'id': c.id,
            'name': c.name,
            'teacher': c.teacher,
            'location': c.location,
            'colorValue': c.colorValue,
            'credit': c.credit,
            'score': c.score,
            'iconName': c.iconName,
            'weekdays': c.weekdays,
            'startTime': c.startTime,
            'endTime': c.endTime,
            'createdAt': c.createdAt.toIso8601String(),
            'userId': c.userId,
          },
        )
        .toList();
  }

  static List<Map<String, dynamic>> _exportTasks() {
    final box = Hive.box<Task>('tasks');
    return box.values
        .map(
          (t) => {
            'id': t.id,
            'title': t.title,
            'description': t.description,
            'status': t.status.name,
            'dueDate': t.dueDate?.toIso8601String(),
            'courseId': t.courseId,
            'priority': t.priority,
            'createdAt': t.createdAt.toIso8601String(),
            'completedAt': t.completedAt?.toIso8601String(),
            'tags': t.tags,
            'userId': t.userId,
            'subtasks': t.subtasks.map((s) => {'id': s.id, 'title': s.title, 'done': s.done}).toList(),
            'repeatType': t.repeatType,
            'repeatInterval': t.repeatInterval,
            'parentId': t.parentId,
          },
        )
        .toList();
  }

  static List<Map<String, dynamic>> _exportNotes() {
    final box = Hive.box<Note>('notes');
    return box.values
        .map(
          (n) => {
            'id': n.id,
            'title': n.title,
            'content': n.content,
            'courseId': n.courseId,
            'tags': n.tags,
            'createdAt': n.createdAt.toIso8601String(),
            'updatedAt': n.updatedAt.toIso8601String(),
            'isPinned': n.isPinned,
            'userId': n.userId,
          },
        )
        .toList();
  }

  static List<Map<String, dynamic>> _exportHabits() {
    final box = Hive.box<Habit>('habits');
    return box.values
        .map(
          (h) => {
            'id': h.id,
            'name': h.name,
            'icon': h.icon,
            'colorValue': h.colorValue,
            'records': h.records
                .map(
                  (r) => {
                    'date': r.date.toIso8601String(),
                    'note': r.note,
                  },
                )
                .toList(),
            'createdAt': h.createdAt.toIso8601String(),
            'targetDays': h.targetDays,
            'reminderWeekdays': h.reminderWeekdays,
            'userId': h.userId,
          },
        )
        .toList();
  }

  static List<Map<String, dynamic>> _exportExpenses() {
    final box = Hive.box<Expense>('expenses');
    return box.values
        .map(
          (e) => {
            'id': e.id,
            'amount': e.amount,
            'category': e.category.name,
            'description': e.description,
            'date': e.date.toIso8601String(),
            'isIncome': e.isIncome,
            'userId': e.userId,
          },
        )
        .toList();
  }

  static List<Map<String, dynamic>> _exportFlashcardDecks() {
    final box = Hive.box<FlashcardDeck>('flashcard_decks');
    return box.values
        .map(
          (d) => {
            'id': d.id,
            'name': d.name,
            'courseId': d.courseId,
            'cards': d.cards
                .map(
                  (c) => {
                    'id': c.id,
                    'front': c.front,
                    'back': c.back,
                    'repetitionLevel': c.repetitionLevel,
                    'easeFactor': c.easeFactor,
                    'nextReviewDate': c.nextReviewDate?.toIso8601String(),
                    'reviewCount': c.reviewCount,
                  },
                )
                .toList(),
            'colorValue': d.colorValue,
            'createdAt': d.createdAt.toIso8601String(),
            'userId': d.userId,
          },
        )
        .toList();
  }

  static List<Map<String, dynamic>> _exportPomodoroRecords() {
    final box = Hive.box<PomodoroRecord>('pomodoro_records');
    return box.values
        .map(
          (r) => {
            'id': r.id,
            'durationMinutes': r.durationMinutes,
            'startTime': r.startTime.toIso8601String(),
            'endTime': r.endTime.toIso8601String(),
            'courseId': r.courseId,
            'taskId': r.taskId,
            'completed': r.completed,
            'userId': r.userId,
            'interruptions': r.interruptions,
            'focusNote': r.focusNote,
          },
        )
        .toList();
  }

  static Future<void> _restoreSettings(dynamic raw) async {
    final settings = Hive.box('settings');
    await settings.clear();
    if (raw is! Map) return;
    if (raw['current_user_id'] != null) {
      await settings.put('current_user_id', raw['current_user_id']);
    }
    if (raw['schema_version'] != null) {
      await settings.put('schema_version', raw['schema_version']);
    }
    if (raw['daily_focus_goal'] != null) {
      await settings.put('daily_focus_goal', raw['daily_focus_goal']);
    }
  }

  static Future<void> _restoreUsers(dynamic raw) async {
    await UserDatabase.clearUsers();
    if (raw is! List) return;
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final user = UserProfile(
        id: map['id'] as String,
        username: map['username'] as String,
        passwordHash: map['passwordHash'] as String,
        nickname: (map['nickname'] as String?) ?? '',
        avatarIndex: (map['avatarIndex'] as int?) ?? 0,
        avatarPath: map['avatarPath'] as String?,
        tags: ((map['tags'] as List?) ?? []).cast<String>(),
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
        bio: map['bio'] as String?,
        salt: (map['salt'] as String?) ?? '',
        loginAttempts: (map['loginAttempts'] as int?) ?? 0,
        lastAttemptTime:
            DateTime.tryParse(map['lastAttemptTime'] as String? ?? ''),
      );
      await UserDatabase.insertUser(user);
    }
  }

  static Future<void> _restoreCourses(dynamic raw) async {
    final box = Hive.box<Course>('courses');
    await box.clear();
    if (raw is! List) return;
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final course = Course(
        id: map['id'] as String,
        name: map['name'] as String,
        teacher: (map['teacher'] as String?) ?? '',
        location: (map['location'] as String?) ?? '',
        colorValue: (map['colorValue'] as int?) ?? 0xFF4A90D9,
        credit: (map['credit'] as num?)?.toDouble() ?? 0,
        score: (map['score'] as num?)?.toDouble(),
        iconName: map['iconName'] as String?,
        weekdays: ((map['weekdays'] as List?) ?? []).cast<int>(),
        startTime: (map['startTime'] as String?) ?? '08:00',
        endTime: (map['endTime'] as String?) ?? '09:40',
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
        userId: (map['userId'] as String?) ?? 'guest',
      );
      await box.put(course.id, course);
    }
  }

  static Future<void> _restoreTasks(dynamic raw) async {
    final box = Hive.box<Task>('tasks');
    await box.clear();
    if (raw is! List) return;
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final subtasksRaw = (map['subtasks'] as List?) ?? [];
      final subtasks = subtasksRaw.whereType<Map>().map((s) => SubTask(
        id: s['id'] as String? ?? '',
        title: s['title'] as String? ?? '',
        done: (s['done'] as bool?) ?? false,
      )).toList();
      final task = Task(
        id: map['id'] as String,
        title: map['title'] as String,
        description: (map['description'] as String?) ?? '',
        status: TaskStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => TaskStatus.todo,
        ),
        dueDate: DateTime.tryParse(map['dueDate'] as String? ?? ''),
        courseId: map['courseId'] as String?,
        priority: (map['priority'] as int?) ?? 1,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
        completedAt: DateTime.tryParse(map['completedAt'] as String? ?? ''),
        tags: ((map['tags'] as List?) ?? []).cast<String>(),
        userId: (map['userId'] as String?) ?? 'guest',
        subtasks: subtasks,
        repeatType: (map['repeatType'] as int?) ?? 0,
        repeatInterval: (map['repeatInterval'] as int?) ?? 1,
        parentId: map['parentId'] as String?,
      );
      await box.put(task.id, task);
    }
  }

  static Future<void> _restoreNotes(dynamic raw) async {
    final box = Hive.box<Note>('notes');
    await box.clear();
    if (raw is! List) return;
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final note = Note(
        id: map['id'] as String,
        title: map['title'] as String,
        content: (map['content'] as String?) ?? '',
        courseId: map['courseId'] as String?,
        tags: ((map['tags'] as List?) ?? []).cast<String>(),
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
        isPinned: (map['isPinned'] as bool?) ?? false,
        userId: (map['userId'] as String?) ?? 'guest',
      );
      await box.put(note.id, note);
    }
  }

  static Future<void> _restoreHabits(dynamic raw) async {
    final box = Hive.box<Habit>('habits');
    await box.clear();
    if (raw is! List) return;
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final recordsRaw = (map['records'] as List?) ?? const [];
      final records = recordsRaw
          .whereType<Map>()
          .map(
            (r) => HabitRecord(
              date: DateTime.tryParse(r['date'] as String? ?? '') ??
                  DateTime.now(),
              note: r['note'] as String?,
            ),
          )
          .toList();
      final habit = Habit(
        id: map['id'] as String,
        name: map['name'] as String,
        icon: map['icon'] as String?,
        colorValue: (map['colorValue'] as int?) ?? 0xFF16A085,
        records: records,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
        targetDays: (map['targetDays'] as int?) ?? 21,
        reminderWeekdays:
            ((map['reminderWeekdays'] as List?) ?? [1, 2, 3, 4, 5, 6, 7])
                .cast<int>(),
        userId: (map['userId'] as String?) ?? 'guest',
      );
      await box.put(habit.id, habit);
    }
  }

  static Future<void> _restoreExpenses(dynamic raw) async {
    final box = Hive.box<Expense>('expenses');
    await box.clear();
    if (raw is! List) return;
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final categoryName = (map['category'] as String?) ?? 'other';
      final expense = Expense(
        id: map['id'] as String,
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        category: ExpenseCategory.values.firstWhere(
          (c) => c.name == categoryName,
          orElse: () => ExpenseCategory.other,
        ),
        description: (map['description'] as String?) ?? '',
        date: DateTime.tryParse(map['date'] as String? ?? ''),
        isIncome: (map['isIncome'] as bool?) ?? false,
        userId: (map['userId'] as String?) ?? 'guest',
      );
      await box.put(expense.id, expense);
    }
  }

  static Future<void> _restoreFlashcardDecks(dynamic raw) async {
    final box = Hive.box<FlashcardDeck>('flashcard_decks');
    await box.clear();
    if (raw is! List) return;
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final cardsRaw = (map['cards'] as List?) ?? const [];
      final cards = cardsRaw
          .whereType<Map>()
          .map(
            (c) => Flashcard(
              id: c['id'] as String,
              front: c['front'] as String,
              back: c['back'] as String,
              repetitionLevel: (c['repetitionLevel'] as int?) ?? 0,
              easeFactor: (c['easeFactor'] as num?)?.toDouble() ?? 2.5,
              nextReviewDate:
                  DateTime.tryParse(c['nextReviewDate'] as String? ?? ''),
              reviewCount: (c['reviewCount'] as int?) ?? 0,
            ),
          )
          .toList();
      final deck = FlashcardDeck(
        id: map['id'] as String,
        name: map['name'] as String,
        courseId: map['courseId'] as String?,
        cards: cards,
        colorValue: (map['colorValue'] as int?) ?? 0xFF27AE60,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
        userId: (map['userId'] as String?) ?? 'guest',
      );
      await box.put(deck.id, deck);
    }
  }

  static Future<void> _restorePomodoroRecords(dynamic raw) async {
    final box = Hive.box<PomodoroRecord>('pomodoro_records');
    await box.clear();
    if (raw is! List) return;
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final record = PomodoroRecord(
        id: map['id'] as String,
        durationMinutes: (map['durationMinutes'] as int?) ?? 25,
        startTime:
            DateTime.tryParse(map['startTime'] as String? ?? '') ??
                DateTime.now(),
        endTime:
            DateTime.tryParse(map['endTime'] as String? ?? '') ??
                DateTime.now(),
        courseId: map['courseId'] as String?,
        taskId: map['taskId'] as String?,
        completed: (map['completed'] as bool?) ?? true,
        userId: (map['userId'] as String?) ?? 'guest',
        interruptions: (map['interruptions'] as int?) ?? 0,
        focusNote: map['focusNote'] as String?,
      );
      await box.put(record.id, record);
    }
  }
}
