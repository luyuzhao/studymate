// AI生成 - 用户状态管理，使用 SQLite 持久化存储用户账户
// 支持：手机号注册、加盐SHA-256密码、登录失败限制、输入校验
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../utils/user_database.dart';

final userProvider =
    StateNotifierProvider<UserNotifier, UserProfile?>((ref) {
  return UserNotifier();
});

/// 当前用户ID（未登录返回 'guest'）——其他 Provider 依赖此值做数据隔离
final currentUserIdProvider = Provider<String>((ref) {
  final user = ref.watch(userProvider);
  return user?.id ?? 'guest';
});

/// 所有已注册用户列表（异步）
final allUsersProvider = FutureProvider<List<UserProfile>>((ref) async {
  ref.watch(userProvider); // 当用户变化时刷新
  return UserDatabase.getAllUsers();
});

class UserNotifier extends StateNotifier<UserProfile?> {
  UserNotifier() : super(_preloadedUser);

  static const _currentUserKey = 'current_user_id';

  /// 预加载的当前用户（在 main.dart 中提前初始化）
  static UserProfile? _preloadedUser;

  /// 在应用启动时调用，从 SQLite 恢复登录会话
  static Future<void> init() async {
    final userId = await UserDatabase.getSetting(_currentUserKey);
    if (userId != null) {
      _preloadedUser = await UserDatabase.getUserById(userId);
    }
  }

  // 内置头像列表
  static const List<String> avatarAssets = [
    '😀', '🧑‍🎓', '👩‍💻', '🧑‍🔬', '👨‍🏫', '🦊', '🐱', '🐶',
    '🌟', '🎯', '🚀', '📚', '🎨', '🎵', '🏆', '💡',
  ];

  /// 注册新用户（手机号作为账号）
  Future<String?> register(String phone, String password) async {
    final trimmedPhone = phone.trim();
    if (trimmedPhone.isEmpty) return '请输入手机号';
    if (!UserProfile.isValidPhone(trimmedPhone)) return '请输入正确的手机号（11位数字，1开头）';
    if (password.length < 6) return '密码至少6位';

    // 检查手机号是否已注册
    final existing = await UserDatabase.getUserByUsername(trimmedPhone);
    if (existing != null) return '该手机号已注册';

    final salt = UserProfile.generateSalt();
    final user = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: trimmedPhone,
      passwordHash: UserProfile.hashPassword(password, salt: salt),
      nickname: '用户${trimmedPhone.substring(7)}',
      salt: salt,
    );
    await UserDatabase.insertUser(user);
    await UserDatabase.putSetting(_currentUserKey, user.id);
    state = user;
    return null; // 成功
  }

  /// 登录（手机号 + 密码）
  Future<String?> login(String phone, String password) async {
    final trimmedPhone = phone.trim();
    if (trimmedPhone.isEmpty) return '请输入手机号';
    if (!UserProfile.isValidPhone(trimmedPhone)) return '账号为手机号，请输入正确的手机号';
    if (password.isEmpty) return '请输入密码';

    final user = await UserDatabase.getUserByUsername(trimmedPhone);
    if (user == null) return '该手机号未注册';

    // 登录锁定检查
    if (user.isLocked) {
      final remaining = 5 - DateTime.now().difference(user.lastAttemptTime!).inMinutes;
      return '登录失败次数过多，请${remaining}分钟后再试';
    }

    // 兼容旧版无盐密码和新版加盐密码
    bool passwordCorrect;
    if (user.salt.isEmpty) {
      passwordCorrect = user.passwordHash == UserProfile.hashPassword(password, salt: '');
    } else {
      passwordCorrect = user.checkPassword(password);
    }

    if (!passwordCorrect) {
      user.recordFailedAttempt();
      await UserDatabase.updateUser(user);
      final remaining = 5 - user.loginAttempts;
      if (remaining > 0) {
        return '密码错误，还可尝试$remaining次';
      } else {
        return '密码错误，账号已锁定5分钟';
      }
    }

    // 登录成功，重置失败计数
    user.resetLoginAttempts();
    await UserDatabase.updateUser(user);
    await UserDatabase.putSetting(_currentUserKey, user.id);
    state = user;
    return null; // 成功
  }

  /// 登出（清理会话状态）
  Future<void> logout() async {
    state = null;
    await UserDatabase.putSetting(_currentUserKey, null);
  }

  /// 更新昵称（带校验）
  Future<String?> updateNickname(String nickname) async {
    if (state == null) return '未登录';
    if (nickname.trim().isEmpty) return '昵称不能为空';
    if (!UserProfile.isValidNickname(nickname.trim())) return '昵称包含非法字符或超过20字';
    final updated = state!.copyWith(nickname: nickname.trim());
    await UserDatabase.updateUser(updated);
    state = updated;
    return null;
  }

  /// 更新个性签名
  Future<String?> updateBio(String bio) async {
    if (state == null) return '未登录';
    if (bio.length > 50) return '签名最多50字';
    final updated = state!.copyWith(bio: () => bio);
    await UserDatabase.updateUser(updated);
    state = updated;
    return null;
  }

  /// 更新头像索引（内置头像）
  Future<void> updateAvatarIndex(int index) async {
    if (state == null) return;
    final updated = state!.copyWith(avatarIndex: index, avatarPath: () => null);
    await UserDatabase.updateUser(updated);
    state = updated;
  }

  /// 更新自定义头像路径
  Future<void> updateAvatarPath(String path) async {
    if (state == null) return;
    final updated = state!.copyWith(avatarPath: () => path);
    await UserDatabase.updateUser(updated);
    state = updated;
  }

  /// 更新标签列表（带校验）
  Future<String?> updateTags(List<String> tags) async {
    if (state == null) return '未登录';
    if (!UserProfile.isValidTags(tags)) return '标签最多10个，每个最多10字';
    final updated = state!.copyWith(tags: tags);
    await UserDatabase.updateUser(updated);
    state = updated;
    return null;
  }

  /// 添加标签
  Future<String?> addTag(String tag) async {
    if (state == null) return '未登录';
    if (tag.trim().isEmpty) return '标签不能为空';
    if (tag.trim().length > 10) return '标签最多10个字符';
    if (state!.tags.length >= 10) return '最多添加10个标签';
    if (state!.tags.contains(tag.trim())) return '标签已存在';
    final updated = state!.copyWith(tags: [...state!.tags, tag.trim()]);
    await UserDatabase.updateUser(updated);
    state = updated;
    return null;
  }

  /// 删除标签
  Future<void> removeTag(String tag) async {
    if (state == null) return;
    final updated = state!.copyWith(tags: state!.tags.where((t) => t != tag).toList());
    await UserDatabase.updateUser(updated);
    state = updated;
  }

  bool get isLoggedIn => state != null;
}
