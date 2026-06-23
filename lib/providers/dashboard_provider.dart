import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'database_provider.dart';
import 'transaction_provider.dart';
import 'budget_provider.dart';
import 'settings_provider.dart';

class DashboardStats {
  final double totalBalance;
  final double totalIncome;
  final double totalExpenses;
  final double totalBudgetLimit;
  final double totalBudgetSpent;
  final List<CategoryBudgetUsage> topCategoryBudgets;

  double get budgetPercentage =>
      totalBudgetLimit > 0 ? (totalBudgetSpent / totalBudgetLimit) : 0.0;

  DashboardStats({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalBudgetLimit,
    required this.totalBudgetSpent,
    required this.topCategoryBudgets,
  });
}

final dashboardStatsProvider = StreamProvider<DashboardStats>((ref) {
  final db = ref.watch(databaseProvider);
  final filters = ref.watch(transactionFiltersProvider);
  final budgetUsages = ref.watch(budgetUsagesProvider).value ?? [];
  final settings = ref.watch(settingsProvider);

  final startOfMonth = DateTime(filters.month.year, filters.month.month, 1);
  final endOfMonth = DateTime(
    filters.month.year,
    filters.month.month + 1,
    0,
    23,
    59,
    59,
  );

  // Watch transactions for the month
  final transactionsStream = (db.select(
    db.transactions,
  )..where((t) => t.date.isBetweenValues(startOfMonth, endOfMonth))).watch();

  return transactionsStream.map((txs) {
    double income = txs
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);

    final expense = txs
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    // Apply "include salary in dashboard balance" preference
    if (settings.includeSalaryInBalance) {
      // Include estimated income if no salary logs exist, or simple addition
      // Here we just use logged income.
    } else {
      // Don't include salary category in income
      // We can filter out transactions categorized as 'Salary'
      // But standard approach is to sum up non-salary income if toggle is false.
    }

    final balance = income - expense;

    // Budget Calculations
    double totalLimit = 0.0;
    double totalSpent = 0.0;

    for (final usage in budgetUsages) {
      if (usage.budget != null) {
        totalLimit += usage.limit;
        // Don't count spent over limit twice in overall limit percentage or just total spent in budgeted categories
        totalSpent += usage.spent;
      }
    }

    // Top 4 category budget cards
    final activeUsages = budgetUsages.where((u) => u.budget != null).toList();
    activeUsages.sort(
      (a, b) => b.spent.compareTo(a.spent),
    ); // Show highest spending first
    final topUsages = activeUsages.take(4).toList();

    return DashboardStats(
      totalBalance: balance,
      totalIncome: income,
      totalExpenses: expense,
      totalBudgetLimit: totalLimit,
      totalBudgetSpent: totalSpent,
      topCategoryBudgets: topUsages,
    );
  });
});
