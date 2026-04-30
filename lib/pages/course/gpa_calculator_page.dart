// AI生成 - GPA 计算器页面
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../providers/course_provider.dart';

class GPACalculatorPage extends ConsumerWidget {
  const GPACalculatorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(courseProvider);
    final courseNotifier = ref.read(courseProvider.notifier);
    final gpa = courseNotifier.calculateGPA();
    final avgScore = courseNotifier.calculateAverageScore();
    final scoredCourses = courseNotifier.getScoredCoursesByCreatedAt();
    final theme = Theme.of(context);
    final totalCredits = courses.fold<double>(0, (s, c) => s + c.credit);

    return Scaffold(
      appBar: AppBar(title: const Text('GPA 计算器')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: CircularPercentIndicator(radius: 80, lineWidth: 12, percent: (gpa / 4.0).clamp(0.0, 1.0),
          center: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(gpa.toStringAsFixed(2), style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            Text('GPA', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ]),
          progressColor: theme.colorScheme.primary, backgroundColor: theme.colorScheme.surfaceContainerHighest, circularStrokeCap: CircularStrokeCap.round)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _stat(context, '总课程', '${courses.length}'), _stat(context, '已评分', '${courses.where((c) => c.score != null).length}'), _stat(context, '总学分', totalCredits.toStringAsFixed(1)),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _stat(context, '平均分', avgScore == 0 ? '-' : avgScore.toStringAsFixed(1)),
          _stat(context, '最高分', scoredCourses.isEmpty ? '-' : scoredCourses.map((c) => c.score!).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)),
          _stat(context, '最低分', scoredCourses.isEmpty ? '-' : scoredCourses.map((c) => c.score!).reduce((a, b) => a < b ? a : b).toStringAsFixed(0)),
        ]),
        const SizedBox(height: 24),
        Text('成绩趋势（按录入顺序）', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 220,
          padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: scoredCourses.length < 2
              ? Center(
                  child: Text(
                    '至少录入 2 门课程成绩后显示趋势',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 100,
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: 20,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          interval: 20,
                          getTitlesWidget: (value, _) => Text(
                            value.toInt().toString(),
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 28,
                          getTitlesWidget: (value, _) {
                            final i = value.toInt();
                            if (i < 0 || i >= scoredCourses.length) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              '${i + 1}',
                              style: theme.textTheme.labelSmall,
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          scoredCourses.length,
                          (i) => FlSpot(i.toDouble(), scoredCourses[i].score!),
                        ),
                        isCurved: true,
                        barWidth: 3,
                        color: theme.colorScheme.primary,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                            radius: 3.5,
                            color: theme.colorScheme.primary,
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: theme.colorScheme.primary.withOpacity(0.15),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 24),
        Text('成绩明细', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...courses.map((c) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
          leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: Color(c.colorValue).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(c.score?.toStringAsFixed(0) ?? '-', style: TextStyle(fontWeight: FontWeight.bold, color: Color(c.colorValue))))),
          title: Text(c.name), subtitle: Text('${c.credit} 学分'),
          trailing: Text(c.score != null ? courseNotifier.scoreToGpa(c.score!).toStringAsFixed(1) : '未评分', style: theme.textTheme.labelLarge)))),
      ]),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(children: [
      Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
      Text(label, style: theme.textTheme.bodySmall),
    ]);
  }

}
