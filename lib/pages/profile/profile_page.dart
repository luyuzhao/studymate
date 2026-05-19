// AI生成 - 个人中心页，大厂风格：用户卡片 + 数据概览 + 分组设置
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../providers/theme_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/pomodoro_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/task.dart';
import '../../theme/app_theme.dart';
import '../../utils/backup_service.dart';
import 'login_page.dart';
import 'profile_edit_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(userProvider);
    final courses = ref.watch(courseProvider);
    final tasks = ref.watch(taskProvider);
    final notes = ref.watch(noteProvider);
    final habits = ref.watch(habitProvider);
    final decks = ref.watch(flashcardProvider);
    final pomodoros = ref.watch(pomodoroRecordProvider);

    final done = tasks.where((t) => t.status == TaskStatus.done).length;
    final totalCards = decks.fold<int>(0, (s, d) => s + d.totalCards);
    final totalMin = pomodoros.fold<int>(0, (s, r) => s + r.durationMinutes);
    final isLoggedIn = user != null;

    return Scaffold(
      appBar: AppBar(title: const Text('个人中心')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ─── 用户信息卡片 ───
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(children: [
              Row(children: [
                // 头像
                GestureDetector(
                  onTap: isLoggedIn ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditPage())) : null,
                  child: _buildAvatar(theme, user, isLoggedIn),
                ),
                const SizedBox(width: 16),
                // 信息
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isLoggedIn ? user.displayName : '游客模式',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  if (isLoggedIn)
                    Text(
                      user.username.length == 11
                          ? '${user.username.substring(0, 3)}****${user.username.substring(7)}'
                          : user.username,
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)))
                  else
                    Text('登录后数据将与账号绑定',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5))),
                  if (isLoggedIn && user.bio != null && user.bio!.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(top: 4),
                      child: Text(user.bio!, style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ])),
                // 箭头
                if (isLoggedIn)
                  IconButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditPage())),
                    icon: Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.3)),
                  ),
              ]),
              // 标签
              if (isLoggedIn && user.tags.isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 12),
                  child: Wrap(spacing: 6, runSpacing: 6, children: user.tags.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(t, style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.w500)),
                  )).toList())),
              // 按钮
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: isLoggedIn
                  ? Row(children: [
                      Expanded(child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditPage())),
                        icon: const Icon(Icons.edit_rounded, size: 16), label: const Text('编辑资料'))),
                      const SizedBox(width: 10),
                      Expanded(child: OutlinedButton.icon(
                        onPressed: () => _confirmLogout(context, ref),
                        icon: const Icon(Icons.logout_rounded, size: 16), label: const Text('退出登录'))),
                    ])
                  : SizedBox(width: double.infinity, child: FilledButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                      icon: const Icon(Icons.login_rounded, size: 18), label: const Text('登录 / 注册'))),
              ),
            ]),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.03, end: 0),

          const SizedBox(height: 24),

          // ─── 学习数据 ───
          Text('学习数据', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.3,
            children: [
              _DataTile(Icons.school_rounded, '课程', '${courses.length}', AppTheme.courseColor),
              _DataTile(Icons.task_alt_rounded, '已完成', '$done/${tasks.length}', AppTheme.taskColor),
              _DataTile(Icons.sticky_note_2_rounded, '笔记', '${notes.length}', AppTheme.noteColor),
              _DataTile(Icons.style_rounded, '闪卡', '$totalCards', AppTheme.flashcardColor),
              _DataTile(Icons.timer_rounded, '专注', '$totalMin分', AppTheme.pomodoroColor),
              _DataTile(Icons.check_circle_rounded, '习惯', '${habits.length}', AppTheme.habitColor),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

          const SizedBox(height: 24),

          // ─── 设置 ───
          Text('设置', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _SettingsGroup(children: [
            _SettingsItem(
              icon: Icons.palette_rounded,
              title: '外观主题',
              subtitle: themeMode == ThemeMode.system ? '跟随系统' : themeMode == ThemeMode.dark ? '深色模式' : '亮色模式',
              trailing: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded, size: 16)),
                  ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded, size: 16)),
                  ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded, size: 16)),
                ],
                selected: {themeMode},
                onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).setThemeMode(s.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ]).animate().fadeIn(duration: 400.ms, delay: 150.ms),

          const SizedBox(height: 12),

          _SettingsGroup(children: [
            _SettingsItem(
              icon: Icons.cloud_upload_rounded,
              title: '导出备份',
              subtitle: '复制 JSON 备份数据',
              onTap: () => _exportBackup(context),
            ),
            _SettingsItem(
              icon: Icons.cloud_download_rounded,
              title: '导入恢复',
              subtitle: '从 JSON 恢复全部数据',
              onTap: () => _importBackup(context, ref),
            ),
            _SettingsItem(
              icon: Icons.delete_outline_rounded,
              title: '清除所有数据',
              subtitle: '不可恢复，请谨慎操作',
              isDestructive: true,
              onTap: () => _clearData(context, ref),
            ),
          ]).animate().fadeIn(duration: 400.ms, delay: 200.ms),

          const SizedBox(height: 12),

          _SettingsGroup(children: [
            _SettingsItem(
              icon: Icons.info_outline_rounded,
              title: '关于 StudyMate Pro',
              subtitle: 'v1.0.0 · Flutter 3.x · Material 3',
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'StudyMate Pro',
                applicationVersion: 'v1.0.0',
                children: const [Text('全能学习效率伴侣\n集课程管理、任务待办、番茄专注、闪卡记忆、笔记系统、习惯打卡、智能记账于一体。')],
              ),
            ),
          ]).animate().fadeIn(duration: 400.ms, delay: 250.ms),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, dynamic user, bool isLoggedIn) {
    final cs = theme.colorScheme;
    if (isLoggedIn && user.avatarPath != null && user.avatarPath!.isNotEmpty && File(user.avatarPath!).existsSync()) {
      return CircleAvatar(radius: 32, backgroundImage: FileImage(File(user.avatarPath!)));
    }
    return CircleAvatar(
      radius: 32,
      backgroundColor: cs.primary.withValues(alpha: 0.1),
      child: isLoggedIn
          ? Text(UserNotifier.avatarAssets[user.avatarIndex], style: const TextStyle(fontSize: 28))
          : Icon(Icons.person_rounded, size: 32, color: cs.primary.withValues(alpha: 0.6)),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      icon: Icon(Icons.logout_rounded, size: 36, color: Theme.of(context).colorScheme.primary),
      title: const Text('退出登录'),
      content: const Text('退出后将进入游客模式，数据不会丢失，下次登录可恢复。'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () {
          ref.read(userProvider.notifier).logout();
          Navigator.pop(ctx);
        }, child: const Text('退出登录')),
      ]));
  }

  void _clearData(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error, size: 40),
      title: const Text('清除所有数据'),
      content: const Text('此操作将删除所有数据且不可恢复。确定继续吗？'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error), onPressed: () async {
          await Hive.box('courses').clear(); await Hive.box('tasks').clear(); await Hive.box('notes').clear();
          await Hive.box('habits').clear(); await Hive.box('expenses').clear(); await Hive.box('flashcard_decks').clear(); await Hive.box('pomodoro_records').clear();
          ref.invalidate(courseProvider); ref.invalidate(taskProvider); ref.invalidate(noteProvider);
          ref.invalidate(habitProvider); ref.invalidate(expenseProvider); ref.invalidate(flashcardProvider); ref.invalidate(pomodoroRecordProvider);
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('确定清除'))]));
  }

  Future<void> _exportBackup(BuildContext context) async {
    final backupJson = await BackupService.exportBackupJson();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导出备份'),
        content: SizedBox(
          width: 520,
          child: SelectableText(backupJson, maxLines: 16, style: Theme.of(context).textTheme.bodySmall),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: backupJson));
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('备份 JSON 已复制到剪贴板')));
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 16), label: const Text('复制'),
          ),
        ],
      ),
    );
  }

  void _importBackup(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入恢复'),
        content: SizedBox(
          width: 520,
          child: TextField(controller: ctrl, maxLines: 16,
            decoration: const InputDecoration(hintText: '请粘贴完整备份 JSON', alignLabelWithHint: true)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              try {
                await BackupService.importBackupJson(ctrl.text.trim());
                ref.invalidate(userProvider); ref.invalidate(courseProvider); ref.invalidate(taskProvider);
                ref.invalidate(noteProvider); ref.invalidate(habitProvider); ref.invalidate(expenseProvider);
                ref.invalidate(flashcardProvider); ref.invalidate(pomodoroRecordProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('恢复成功，数据已刷新')));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('恢复失败：$e')));
              }
            },
            child: const Text('开始恢复'),
          ),
        ],
      ),
    );
  }
}

// ─── 数据统计格子 ───
class _DataTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _DataTile(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700, color: cs.onSurface)),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.5), fontSize: 11)),
          ]),
        ],
      ),
    );
  }
}

// ─── 设置分组容器 ───
class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(children.length * 2 - 1, (i) {
          if (i.isOdd) return Divider(height: 1, indent: 52, color: theme.dividerColor);
          return children[i ~/ 2];
        }),
      ),
    );
  }
}

// ─── 设置项 ───
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;
  const _SettingsItem({
    required this.icon, required this.title, this.subtitle,
    this.trailing, this.onTap, this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final iconColor = isDestructive ? cs.error : cs.onSurface.withValues(alpha: 0.6);
    final titleColor = isDestructive ? cs.error : cs.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: titleColor, fontWeight: FontWeight.w500)),
            if (subtitle != null)
              Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.4), fontSize: 12)),
          ])),
          if (trailing != null) trailing!
          else if (onTap != null)
            Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurface.withValues(alpha: 0.25)),
        ]),
      ),
    );
  }
}
