// AI生成 - 成就/勋章展示页：分类展示 + 进度条 + 解锁动画
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/achievement_provider.dart';
import '../../models/achievement.dart';

class AchievementPage extends ConsumerStatefulWidget {
  const AchievementPage({super.key});
  @override
  ConsumerState<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends ConsumerState<AchievementPage> {
  @override
  void initState() {
    super.initState();
    // 进入页面时刷新成就进度
    Future.microtask(() => ref.read(achievementProvider.notifier).checkAll());
  }

  static const _categoryLabels = {
    'focus': '专注',
    'flashcard': '闪卡',
    'task': '待办',
    'habit': '习惯',
    'general': '综合',
  };

  static const _categoryIcons = {
    'focus': Icons.timer_rounded,
    'flashcard': Icons.style_rounded,
    'task': Icons.task_alt_rounded,
    'habit': Icons.favorite_rounded,
    'general': Icons.school_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final achievements = ref.watch(achievementProvider);
    final notifier = ref.read(achievementProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // 按分类分组
    final grouped = <String, List<Achievement>>{};
    for (final a in achievements) {
      (grouped[a.category] ??= []).add(a);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('成就勋章'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('${notifier.unlockedCount}/${notifier.totalCount}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.amber)),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: achievements.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: grouped.length,
              itemBuilder: (_, i) {
                final cat = grouped.keys.elementAt(i);
                final items = grouped[cat]!;
                final unlockedInCat = items.where((a) => a.unlocked).length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── 分类标题 ───
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        Icon(_categoryIcons[cat] ?? Icons.star,
                            size: 18, color: cs.primary),
                        const SizedBox(width: 6),
                        Text(
                          _categoryLabels[cat] ?? cat,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        Text('$unlockedInCat/${items.length}',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant)),
                      ]),
                    ),
                    // ─── 成就卡片 ───
                    ...items.asMap().entries.map((entry) =>
                        _achievementCard(theme, entry.value)
                            .animate()
                            .fadeIn(
                                duration: 300.ms,
                                delay: (entry.key * 60).ms)
                            .slideX(begin: 0.05, end: 0)),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
    );
  }

  Widget _achievementCard(ThemeData theme, Achievement a) {
    final color = Color(a.colorValue);
    final cs = theme.colorScheme;
    final isLocked = !a.unlocked;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isLocked ? null : color.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          // ─── 勋章图标 ───
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isLocked
                  ? cs.surfaceContainerHighest
                  : color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: a.unlocked
                  ? Border.all(color: color.withValues(alpha: 0.4), width: 2)
                  : null,
            ),
            child: Icon(
              _resolveIcon(a.iconName),
              color: isLocked
                  ? cs.onSurfaceVariant.withValues(alpha: 0.3)
                  : color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          // ─── 标题 + 进度 ───
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(a.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isLocked
                              ? cs.onSurfaceVariant.withValues(alpha: 0.5)
                              : null,
                        )),
                  ),
                  if (a.unlocked)
                    Icon(Icons.check_circle, color: color, size: 18),
                ]),
                const SizedBox(height: 2),
                Text(a.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(
                            alpha: isLocked ? 0.4 : 0.7))),
                const SizedBox(height: 6),
                // ─── 进度条 ───
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: a.progress,
                        minHeight: 5,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(
                            isLocked ? cs.onSurfaceVariant.withValues(alpha: 0.2) : color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${a.currentValue}/${a.targetValue}',
                      style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isLocked ? cs.onSurfaceVariant.withValues(alpha: 0.4) : color)),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  IconData _resolveIcon(String name) {
    const map = {
      'timer': Icons.timer_rounded,
      'local_fire_department': Icons.local_fire_department_rounded,
      'whatshot': Icons.whatshot_rounded,
      'hourglass_full': Icons.hourglass_full_rounded,
      'style': Icons.style_rounded,
      'psychology': Icons.psychology_rounded,
      'emoji_events': Icons.emoji_events_rounded,
      'task_alt': Icons.task_alt_rounded,
      'verified': Icons.verified_rounded,
      'military_tech': Icons.military_tech_rounded,
      'favorite': Icons.favorite_rounded,
      'star': Icons.star_rounded,
      'diamond': Icons.diamond_rounded,
      'school': Icons.school_rounded,
    };
    return map[name] ?? Icons.emoji_events_rounded;
  }
}
