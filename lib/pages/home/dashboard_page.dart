// AI生成 - Dashboard 首页，大厂风格：渐变 Header + 精致数据卡片 + 入场动画
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../providers/task_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/pomodoro_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/task.dart';
import '../../theme/app_theme.dart';
import '../note/note_list_page.dart';
import '../habit/habit_page.dart';
import '../expense/expense_page.dart';
import '../flashcard/flashcard_list_page.dart';
import '../calendar/calendar_page.dart';
import '../report/report_page.dart';
import '../profile/achievement_page.dart';
import '../flashcard/ocr_import_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tasks = ref.watch(taskProvider);
    final habits = ref.watch(habitProvider);
    final courses = ref.watch(courseProvider);
    final user = ref.watch(userProvider);

    final todayTasks = ref.read(taskProvider.notifier).getTodayTasks();
    final overdueTasks = ref.read(taskProvider.notifier).getOverdueTasks();
    final completedToday = tasks.where((t) {
      if (t.completedAt == null) return false;
      final now = DateTime.now();
      return t.completedAt!.year == now.year && t.completedAt!.month == now.month && t.completedAt!.day == now.day;
    }).length;
    final todayMinutes = ref.read(pomodoroRecordProvider.notifier).todayMinutes;
    final todaySessions = ref.read(pomodoroRecordProvider.notifier).todaySessions;
    final pendingCount = tasks.where((t) => t.status != TaskStatus.done).length;
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final userName = user?.nickname ?? user?.displayName;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ─── 渐变 Hero Header ───
          _HeroHeader(
            greeting: greeting,
            userName: userName,
            dateStr: DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(now),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── 数据概览 ───
                Row(children: [
                  Expanded(child: _StatCard(
                    icon: Icons.timer_rounded,
                    label: '专注时长',
                    value: '$todayMinutes',
                    unit: '分钟',
                    subtitle: '$todaySessions 个番茄',
                    color: AppTheme.pomodoroColor,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(
                    icon: Icons.task_alt_rounded,
                    label: '任务进度',
                    value: '$completedToday',
                    unit: '完成',
                    subtitle: '$pendingCount 项待做',
                    color: AppTheme.taskColor,
                  )),
                ]).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 28),

                // ─── 快捷工具 ───
                _SectionTitle(title: '工具箱'),
                const SizedBox(height: 12),
                _buildToolGrid(context).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                const SizedBox(height: 28),

                // ─── 今日待办 ───
                if (todayTasks.isNotEmpty || overdueTasks.isNotEmpty) ...[
                  Row(children: [
                    _SectionTitle(title: '今日待办'),
                    const Spacer(),
                    if (overdueTasks.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${overdueTasks.length} 项过期',
                          style: theme.textTheme.labelSmall?.copyWith(color: cs.error, fontWeight: FontWeight.w600)),
                      ),
                  ]),
                  const SizedBox(height: 10),
                  ...todayTasks.take(5).toList().asMap().entries.map(
                    (e) => _buildTaskItem(context, ref, e.value)
                        .animate().fadeIn(duration: 300.ms, delay: (150 + e.key * 60).ms)
                        .slideX(begin: 0.03, end: 0),
                  ),
                  const SizedBox(height: 20),
                ],

                // ─── 今日习惯 ───
                if (habits.isNotEmpty) ...[
                  _SectionTitle(title: '今日习惯'),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: habits.map<Widget>((habit) {
                    final checked = ref.read(habitProvider.notifier).isCheckedToday(habit.id);
                    final hColor = Color(habit.colorValue);
                    return ActionChip(
                      avatar: Icon(
                        checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: checked ? hColor : cs.onSurface.withValues(alpha: 0.3), size: 18),
                      label: Text(habit.name, style: TextStyle(
                        fontWeight: checked ? FontWeight.w600 : FontWeight.w400,
                        color: checked ? hColor : null)),
                      backgroundColor: checked ? hColor.withValues(alpha: 0.1) : null,
                      side: checked ? BorderSide(color: hColor.withValues(alpha: 0.3)) : null,
                      onPressed: () { if (!checked) ref.read(habitProvider.notifier).checkIn(habit.id); },
                    );
                  }).toList()).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                  const SizedBox(height: 28),
                ],

                // ─── 我的课程 ───
                if (courses.isNotEmpty) ...[
                  _SectionTitle(title: '我的课程', trailing: '${courses.length}门'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: courses.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final c = courses[index];
                        final cColor = Color(c.colorValue);
                        return Container(
                          width: 170,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cColor.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(c.name, style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600, color: cColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Text('${c.teacher} · ${c.location}', style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('${c.startTime}-${c.endTime}', style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11)),
                            ],
                          ),
                        );
                      },
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 250.ms),
                ],

                // ─── 空状态 ───
                if (courses.isEmpty && tasks.isEmpty && habits.isEmpty)
                  _buildEmptyState(context).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95)),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 6) return '夜深了 🌙';
    if (hour < 12) return '早上好 ☀️';
    if (hour < 14) return '中午好 🌤️';
    if (hour < 18) return '下午好 ⛅';
    return '晚上好 🌆';
  }

  Widget _buildToolGrid(BuildContext context) {
    final tools = [
      _ToolItem(Icons.sticky_note_2_rounded, '笔记', AppTheme.noteColor,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoteListPage()))),
      _ToolItem(Icons.style_rounded, '闪卡', AppTheme.flashcardColor,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FlashcardListPage()))),
      _ToolItem(Icons.check_circle_rounded, '习惯', AppTheme.habitColor,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitPage()))),
      _ToolItem(Icons.account_balance_wallet_rounded, '记账', AppTheme.expenseColor,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensePage()))),
      _ToolItem(Icons.calendar_month_rounded, '日历', Colors.teal,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarPage()))),
      _ToolItem(Icons.bar_chart_rounded, '报告', Colors.indigo,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportPage()))),
      _ToolItem(Icons.emoji_events_rounded, '成就', Colors.amber,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementPage()))),
      _ToolItem(Icons.document_scanner_rounded, 'OCR', Colors.deepOrange,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OcrImportPage()))),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: tools.map((t) => InkWell(
        onTap: t.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: t.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.color.withValues(alpha: 0.12)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(t.icon, color: t.color, size: 24),
              const SizedBox(height: 6),
              Text(t.label, style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500, fontSize: 12)),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildTaskItem(BuildContext context, WidgetRef ref, Task task) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDone = task.status == TaskStatus.done;
    final priorityColor = task.priority == 2 ? AppTheme.pomodoroColor
        : task.priority == 1 ? AppTheme.taskColor : AppTheme.flashcardColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: theme.dividerColor),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              SizedBox(
                width: 22, height: 22,
                child: Checkbox(
                  value: isDone,
                  onChanged: (v) => ref.read(taskProvider.notifier)
                      .updateStatus(task.id, v == true ? TaskStatus.done : TaskStatus.todo),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: theme.textTheme.bodyMedium?.copyWith(
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? cs.onSurface.withValues(alpha: 0.4) : cs.onSurface,
                      fontWeight: FontWeight.w500)),
                    if (task.dueDate != null)
                      Text(DateFormat('M/d HH:mm').format(task.dueDate!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: task.isOverdue ? cs.error : cs.onSurface.withValues(alpha: 0.4),
                          fontSize: 11)),
                  ],
                ),
              ),
              Container(width: 6, height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: priorityColor)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.rocket_launch_rounded, size: 48, color: cs.primary),
          ),
          const SizedBox(height: 20),
          Text('欢迎使用 StudyMate Pro',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('从添加课程或创建待办开始你的学习之旅',
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
            textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── 渐变 Hero Header ───
class _HeroHeader extends StatelessWidget {
  final String greeting;
  final String? userName;
  final String dateStr;
  const _HeroHeader({required this.greeting, this.userName, required this.dateStr});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 24, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? [cs.primary.withValues(alpha: 0.06), cs.tertiary.withValues(alpha: 0.04), cs.surface]
              : [cs.primary.withValues(alpha: 0.15), cs.tertiary.withValues(alpha: 0.08), cs.surface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateStr, style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(greeting, style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700)),
              if (userName != null && userName!.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('$userName', style: theme.textTheme.titleLarge?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w400)),
                ),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.03, end: 0);
  }
}

// ─── 数据统计卡片 ───
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value, unit, subtitle;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value,
    required this.unit, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.labelMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.6))),
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700, color: cs.onSurface, height: 1)),
          const SizedBox(width: 3),
          Text(unit, style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
          color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11)),
      ]),
    );
  }
}

// ─── Section 标题 ───
class _SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  const _SectionTitle({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (trailing != null) {
      return Row(children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(width: 8),
        Text(trailing!, style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
      ]);
    }
    return Text(title, style: theme.textTheme.titleMedium);
  }
}

class _ToolItem {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  _ToolItem(this.icon, this.label, this.color, this.onTap);
}
