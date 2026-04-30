// AI生成 - 课程列表页，展示所有课程和GPA概览
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/course_provider.dart';
import '../../models/course.dart';
import 'course_detail_page.dart';
import 'gpa_calculator_page.dart';

class CourseListPage extends ConsumerWidget {
  const CourseListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(courseProvider);
    final theme = Theme.of(context);
    final gpa = ref.read(courseProvider.notifier).calculateGPA();

    return Scaffold(
      appBar: AppBar(title: const Text('我的课程'), actions: [
        IconButton(icon: const Icon(Icons.calculate_outlined), tooltip: 'GPA 计算器',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GPACalculatorPage()))),
      ]),
      body: courses.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.school_outlined, size: 80, color: theme.colorScheme.primary.withOpacity(0.4)),
        const SizedBox(height: 16), Text('还没有课程', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8), Text('点击下方按钮添加你的第一门课程', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
      ])) : ListView(padding: const EdgeInsets.all(16), children: [
        if (courses.any((c) => c.score != null))
          Container(padding: const EdgeInsets.all(20), margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.tertiary]), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('当前 GPA', style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70)),
                Text(gpa.toStringAsFixed(2), style: theme.textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              ]),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text('${courses.length}', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('门课程', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
                ])),
            ])),
        ...courses.map((course) => _buildCourseCard(context, course)),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showAddCourseDialog(context, ref), icon: const Icon(Icons.add), label: const Text('添加课程')),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    final theme = Theme.of(context);
    final color = Color(course.colorValue);
    return Card(margin: const EdgeInsets.only(bottom: 12), child: InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailPage(courseId: course.id))),
      borderRadius: BorderRadius.circular(16),
      child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Container(width: 50, height: 50, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.school, color: color)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(course.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${course.teacher} · ${course.location}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          if (course.weekdays.isNotEmpty)
            Text('${_weekdaysShort(course.weekdays)} ${course.startTime}-${course.endTime} · ${course.credit}学分',
              style: theme.textTheme.bodySmall?.copyWith(color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w500))
          else if (course.credit > 0)
            Text('${course.credit}学分', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ])),
        if (course.score != null) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: _getScoreColor(course.score!).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Text(course.score!.toStringAsFixed(0), style: TextStyle(color: _getScoreColor(course.score!), fontWeight: FontWeight.bold))),
        const Icon(Icons.chevron_right),
      ])),
    ));
  }

  static const _wdLabels = {1: '一', 2: '二', 3: '三', 4: '四', 5: '五', 6: '六', 7: '日'};
  String _weekdaysShort(List<int> wd) => wd.map((d) => '周${_wdLabels[d]}').join('/');

  Color _getScoreColor(double s) { if (s >= 90) return Colors.green; if (s >= 80) return Colors.blue; if (s >= 70) return Colors.orange; if (s >= 60) return Colors.deepOrange; return Colors.red; }

  void _showAddCourseDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final teacherCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final creditCtrl = TextEditingController();
    final scoreCtrl = TextEditingController();
    int selectedColor = 0xFF4A90D9;
    final colors = [0xFF4A90D9, 0xFFE74C3C, 0xFF27AE60, 0xFFF39C12, 0xFF8E44AD, 0xFF16A085, 0xFFE67E22, 0xFF2C3E50];
    List<int> selectedWeekdays = [];
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 9, minute: 40);
    const weekdayLabels = {1: '一', 2: '二', 3: '三', 4: '四', 5: '五', 6: '六', 7: '日'};

    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        final sheetTheme = Theme.of(ctx);
        String fmtTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('添加课程', style: sheetTheme.textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '课程名称 *'), autofocus: true),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: teacherCtrl, decoration: const InputDecoration(labelText: '授课教师'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: '上课地点'))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: creditCtrl,
                  decoration: const InputDecoration(labelText: '学分'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: scoreCtrl,
                  decoration: const InputDecoration(labelText: '成绩(可选)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true))),
              ]),

              const SizedBox(height: 20),
              // ─── 上课时间段 ───
              Text('上课时间', style: sheetTheme.textTheme.labelLarge),
              const SizedBox(height: 8),
              // 星期多选
              Wrap(spacing: 6, children: [1, 2, 3, 4, 5, 6, 7].map((d) {
                final selected = selectedWeekdays.contains(d);
                return FilterChip(
                  label: Text('周${weekdayLabels[d]}'),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) { selectedWeekdays.add(d); selectedWeekdays.sort(); }
                    else { selectedWeekdays.remove(d); }
                  }),
                  showCheckmark: false,
                  selectedColor: Color(selectedColor).withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? Color(selectedColor) : null,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: selected
                          ? Color(selectedColor).withValues(alpha: 0.5)
                          : sheetTheme.dividerColor,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                );
              }).toList()),
              const SizedBox(height: 10),
              // 时间选择行
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text('开始 ${fmtTime(startTime)}'),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: ctx, initialTime: startTime,
                        builder: (c, child) => MediaQuery(
                          data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
                          child: child!),
                      );
                      if (picked != null) setState(() => startTime = picked);
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('—'),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text('结束 ${fmtTime(endTime)}'),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: ctx, initialTime: endTime,
                        builder: (c, child) => MediaQuery(
                          data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
                          child: child!),
                      );
                      if (picked != null) setState(() => endTime = picked);
                    },
                  ),
                ),
              ]),

              const SizedBox(height: 16),
              Text('选择颜色', style: sheetTheme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: colors.map((c) => GestureDetector(onTap: () => setState(() => selectedColor = c),
                child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle,
                  border: selectedColor == c ? Border.all(color: Colors.white, width: 3) : null,
                  boxShadow: selectedColor == c ? [BoxShadow(color: Color(c).withValues(alpha: 0.5), blurRadius: 8)] : null)))).toList()),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final score = scoreCtrl.text.trim().isEmpty
                    ? null : double.tryParse(scoreCtrl.text.trim());
                if (score != null && (score < 0 || score > 100)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('成绩需在 0~100 之间')));
                  return;
                }
                ref.read(courseProvider.notifier).addCourse(
                  name: nameCtrl.text.trim(),
                  teacher: teacherCtrl.text.trim(),
                  location: locationCtrl.text.trim(),
                  colorValue: selectedColor,
                  credit: double.tryParse(creditCtrl.text) ?? 0,
                  score: score,
                  weekdays: selectedWeekdays,
                  startTime: fmtTime(startTime),
                  endTime: fmtTime(endTime),
                );
                Navigator.pop(ctx);
              }, child: const Text('添加'))),
            ]),
          ),
        );
      }));
  }
}
