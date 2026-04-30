// AI生成 - 记账数据模型
import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 6)
class Expense extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  ExpenseCategory category;

  @HiveField(3)
  String description;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  bool isIncome;

  @HiveField(6)
  String userId;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    this.description = '',
    DateTime? date,
    this.isIncome = false,
    this.userId = 'guest',
  }) : date = date ?? DateTime.now();
}

@HiveType(typeId: 7)
enum ExpenseCategory {
  @HiveField(0)
  food,
  @HiveField(1)
  transport,
  @HiveField(2)
  shopping,
  @HiveField(3)
  entertainment,
  @HiveField(4)
  study,
  @HiveField(5)
  living,
  @HiveField(6)
  other,
  @HiveField(7)
  income,
}

extension ExpenseCategoryExt on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.food: return '餐饮';
      case ExpenseCategory.transport: return '交通';
      case ExpenseCategory.shopping: return '购物';
      case ExpenseCategory.entertainment: return '娱乐';
      case ExpenseCategory.study: return '学习';
      case ExpenseCategory.living: return '生活';
      case ExpenseCategory.other: return '其他';
      case ExpenseCategory.income: return '收入';
    }
  }

  String get icon {
    switch (this) {
      case ExpenseCategory.food: return '🍜';
      case ExpenseCategory.transport: return '🚌';
      case ExpenseCategory.shopping: return '🛍️';
      case ExpenseCategory.entertainment: return '🎮';
      case ExpenseCategory.study: return '📚';
      case ExpenseCategory.living: return '🏠';
      case ExpenseCategory.other: return '📦';
      case ExpenseCategory.income: return '💰';
    }
  }
}
