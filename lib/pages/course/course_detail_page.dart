// AI生成 - 课程详情页，展示课程信息、关联任务与笔记、编辑上课时间
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/course_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/note_provider.dart';
import '../../models/course.dart';
import '../../models/task.dart';

class CourseDetailPage extends ConsumerWidget {
  final String courseId;
  const CourseDetailPage({super.key, required this.courseId});

  static const _weekdayLabels = {1: '一', 2: '二', 3: '三', 4: '四', 5: '五', 6: '六', 7: '日'};

  String _weekdaysStr(List<int> wd) {
    if (wd.isEmpty) return '未设置';
    return wd.map((d) => '周${_weekdayLabels[d]}').join('、');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(courseProvider);
    final course = courses.where((c) => c.id == courseId).firstOrNull;
    if (course == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('课程不存在')));

    final theme = Theme.of(context);
    final color = Color(course.colorValue);
    final tasks = ref.read(taskProvider.notifier).getTasksByCourse(courseId);
    final notes = ref.read(noteProvider.notifier).getNotesByCourse(courseId);

    return Scaffold(
      appBar: AppBar(title: Text(course.name), actions: [
        IconButton(icon: const Icon(Icons.edit_outlined),
          onPressed: () => _showEditScoreDialog(context, ref, courseId, course.score)),
        IconButton(icon: const Icon(Icons.delete_outline), onPressed: () {
          showDialog(context: context, builder: (ctx) => AlertDialog(
            title: const Text('删除课程'),
            content: Text('确定要删除 "${course.name}" 吗？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
              FilledButton(onPressed: () {
                ref.read(courseProvider.notifier).deleteCourse(courseId);
                Navigator.pop(ctx); Navigator.pop(context);
              }, child: const Text('删除')),
            ]));
        }),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // ─── 课程信息卡 ───
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.8), color],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.school, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Text(course.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 16),
            _info(Icons.person, '教师: ${course.teacher.isEmpty ? "未设置" : course.teacher}'),
            _info(Icons.location_on, '地点: ${course.location.isEmpty ? "未设置" : course.location}'),
            _info(Icons.calendar_today, '上课日: ${_weekdaysStr(course.weekdays)}'),
            _info(Icons.access_time, '时间: ${course.startTime} - ${course.endTime}'),
            _info(Icons.star, '学分: ${course.credit}'),
            if (course.score != null)
              _info(Icons.grade, '成绩: ${course.score!.toStringAsFixed(1)}'),
            const SizedBox(height: 10),
            // ─── 操作按钮行 ───
            Wrap(spacing: 8, children: [
              FilledButton.tonalIcon(
                onPressed: () => _showEditScheduleDialog(context, ref, course),
                icon: const Icon(Icons.schedule, size: 18),
                label: const Text('编辑时间'),
                style: FilledButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.2)),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _showEditScoreDialog(context, ref, courseId, course.score),
                icon: const Icon(Icons.score_outlined, size: 18),
                label: Text(course.score == null ? '录入成绩' : '修改成绩'),
                style: FilledButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.2)),
              ),
            ]),
          ])),

        const SizedBox(height: 24),
        Text('相关任务 (${tasks.length})',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          Card(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: Text('暂无关联任务',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant)))))
        else
          ...tasks.map((t) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                t.status == TaskStatus.done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: t.status == TaskStatus.done ? Colors.green : null),
              title: Text(t.title),
              subtitle: Text(t.status.name)))),
        const SizedBox(height: 20),
        Text('课程笔记 (${notes.length})',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (notes.isEmpty)
          Card(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: Text('暂无课程笔记',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant)))))
        else
          ...notes.map((n) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.note),
              title: Text(n.title),
              subtitle: Text(n.content, maxLines: 2, overflow: TextOverflow.ellipsis)))),
      ]),
    );
  }

  Widget _info(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(icon, color: Colors.white70, size: 18),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(color: Colors.white)),
    ]));

  // ─── 编辑上课时间弹窗 ───
  void _showEditScheduleDialog(BuildContext context, WidgetRef ref, Course course) {
    List<int> weekdays = List<int>.from(course.weekdays);
    TimeOfDay startTime = _parseTime(course.startTime);
    TimeOfDay endTime = _parseTime(course.endTime);

    String fmtTime(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        final sheetTheme = Theme.of(ctx);
        final courseColor = Color(course.colorValue);
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('编辑上课时间', style: sheetTheme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(course.name,
              style: sheetTheme.textTheme.bodyMedium?.copyWith(
                color: sheetTheme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            Text('上课日', style: sheetTheme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: [1, 2, 3, 4, 5, 6, 7].map((d) {
              final selected = weekdays.contains(d);
              return FilterChip(
                label: Text('周${_weekdayLabels[d]}'),
                selected: selected,
                onSelected: (v) => setState(() {
                  if (v) { weekdays.add(d); weekdays.sort(); }
                  else { weekdays.remove(d); }
                }),
                showCheckmark: false,
                selectedColor: courseColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? courseColor : null, fontSize: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: selected
                        ? courseColor.withValues(alpha: 0.5)
                        : sheetTheme.dividerColor)),
                padding: const EdgeInsets.symmetric(horizontal: 2),
              );
            }).toList()),
            const SizedBox(height: 14),
            Text('时间段', style: sheetTheme.textTheme.labelLarge),
            const SizedBox(height: 8),
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
                        child: child!));
                    if (picked != null) setState(() => startTime = picked);
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('—')),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text('结束 ${fmtTime(endTime)}'),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: ctx, initialTime: endTime,
                      builder: (c, child) => MediaQuery(
                        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
                        child: child!));
                    if (picked != null) setState(() => endTime = picked);
                  },
                ),
              ),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  course.weekdays = weekdays;
                  course.startTime = fmtTime(startTime);
                  course.endTime = fmtTime(endTime);
                  ref.read(courseProvider.notifier).updateCourse(course);
                  Navigator.pop(ctx);
                },
                child: const Text('保存')),
            ),
          ]),
        );
      }),
    );
  }

  TimeOfDay _parseTime(String s) {
    final parts = s.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0);
  }

  void _showEditScoreDialog(BuildContext context, WidgetRef ref, String cid, double? cur) {
    final ctrl = TextEditingController(text: cur?.toStringAsFixed(0) ?? '');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('设置成绩'),
      content: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: '分数 (0-100)')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () {
          final s = double.tryParse(ctrl.text.trim());
          if (s == null || s < 0 || s > 100) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('请输入 0~100 之间的数字成绩')));
            return;
          }
          ref.read(courseProvider.notifier).setScore(cid, s);
          Navigator.pop(ctx);
        }, child: const Text('保存')),
      ]));
  }
}
