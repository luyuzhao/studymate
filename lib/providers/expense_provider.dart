// AI生成 - 记账状态管理
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import 'user_provider.dart';

final expenseProvider =
    StateNotifierProvider<ExpenseNotifier, List<Expense>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return ExpenseNotifier(userId);
});

class ExpenseNotifier extends StateNotifier<List<Expense>> {
  ExpenseNotifier(this._userId) : super([]) { _loadExpenses(); }

  final String _userId;
  final _box = Hive.box<Expense>('expenses');
  final _uuid = const Uuid();

  void _loadExpenses() {
    state = _box.values.where((e) => e.userId == _userId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addExpense({
    required double amount, required ExpenseCategory category,
    String description = '', DateTime? date, bool isIncome = false,
  }) async {
    final expense = Expense(id: _uuid.v4(), amount: amount, category: category,
        description: description, date: date, isIncome: isIncome, userId: _userId);
    await _box.put(expense.id, expense);
    _loadExpenses();
  }

  Future<void> deleteExpense(String id) async { await _box.delete(id); _loadExpenses(); }

  double get totalExpense => state.where((e) => !e.isIncome).fold(0.0, (s, e) => s + e.amount);
  double get totalIncome => state.where((e) => e.isIncome).fold(0.0, (s, e) => s + e.amount);
  double get balance => totalIncome - totalExpense;

  Map<ExpenseCategory, double> getCategoryBreakdown({int? year, int? month}) {
    final filtered = state.where((e) {
      if (e.isIncome) return false;
      if (year != null && e.date.year != year) return false;
      if (month != null && e.date.month != month) return false;
      return true;
    });
    final map = <ExpenseCategory, double>{};
    for (final e in filtered) { map[e.category] = (map[e.category] ?? 0) + e.amount; }
    return map;
  }

  List<Expense> getExpensesByMonth(int year, int month) {
    return state.where((e) => e.date.year == year && e.date.month == month).toList();
  }
}
