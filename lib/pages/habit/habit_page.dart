// AI生成 - 习惯打卡页，含热力图和打卡操作
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/habit_provider.dart';
import '../../models/habit.dart';

class HabitPage extends ConsumerWidget {
  const HabitPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('习惯打卡')),
      body: habits.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.track_changes, size: 80, color: theme.colorScheme.primary.withOpacity(0.4)),
              const SizedBox(height: 16), Text('开始养成好习惯吧', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8), Text('每天坚持打卡，21天形成习惯', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))]))
          : ListView.builder(padding: const EdgeInsets.all(16), itemCount: habits.length,
              itemBuilder: (_, i) => _habitCard(context, ref, habits[i])),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _addHabit(context, ref), icon: const Icon(Icons.add), label: const Text('新建习惯')),
    );
  }

  Widget _habitCard(BuildContext context, WidgetRef ref, Habit habit) {
    final theme = Theme.of(context);
    final color = Color(habit.colorValue);
    final checked = ref.read(habitProvider.notifier).isCheckedToday(habit.id);

    return Card(margin: const EdgeInsets.only(bottom: 16), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.flag, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(habit.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          Text('连续 ${habit.currentStreak} 天 · 共 ${habit.totalCheckins} 次', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ])),
        FilledButton.tonal(onPressed: checked ? null : () => ref.read(habitProvider.notifier).checkIn(habit.id),
          style: FilledButton.styleFrom(backgroundColor: color.withOpacity(checked ? 0.15 : 0.12), foregroundColor: color),
          child: Text(checked ? '已打卡 ✓' : '打卡')),
        PopupMenuButton(itemBuilder: (_) => [const PopupMenuItem(value: 'delete', child: Text('删除'))],
          onSelected: (v) { if (v == 'delete') ref.read(habitProvider.notifier).deleteHabit(habit.id); }),
      ]),
      const SizedBox(height: 16),
      // 35天热力图
      _heatmap(context, habit, color),
      const SizedBox(height: 12),
      Row(children: [
        Text('目标: ${habit.targetDays} 天', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const Spacer(),
        Text('${(habit.totalCheckins / habit.targetDays * 100).clamp(0, 100).toStringAsFixed(0)}%', style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 4),
      LinearProgressIndicator(value: (habit.totalCheckins / habit.targetDays).clamp(0.0, 1.0), backgroundColor: theme.colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation(color), borderRadius: BorderRadius.circular(4)),
    ])));
  }

  Widget _heatmap(BuildContext context, Habit habit, Color color) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 3, crossAxisSpacing: 3),
      itemCount: 35, itemBuilder: (_, i) {
        final date = today.subtract(Duration(days: 34 - i));
        final isChecked = habit.records.any((r) { final d = DateTime(r.date.year, r.date.month, r.date.day); return d == date; });
        final isToday = date == today;
        return Container(decoration: BoxDecoration(
          color: isChecked ? color.withOpacity(0.7) : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4), border: isToday ? Border.all(color: color, width: 2) : null));
      });
  }

  void _addHabit(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    int targetDays = 21, selColor = 0xFF16A085;
    final colors = [0xFF16A085, 0xFF4A90D9, 0xFFE74C3C, 0xFFF39C12, 0xFF8E44AD, 0xFF27AE60, 0xFFE67E22, 0xFF2C3E50];

    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('新建习惯', style: Theme.of(ctx).textTheme.titleLarge), const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '习惯名称 *', hintText: '如：每日阅读、健身、早起...'), autofocus: true),
          const SizedBox(height: 16),
          Text('目标天数', style: Theme.of(ctx).textTheme.labelLarge), const SizedBox(height: 8),
          Wrap(spacing: 8, children: [7, 14, 21, 30, 60, 100].map((d) => ChoiceChip(label: Text('$d 天'), selected: targetDays == d, onSelected: (_) => setState(() => targetDays = d))).toList()),
          const SizedBox(height: 16),
          Text('颜色', style: Theme.of(ctx).textTheme.labelLarge), const SizedBox(height: 8),
          Wrap(spacing: 8, children: colors.map((c) => GestureDetector(onTap: () => setState(() => selColor = c),
            child: Container(width: 32, height: 32, decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle, border: selColor == c ? Border.all(color: Colors.white, width: 3) : null)))).toList()),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () {
            if (nameCtrl.text.trim().isEmpty) return;
            ref.read(habitProvider.notifier).addHabit(name: nameCtrl.text.trim(), colorValue: selColor, targetDays: targetDays);
            Navigator.pop(ctx);
          }, child: const Text('创建'))),
        ]))));
  }
}
