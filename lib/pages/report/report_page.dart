// AI生成 - 学习报告/周报页：汇总专注、闪卡、待办、习惯数据 + 图表可视化
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/pomodoro_provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/habit_provider.dart';
import '../../models/task.dart';

class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key});
  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ─── 数据采集工具 ───
  DateTime _startOfWeek() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
  }

  DateTime _startOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学习报告'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [Tab(text: '本周'), Tab(text: '本月')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildReport(context, ref, _startOfWeek(), '本周'),
          _buildReport(context, ref, _startOfMonth(), '本月'),
        ],
      ),
    );
  }

  Widget _buildReport(
      BuildContext context, WidgetRef ref, DateTime since, String label) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // ─── 采集数据 ───
    final pomodoros = ref.watch(pomodoroRecordProvider);
    final tasks = ref.watch(taskProvider);
    final habits = ref.watch(habitProvider);
    final decks = ref.watch(flashcardProvider);

    // 专注统计
    final focusRecords =
        pomodoros.where((r) => r.completed && r.startTime.isAfter(since));
    final totalFocusMin =
        focusRecords.fold<int>(0, (s, r) => s + r.durationMinutes);
    final focusSessions = focusRecords.length;

    // 待办统计
    final completedTasks = tasks.where((t) =>
        t.status == TaskStatus.done &&
        t.completedAt != null &&
        t.completedAt!.isAfter(since));
    final totalTasks = tasks.where((t) => t.createdAt.isAfter(since)).length;
    final doneTasks = completedTasks.length;

    // 习惯统计
    int totalCheckins = 0;
    int maxStreak = 0;
    for (final h in habits) {
      totalCheckins +=
          h.records.where((r) => r.date.isAfter(since)).length;
      if (h.currentStreak > maxStreak) maxStreak = h.currentStreak;
    }

    // 闪卡统计
    int totalCards = 0;
    int masteredCards = 0;
    int dueCards = 0;
    for (final d in decks) {
      totalCards += d.totalCards;
      masteredCards += d.masteredCount;
      dueCards += d.dueCount;
    }
    final masteryPct =
        totalCards > 0 ? (masteredCards / totalCards * 100).round() : 0;

    // 每日专注分布（本周用）
    final dailyFocus = <int, int>{};
    for (final r in focusRecords) {
      final day = r.startTime.weekday;
      dailyFocus[day] = (dailyFocus[day] ?? 0) + r.durationMinutes;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 概览卡片 ───
          Text('$label概览',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: [
            _statCard(theme, '专注时长', '${totalFocusMin}分',
                Icons.timer_rounded, Colors.blue),
            const SizedBox(width: 10),
            _statCard(theme, '完成待办', '$doneTasks项',
                Icons.task_alt_rounded, Colors.green),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _statCard(theme, '习惯打卡', '$totalCheckins次',
                Icons.favorite_rounded, Colors.red),
            const SizedBox(width: 10),
            _statCard(theme, '闪卡掌握', '$masteryPct%',
                Icons.psychology_rounded, Colors.purple),
          ]),
          const SizedBox(height: 24),

          // ─── 专注时长柱状图 ───
          Text('每日专注时长',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (dailyFocus.values.isEmpty
                        ? 60
                        : dailyFocus.values
                            .reduce((a, b) => a > b ? a : b)
                            .toDouble()) *
                    1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                      '${rod.toY.round()}分',
                      TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['', '一', '二', '三', '四', '五', '六', '日'];
                        return Text(days[value.toInt()],
                            style: theme.textTheme.labelSmall);
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: List.generate(7, (i) {
                  final day = i + 1;
                  return BarChartGroupData(x: day, barRods: [
                    BarChartRodData(
                      toY: (dailyFocus[day] ?? 0).toDouble(),
                      color: cs.primary.withValues(alpha: 0.7),
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                    ),
                  ]);
                }),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ─── 闪卡掌握度饼图 ───
          if (totalCards > 0) ...[
            Text('闪卡掌握分布',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                        sections: [
                          _pieSection('新', decks.fold<int>(0, (s, d) => s + d.newCount).toDouble(),
                              Colors.blue),
                          _pieSection('学习', decks.fold<int>(0, (s, d) => s + d.learningCount).toDouble(),
                              Colors.orange),
                          _pieSection('复习', decks.fold<int>(0, (s, d) => s + d.reviewCount).toDouble(),
                              Colors.purple),
                          _pieSection('掌握', masteredCards.toDouble(),
                              Colors.green),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _legendItem('新卡', Colors.blue),
                      _legendItem('学习中', Colors.orange),
                      _legendItem('复习中', Colors.purple),
                      _legendItem('已掌握', Colors.green),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ─── 详细数据 ───
          Text('详细数据',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _detailRow(theme, '专注次数', '$focusSessions 次', Icons.timer),
          _detailRow(theme, '待办创建', '$totalTasks 项', Icons.add_task),
          _detailRow(theme, '待办完成', '$doneTasks 项', Icons.check_circle),
          _detailRow(
              theme,
              '完成率',
              totalTasks > 0
                  ? '${(doneTasks / totalTasks * 100).round()}%'
                  : '—',
              Icons.percent),
          _detailRow(theme, '最长连续打卡', '$maxStreak 天', Icons.local_fire_department),
          _detailRow(theme, '闪卡总数', '$totalCards 张', Icons.style),
          _detailRow(theme, '待复习', '$dueCards 张', Icons.replay),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _statCard(
      ThemeData theme, String title, String value, IconData icon, Color c) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withValues(alpha: 0.15)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: c, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text(value,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ]),
        ]),
      ),
    );
  }

  PieChartSectionData _pieSection(String title, double value, Color c) {
    return PieChartSectionData(
      value: value == 0 ? 0.01 : value,
      color: c,
      radius: 28,
      title: value > 0 ? '${value.round()}' : '',
      titleStyle: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
    );
  }

  Widget _legendItem(String label, Color c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Container(width: 12, height: 12,
            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }

  Widget _detailRow(ThemeData theme, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
