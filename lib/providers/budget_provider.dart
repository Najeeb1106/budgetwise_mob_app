import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../data/database.dart';
import 'database_provider.dart';
import 'transaction_provider.dart';
import 'category_provider.dart';

class CategoryBudgetUsage {
  final Category category;
  final Budget? budget;
  final double spent;
  final double limit;

  double get percentage => limit > 0 ? (spent / limit) : 0.0;
  bool get isOverBudget => limit > 0 && spent > limit;
  bool get isApproachingLimit =>
      limit > 0 &&
      budget != null &&
      spent >= (limit * budget!.alertThreshold) &&
      spent <= limit;

  CategoryBudgetUsage({
    required this.category,
    this.budget,
    required this.spent,
    required this.limit,
  });
}

// Stream provider to fetch budgets for the current selected month/year in transactionFiltersProvider
final budgetsStreamProvider = StreamProvider<List<Budget>>((ref) {
  final db = ref.watch(databaseProvider);
  final filters = ref.watch(transactionFiltersProvider);

  return (db.select(db.budgets)..where(
        (b) =>
            b.month.equals(filters.month.month) &
            b.year.equals(filters.month.year),
      ))
      .watch();
});

// Aggregate Category Budget Usages in real-time
final budgetUsagesProvider = StreamProvider<List<CategoryBudgetUsage>>((ref) {
  final db = ref.watch(databaseProvider);
  final categoriesAsync = ref.watch(categoryStreamProvider);
  final budgetsAsync = ref.watch(budgetsStreamProvider);
  final filters = ref.watch(transactionFiltersProvider);

  // Watch transactions for the target month
  final startOfMonth = DateTime(filters.month.year, filters.month.month, 1);
  final endOfMonth = DateTime(
    filters.month.year,
    filters.month.month + 1,
    0,
    23,
    59,
    59,
  );

  final transactionsStream =
      (db.select(db.transactions)..where(
            (t) =>
                t.date.isBetweenValues(startOfMonth, endOfMonth) &
                t.type.equals('expense'),
          ))
          .watch();

  return transactionsStream.map((txs) {
    final categories = categoriesAsync.value ?? [];
    final budgets = budgetsAsync.value ?? [];

    return categories
        .where((cat) => cat.type == 'expense' || cat.type == 'both')
        .map((cat) {
          final categoryTxs = txs.where((tx) => tx.categoryId == cat.id);
          final spent = categoryTxs.fold<double>(
            0.0,
            (sum, item) => sum + item.amount,
          );

          final budget = budgets.cast<Budget?>().firstWhere(
            (b) => b?.categoryId == cat.id,
            orElse: () => null,
          );

          final limit = budget?.limitAmount ?? 0.0;

          return CategoryBudgetUsage(
            category: cat,
            budget: budget,
            spent: spent,
            limit: limit,
          );
        })
        .toList();
  });
});

class BudgetNotifier extends FamilyNotifier<void, AppDatabase> {
  @override
  void build(AppDatabase arg) {}

  Future<void> setOrUpdateBudget({
    required String categoryId,
    required double limitAmount,
    required int month,
    required int year,
    required double alertThreshold,
  }) async {
    final db = arg;
    // Check if budget already exists for this category/month/year
    final query = db.select(db.budgets)
      ..where(
        (b) =>
            b.categoryId.equals(categoryId) &
            b.month.equals(month) &
            b.year.equals(year),
      );
    final existing = await query.getSingleOrNull();

    if (existing != null) {
      // Update
      await (db.update(
        db.budgets,
      )..where((b) => b.id.equals(existing.id))).write(
        BudgetsCompanion(
          limitAmount: Value(limitAmount),
          alertThreshold: Value(alertThreshold),
        ),
      );
    } else {
      // Insert
      await db
          .into(db.budgets)
          .insert(
            BudgetsCompanion.insert(
              id: const Uuid().v4(),
              categoryId: categoryId,
              limitAmount: limitAmount,
              month: month,
              year: year,
              alertThreshold: Value(alertThreshold),
            ),
          );
    }
  }

  Future<void> deleteBudget(String id) async {
    final db = arg;
    await (db.delete(db.budgets)..where((b) => b.id.equals(id))).go();
  }
}

final budgetNotifierProvider =
    NotifierProvider.family<BudgetNotifier, void, AppDatabase>(() {
      return BudgetNotifier();
    });
