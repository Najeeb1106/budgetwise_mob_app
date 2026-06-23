import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/database.dart';
import 'database_provider.dart';
import 'category_provider.dart';

class MonthlyStat {
  final String monthLabel; // e.g. "Jan", "Feb"
  final DateTime date;
  final double income;
  final double expense;

  MonthlyStat({
    required this.monthLabel,
    required this.date,
    required this.income,
    required this.expense,
  });
}

class CategorySpend {
  final Category category;
  final double amount;
  final double percentage;

  CategorySpend({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class AnalyticsData {
  final List<MonthlyStat> monthlyHistory; // last 6 months
  final List<CategorySpend> categoryBreakdown; // current selected month
  final String topSpendingCategory;
  final double averageDailySpend;
  final double totalSavedThisMonth;

  AnalyticsData({
    required this.monthlyHistory,
    required this.categoryBreakdown,
    required this.topSpendingCategory,
    required this.averageDailySpend,
    required this.totalSavedThisMonth,
  });
}

final analyticsRangeProvider = StateProvider<String>(
  (ref) => '6_months',
); // 'month' | '3_months' | '6_months' | 'year'

final analyticsDataProvider = StreamProvider<AnalyticsData>((ref) {
  final db = ref.watch(databaseProvider);
  final range = ref.watch(analyticsRangeProvider);
  final categoriesAsync = ref.watch(categoryStreamProvider);

  int monthsCount = 6;
  if (range == 'month') monthsCount = 1;
  if (range == '3_months') monthsCount = 3;
  if (range == 'year') monthsCount = 12;

  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month - monthsCount + 1, 1);

  // Stream of all transactions from startDate to now
  final txsStream = (db.select(
    db.transactions,
  )..where((t) => t.date.isBetweenValues(startDate, DateTime.now()))).watch();

  return txsStream.map((txs) {
    final categories = categoriesAsync.value ?? [];
    final monthlyHistory = <MonthlyStat>[];

    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    // 1. Calculate Monthly History (Income vs Expense)
    for (int i = monthsCount - 1; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthTxs = txs.where(
        (t) => t.date.year == monthDate.year && t.date.month == monthDate.month,
      );

      final income = monthTxs
          .where((t) => t.type == 'income')
          .fold<double>(0.0, (sum, t) => sum + t.amount);
      final expense = monthTxs
          .where((t) => t.type == 'expense')
          .fold<double>(0.0, (sum, t) => sum + t.amount);

      monthlyHistory.add(
        MonthlyStat(
          monthLabel: monthNames[monthDate.month - 1],
          date: monthDate,
          income: income,
          expense: expense,
        ),
      );
    }

    // 2. Calculate Category Breakdown for CURRENT month
    final currentMonthTxs = txs.where(
      (t) => t.date.year == now.year && t.date.month == now.month,
    );
    final currentExpenses = currentMonthTxs.where((t) => t.type == 'expense');
    final totalExpense = currentExpenses.fold<double>(
      0.0,
      (sum, t) => sum + t.amount,
    );

    final breakdown = <CategorySpend>[];
    for (final cat in categories) {
      if (cat.type == 'expense' || cat.type == 'both') {
        final catSpent = currentExpenses
            .where((t) => t.categoryId == cat.id)
            .fold<double>(0.0, (sum, t) => sum + t.amount);
        if (catSpent > 0) {
          breakdown.add(
            CategorySpend(
              category: cat,
              amount: catSpent,
              percentage: totalExpense > 0 ? (catSpent / totalExpense) : 0.0,
            ),
          );
        }
      }
    }

    // Sort breakdown by amount descending
    breakdown.sort((a, b) => b.amount.compareTo(a.amount));

    // Stats calculations
    String topCategory = 'None';
    if (breakdown.isNotEmpty) {
      topCategory = breakdown.first.category.name;
    }

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final totalSpentThisMonth = currentExpenses.fold<double>(
      0.0,
      (sum, t) => sum + t.amount,
    );
    final avgDaily = daysInMonth > 0
        ? (totalSpentThisMonth / daysInMonth)
        : 0.0;

    final totalIncomeThisMonth = currentMonthTxs
        .where((t) => t.type == 'income')
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    final totalSaved = totalIncomeThisMonth - totalSpentThisMonth;

    return AnalyticsData(
      monthlyHistory: monthlyHistory,
      categoryBreakdown: breakdown,
      topSpendingCategory: topCategory,
      averageDailySpend: avgDaily,
      totalSavedThisMonth: totalSaved,
    );
  });
});
