// AI生成 - 用户账户 SQLite 持久化存储，确保重启后数据不丢失
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/user_profile.dart';

class UserDatabase {
  static Database? _db;

  /// 初始化 SQLite 数据库（应用启动时调用一次）
  static Future<void> initialize() async {
    if (_db != null) return;

    // 桌面平台需要 FFI 初始化
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final dbDir = Directory(join(appDir.path, 'studymate_db'));
    if (!await dbDir.exists()) await dbDir.create(recursive: true);
    final path = join(dbDir.path, 'studymate_users.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            username TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            nickname TEXT NOT NULL DEFAULT '',
            avatar_index INTEGER NOT NULL DEFAULT 0,
            avatar_path TEXT,
            tags TEXT NOT NULL DEFAULT '[]',
            created_at TEXT NOT NULL,
            bio TEXT,
            salt TEXT NOT NULL DEFAULT '',
            login_attempts INTEGER NOT NULL DEFAULT 0,
            last_attempt_time TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS app_settings (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
  }

  static Database get _database {
    assert(_db != null, 'UserDatabase.initialize() must be called first');
    return _db!;
  }

  // ─── User CRUD ───

  static Future<void> insertUser(UserProfile user) async {
    await _database.insert('users', _toMap(user),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateUser(UserProfile user) async {
    await _database.update('users', _toMap(user),
        where: 'id = ?', whereArgs: [user.id]);
  }

  static Future<UserProfile?> getUserById(String id) async {
    final rows =
        await _database.query('users', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : _fromMap(rows.first);
  }

  static Future<UserProfile?> getUserByUsername(String username) async {
    final rows = await _database
        .query('users', where: 'username = ?', whereArgs: [username]);
    return rows.isEmpty ? null : _fromMap(rows.first);
  }

  static Future<List<UserProfile>> getAllUsers() async {
    final rows = await _database.query('users');
    return rows.map(_fromMap).toList();
  }

  static Future<void> deleteUser(String id) async {
    await _database.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearUsers() async {
    await _database.delete('users');
  }

  // ─── Settings (登录会话等) ───

  static Future<void> putSetting(String key, String? value) async {
    if (value == null) {
      await _database
          .delete('app_settings', where: 'key = ?', whereArgs: [key]);
    } else {
      await _database.insert(
          'app_settings', {'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  static Future<String?> getSetting(String key) async {
    final rows = await _database
        .query('app_settings', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  // ─── Serialization helpers ───

  static Map<String, dynamic> _toMap(UserProfile u) => {
        'id': u.id,
        'username': u.username,
        'password_hash': u.passwordHash,
        'nickname': u.nickname,
        'avatar_index': u.avatarIndex,
        'avatar_path': u.avatarPath,
        'tags': jsonEncode(u.tags),
        'created_at': u.createdAt.toIso8601String(),
        'bio': u.bio,
        'salt': u.salt,
        'login_attempts': u.loginAttempts,
        'last_attempt_time': u.lastAttemptTime?.toIso8601String(),
      };

  static UserProfile _fromMap(Map<String, dynamic> m) => UserProfile(
        id: m['id'] as String,
        username: m['username'] as String,
        passwordHash: m['password_hash'] as String,
        nickname: (m['nickname'] as String?) ?? '',
        avatarIndex: (m['avatar_index'] as int?) ?? 0,
        avatarPath: m['avatar_path'] as String?,
        tags: _parseTags(m['tags']),
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? ''),
        bio: m['bio'] as String?,
        salt: (m['salt'] as String?) ?? '',
        loginAttempts: (m['login_attempts'] as int?) ?? 0,
        lastAttemptTime:
            DateTime.tryParse(m['last_attempt_time'] as String? ?? ''),
      );

  static List<String> _parseTags(dynamic raw) {
    if (raw == null || raw == '' || raw == '[]') return [];
    try {
      return (jsonDecode(raw as String) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }
}
