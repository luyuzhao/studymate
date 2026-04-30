// AI生成 - 任务看板页，支持子任务、重复任务、智能建议
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/task_provider.dart';
import '../../providers/course_provider.dart';
import '../../models/task.dart';

class TaskBoardPage extends ConsumerStatefulWidget {
  const TaskBoardPage({super.key});
  @override
  ConsumerState<TaskBoardPage> createState() => _TaskBoardPageState();
}

class _TaskBoardPageState extends ConsumerState<TaskBoardPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskProvider);
    final todo = tasks.where((t) => t.status == TaskStatus.todo).toList();
    final doing = tasks.where((t) => t.status == TaskStatus.inProgress).toList();
    final done = tasks.where((t) => t.status == TaskStatus.done).toList();
    final suggested = ref.read(taskProvider.notifier).getSuggestedTasks();

    return Scaffold(
      appBar: AppBar(title: const Text('任务待办'),
        bottom: TabBar(controller: _tabCtrl, isScrollable: true, tabs: [
          Tab(text: '建议 (${suggested.length})'),
          Tab(text: '待做 (${todo.length})'),
          Tab(text: '进行中 (${doing.length})'),
          Tab(text: '已完成 (${done.length})'),
        ])),
      body: TabBarView(controller: _tabCtrl, children: [
        _suggestList(suggested),
        _list(todo, '暂无待做任务'),
        _list(doing, '暂无进行中任务'),
        _list(done, '暂无已完成任务'),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: () => _showAddDialog(context), child: const Icon(Icons.add)),
    );
  }

  Widget _suggestList(List<Task> tasks) {
    final theme = Theme.of(context);
    if (tasks.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.check_circle_outline, size: 64, color: Colors.green.withValues(alpha: 0.4)),
      const SizedBox(height: 8), Text('今日无紧急任务', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 4), Text('保持学习节奏！', style: theme.textTheme.bodySmall),
    ]));
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text('智能建议：优先处理逾期和今日到期的高优任务', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
        ]),
      ),
      ...tasks.map((t) => _card(t)),
    ]);
  }

  Widget _list(List<Task> tasks, String empty) {
    final theme = Theme.of(context);
    if (tasks.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.inbox_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
      const SizedBox(height: 8), Text(empty, style: TextStyle(color: theme.colorScheme.onSurfaceVariant))]));
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: tasks.length,
      itemBuilder: (_, i) => _card(tasks[i]));
  }

  Widget _card(Task task) {
    final theme = Theme.of(context);
    final pColors = [Colors.green, Colors.orange, Colors.red];
    final pLabels = ['低', '中', '高'];
    return Dismissible(key: Key(task.id), direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete, color: Colors.white)),
      confirmDismiss: (_) async => await showDialog<bool>(context: context,
        builder: (ctx) => AlertDialog(title: const Text('删除任务'), content: Text('确定删除 "${task.title}" 吗？'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除'))])) ?? false,
      onDismissed: (_) => ref.read(taskProvider.notifier).deleteTask(task.id),
      child: Card(margin: const EdgeInsets.only(bottom: 8), child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showTaskDetail(context, task),
        child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (task.isOverdue) Padding(padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.warning_amber, size: 16, color: theme.colorScheme.error)),
            if (task.isRecurring) Padding(padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.repeat, size: 16, color: theme.colorScheme.tertiary)),
            Expanded(child: Text(task.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600,
              decoration: task.status == TaskStatus.done ? TextDecoration.lineThrough : null))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: pColors[task.priority].withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
              child: Text(pLabels[task.priority], style: TextStyle(color: pColors[task.priority], fontSize: 12, fontWeight: FontWeight.bold))),
          ]),
          if (task.description.isNotEmpty) ...[const SizedBox(height: 6),
            Text(task.description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis)],
          // 子任务进度条
          if (task.subtasks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: task.subtaskProgress, minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: task.subtaskProgress >= 1.0 ? Colors.green : theme.colorScheme.primary))),
              const SizedBox(width: 8),
              Text('${task.subtasksDone}/${task.subtasks.length}', style: theme.textTheme.labelSmall),
            ]),
          ],
          const SizedBox(height: 10),
          Row(children: [
            if (task.dueDate != null) ...[Icon(Icons.schedule, size: 14, color: task.isOverdue ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant), const SizedBox(width: 4),
              Text(DateFormat('M/d HH:mm').format(task.dueDate!), style: TextStyle(fontSize: 12, color: task.isOverdue ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant))],
            if (task.isOverdue) ...[const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: theme.colorScheme.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                child: Text('已逾期', style: TextStyle(fontSize: 10, color: theme.colorScheme.error, fontWeight: FontWeight.bold)))],
            const Spacer(),
            PopupMenuButton<TaskStatus>(onSelected: (s) => ref.read(taskProvider.notifier).updateStatus(task.id, s),
              itemBuilder: (_) => const [PopupMenuItem(value: TaskStatus.todo, child: Text('待做')), PopupMenuItem(value: TaskStatus.inProgress, child: Text('进行中')), PopupMenuItem(value: TaskStatus.done, child: Text('已完成'))],
              child: Chip(label: Text(task.status == TaskStatus.todo ? '待做' : task.status == TaskStatus.inProgress ? '进行中' : '已完成', style: const TextStyle(fontSize: 12)), visualDensity: VisualDensity.compact)),
          ]),
        ])))));
  }

  /// 任务详情弹窗：含子任务 Checklist
  void _showTaskDetail(BuildContext context, Task task) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setBS) {
        final subCtrl = TextEditingController();
        return DraggableScrollableSheet(
          initialChildSize: 0.6, minChildSize: 0.3, maxChildSize: 0.9, expand: false,
          builder: (_, scrollCtrl) => ListView(controller: scrollCtrl, padding: const EdgeInsets.all(24), children: [
            Text(task.title, style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            if (task.description.isNotEmpty) ...[const SizedBox(height: 8), Text(task.description, style: Theme.of(ctx).textTheme.bodyMedium)],
            if (task.isRecurring) ...[const SizedBox(height: 8),
              Chip(avatar: const Icon(Icons.repeat, size: 16), label: Text(task.repeatType == 1 ? '每${task.repeatInterval}天重复' : '每${task.repeatInterval}周重复'))],
            const SizedBox(height: 16),
            Row(children: [
              Text('子任务 (${task.subtasksDone}/${task.subtasks.length})', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (task.subtasks.isNotEmpty)
                Text('${(task.subtaskProgress * 100).toInt()}%', style: TextStyle(color: Theme.of(ctx).colorScheme.primary, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            ...task.subtasks.map((sub) => CheckboxListTile(
              value: sub.done,
              title: Text(sub.title, style: TextStyle(decoration: sub.done ? TextDecoration.lineThrough : null)),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              secondary: IconButton(icon: const Icon(Icons.close, size: 18),
                onPressed: () { ref.read(taskProvider.notifier).removeSubtask(task.id, sub.id); setBS(() {}); }),
              onChanged: (_) { ref.read(taskProvider.notifier).toggleSubtask(task.id, sub.id); setBS(() {}); },
            )),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: subCtrl, decoration: const InputDecoration(hintText: '添加子任务...', isDense: true))),
              IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () {
                if (subCtrl.text.trim().isEmpty) return;
                ref.read(taskProvider.notifier).addSubtask(task.id, subCtrl.text.trim());
                subCtrl.clear(); setBS(() {});
              }),
            ]),
          ]),
        );
      }));
  }

  void _showAddDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int priority = 1; DateTime? dueDate; String? courseId;
    int repeatType = 0; int repeatInterval = 1;
    final courses = ref.read(courseProvider);

    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('新建任务', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '任务标题 *'), autofocus: true),
          const SizedBox(height: 12),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: '描述 (可选)'), maxLines: 2),
          const SizedBox(height: 12),
          Row(children: [const Text('优先级: '), const SizedBox(width: 8),
            ChoiceChip(label: const Text('低'), selected: priority == 0, onSelected: (_) => setState(() => priority = 0)),
            const SizedBox(width: 8), ChoiceChip(label: const Text('中'), selected: priority == 1, onSelected: (_) => setState(() => priority = 1)),
            const SizedBox(width: 8), ChoiceChip(label: const Text('高'), selected: priority == 2, onSelected: (_) => setState(() => priority = 2))]),
          const SizedBox(height: 12),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_today),
            title: Text(dueDate != null ? DateFormat('yyyy-MM-dd HH:mm').format(dueDate!) : '设置截止日期'),
            onTap: () async {
              final d = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
              if (d != null && ctx.mounted) { final t = await showTimePicker(context: ctx, initialTime: const TimeOfDay(hour: 23, minute: 59));
                setState(() => dueDate = DateTime(d.year, d.month, d.day, t?.hour ?? 23, t?.minute ?? 59)); }
            }),
          // 重复任务设置
          Row(children: [const Icon(Icons.repeat, size: 20), const SizedBox(width: 8), const Text('重复: '), const SizedBox(width: 8),
            ChoiceChip(label: const Text('不重复'), selected: repeatType == 0, onSelected: (_) => setState(() => repeatType = 0)),
            const SizedBox(width: 6), ChoiceChip(label: const Text('每天'), selected: repeatType == 1, onSelected: (_) => setState(() => repeatType = 1)),
            const SizedBox(width: 6), ChoiceChip(label: const Text('每周'), selected: repeatType == 2, onSelected: (_) => setState(() => repeatType = 2)),
          ]),
          if (courses.isNotEmpty) ...[const SizedBox(height: 8),
            DropdownButtonFormField<String?>(initialValue: courseId, decoration: const InputDecoration(labelText: '关联课程 (可选)'),
              items: [const DropdownMenuItem(value: null, child: Text('无')), ...courses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))],
              onChanged: (v) => setState(() => courseId = v))],
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () {
            if (titleCtrl.text.trim().isEmpty) return;
            ref.read(taskProvider.notifier).addTask(
              title: titleCtrl.text.trim(), description: descCtrl.text.trim(),
              priority: priority, dueDate: dueDate, courseId: courseId,
              repeatType: repeatType, repeatInterval: repeatInterval,
            );
            Navigator.pop(ctx);
          }, child: const Text('创建任务'))),
        ]))));
  }
}
