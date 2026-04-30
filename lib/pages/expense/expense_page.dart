// AI生成 - 记账页，包含快速记账、分类统计饼图和月度明细
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/expense_provider.dart';
import '../../models/expense.dart';

class ExpensePage extends ConsumerStatefulWidget {
  const ExpensePage({super.key});
  @override
  ConsumerState<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends ConsumerState<ExpensePage> {
  late int _year, _month;
  @override
  void initState() { super.initState(); final now = DateTime.now(); _year = now.year; _month = now.month; }

  @override
  Widget build(BuildContext context) {
    ref.watch(expenseProvider);
    final theme = Theme.of(context);
    final notifier = ref.read(expenseProvider.notifier);
    final monthExp = notifier.getExpensesByMonth(_year, _month);
    final total = monthExp.where((e) => !e.isIncome).fold<double>(0, (s, e) => s + e.amount);
    final income = monthExp.where((e) => e.isIncome).fold<double>(0, (s, e) => s + e.amount);
    final catBreak = notifier.getCategoryBreakdown(year: _year, month: _month);

    return Scaffold(appBar: AppBar(title: const Text('记账本')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 月份切换
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() { if (_month == 1) { _month = 12; _year--; } else _month--; })),
          Text('$_year年$_month月', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() { if (_month == 12) { _month = 1; _year++; } else _month++; })),
        ]),
        const SizedBox(height: 16),
        // 收支概览
        Row(children: [
          Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('支出', style: theme.textTheme.labelMedium),
              Text('¥${total.toStringAsFixed(2)}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.red))]))),
          const SizedBox(width: 12),
          Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.green.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('收入', style: theme.textTheme.labelMedium),
              Text('¥${income.toStringAsFixed(2)}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.green))]))),
        ]),
        const SizedBox(height: 20),
        // 饼图
        if (catBreak.isNotEmpty) ...[
          Text('支出分类', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 12),
          SizedBox(height: 200, child: Row(children: [
            Expanded(child: PieChart(PieChartData(sections: catBreak.entries.map((e) {
              final pct = total > 0 ? e.value / total * 100 : 0.0;
              return PieChartSectionData(color: _catColor(e.key), value: e.value, title: '${pct.toStringAsFixed(0)}%', radius: 50,
                titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white));
            }).toList(), centerSpaceRadius: 40, sectionsSpace: 2))),
            const SizedBox(width: 16),
            Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
              children: catBreak.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: _catColor(e.key), borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 6),
                Text('${e.key.icon} ${e.key.label}', style: theme.textTheme.bodySmall)]))).toList()),
          ])),
          const SizedBox(height: 20),
        ],
        // 明细
        Text('支出明细', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 8),
        if (monthExp.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('本月暂无记录', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))))
        else ...monthExp.map((exp) => Dismissible(key: Key(exp.id), direction: DismissDirection.endToStart,
          background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.delete, color: Colors.white)),
          onDismissed: (_) => ref.read(expenseProvider.notifier).deleteExpense(exp.id),
          child: Card(margin: const EdgeInsets.only(bottom: 6), child: ListTile(
            leading: Text(exp.category.icon, style: const TextStyle(fontSize: 24)),
            title: Text(exp.description.isEmpty ? exp.category.label : exp.description),
            subtitle: Text(DateFormat('MM/dd HH:mm').format(exp.date)),
            trailing: Text('${exp.isIncome ? '+' : '-'}¥${exp.amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: exp.isIncome ? Colors.green : Colors.red)))))),
      ])),
      floatingActionButton: FloatingActionButton(onPressed: () => _addExpense(context), child: const Icon(Icons.add)),
    );
  }

  Color _catColor(ExpenseCategory c) {
    switch (c) {
      case ExpenseCategory.food: return const Color(0xFFE74C3C);
      case ExpenseCategory.transport: return const Color(0xFF3498DB);
      case ExpenseCategory.shopping: return const Color(0xFFF39C12);
      case ExpenseCategory.entertainment: return const Color(0xFF9B59B6);
      case ExpenseCategory.study: return const Color(0xFF2ECC71);
      case ExpenseCategory.living: return const Color(0xFF1ABC9C);
      case ExpenseCategory.other: return const Color(0xFF95A5A6);
      case ExpenseCategory.income: return const Color(0xFF27AE60);
    }
  }

  void _addExpense(BuildContext context) {
    final amtCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    ExpenseCategory cat = ExpenseCategory.food;
    bool isIncome = false;

    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text('记一笔', style: Theme.of(ctx).textTheme.titleLarge), const Spacer(),
            SegmentedButton<bool>(segments: const [ButtonSegment(value: false, label: Text('支出')), ButtonSegment(value: true, label: Text('收入'))],
              selected: {isIncome}, onSelectionChanged: (v) => setState(() => isIncome = v.first))]),
          const SizedBox(height: 16),
          TextField(controller: amtCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: Theme.of(ctx).textTheme.headlineMedium,
            decoration: InputDecoration(prefixText: '¥ ', hintText: '0.00', border: InputBorder.none, prefixStyle: TextStyle(fontSize: 28, color: isIncome ? Colors.green : Colors.red)), autofocus: true),
          const SizedBox(height: 12),
          if (!isIncome) ...[Text('分类', style: Theme.of(ctx).textTheme.labelLarge), const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: ExpenseCategory.values.where((c) => c != ExpenseCategory.income).map((c) =>
              ChoiceChip(label: Text('${c.icon} ${c.label}'), selected: cat == c, onSelected: (_) => setState(() => cat = c))).toList()), const SizedBox(height: 12)],
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: '备注 (可选)')),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () {
            final amt = double.tryParse(amtCtrl.text);
            if (amt == null || amt <= 0) return;
            ref.read(expenseProvider.notifier).addExpense(amount: amt, category: isIncome ? ExpenseCategory.income : cat, description: descCtrl.text.trim(), isIncome: isIncome);
            Navigator.pop(ctx);
          }, child: const Text('保存'))),
        ]))));
  }
}
