// AI生成 - 用户资料模型，支持本地登录、昵称、头像、个人标签
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 11)
class UserProfile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String username;

  @HiveField(2)
  String passwordHash;

  @HiveField(3)
  String nickname;

  @HiveField(4)
  int avatarIndex; // 内置头像索引

  @HiveField(5)
  String? avatarPath; // 自定义头像路径

  @HiveField(6)
  List<String> tags;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  String? bio; // 个性签名

  @HiveField(9)
  String salt; // 密码盐值

  @HiveField(10)
  int loginAttempts; // 连续失败登录次数

  @HiveField(11)
  DateTime? lastAttemptTime; // 最后一次登录尝试时间

  UserProfile({
    required this.id,
    required this.username,
    required this.passwordHash,
    this.nickname = '',
    this.avatarIndex = 0,
    this.avatarPath,
    this.tags = const [],
    this.bio,
    DateTime? createdAt,
    this.salt = '',
    this.loginAttempts = 0,
    this.lastAttemptTime,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 生成随机盐值
  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// 加盐 SHA-256 哈希
  static String hashPassword(String password, {String salt = ''}) {
    final bytes = utf8.encode('$salt:$password');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool checkPassword(String password) {
    return passwordHash == hashPassword(password, salt: salt);
  }

  /// 检查是否被锁定（5次失败后锁定5分钟）
  bool get isLocked {
    if (loginAttempts < 5) return false;
    if (lastAttemptTime == null) return false;
    return DateTime.now().difference(lastAttemptTime!).inMinutes < 5;
  }

  /// 记录登录失败
  void recordFailedAttempt() {
    loginAttempts++;
    lastAttemptTime = DateTime.now();
  }

  /// 重置登录尝试计数
  void resetLoginAttempts() {
    loginAttempts = 0;
    lastAttemptTime = null;
  }

  /// 验证手机号格式（中国大陆1开头的11位数字）
  static bool isValidPhone(String phone) {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);
  }

  /// 昵称校验：1-20字符，不允许特殊字符
  static bool isValidNickname(String nickname) {
    if (nickname.isEmpty || nickname.length > 20) return false;
    return !RegExp(r'[<>"&\\]').hasMatch(nickname);
  }

  /// 标签校验：最多10个，每个最多10字符
  static bool isValidTags(List<String> tags) {
    if (tags.length > 10) return false;
    return tags.every((t) => t.length <= 10 && t.isNotEmpty);
  }

  String get displayName => nickname.isNotEmpty ? nickname : username;

  /// 复制并修改字段（用于 Riverpod 状态更新）
  UserProfile copyWith({
    String? id,
    String? username,
    String? passwordHash,
    String? nickname,
    int? avatarIndex,
    String? Function()? avatarPath,
    List<String>? tags,
    DateTime? createdAt,
    String? Function()? bio,
    String? salt,
    int? loginAttempts,
    DateTime? Function()? lastAttemptTime,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      nickname: nickname ?? this.nickname,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      avatarPath: avatarPath != null ? avatarPath() : this.avatarPath,
      tags: tags ?? List<String>.from(this.tags),
      createdAt: createdAt ?? this.createdAt,
      bio: bio != null ? bio() : this.bio,
      salt: salt ?? this.salt,
      loginAttempts: loginAttempts ?? this.loginAttempts,
      lastAttemptTime: lastAttemptTime != null ? lastAttemptTime() : this.lastAttemptTime,
    );
  }
}
