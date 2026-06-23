import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../data/database.dart';
import 'database_provider.dart';
import 'settings_provider.dart';
import '../services/notification_service.dart';

class TransactionFilters {
  final DateTime month;
  final String search;
  final String? type; // 'income' | 'expense' | null
  final List<String> categoryIds;
  final String
  sortBy; // 'date_desc' | 'date_asc' | 'amount_desc' | 'amount_asc'

  TransactionFilters({
    required this.month,
    this.search = '',
    this.type,
    this.categoryIds = const [],
    this.sortBy = 'date_desc',
  });

  TransactionFilters copyWith({
    DateTime? month,
    String? search,
    String? type,
    List<String>? categoryIds,
    String? sortBy,
  }) {
    return TransactionFilters(
      month: month ?? this.month,
      search: search ?? this.search,
      type: type != undefined ? type : this.type,
      categoryIds: categoryIds ?? this.categoryIds,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

// Magic value to represent resetting a parameter to null
const String undefined = '__undefined__';

class TransactionFiltersNotifier extends StateNotifier<TransactionFilters> {
  TransactionFiltersNotifier()
    : super(TransactionFilters(month: DateTime.now()));

  void setMonth(DateTime month) {
    state = state.copyWith(month: month);
  }

  void setSearch(String search) {
    state = state.copyWith(search: search);
  }

  void setType(String? type) {
    state = state.copyWith(type: type ?? undefined);
  }

  void toggleCategory(String categoryId) {
    final list = List<String>.from(state.categoryIds);
    if (list.contains(categoryId)) {
      list.remove(categoryId);
    } else {
      list.add(categoryId);
    }
    state = state.copyWith(categoryIds: list);
  }

  void resetCategories() {
    state = state.copyWith(categoryIds: const []);
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }
}

final transactionFiltersProvider =
    StateNotifierProvider<TransactionFiltersNotifier, TransactionFilters>((
      ref,
    ) {
      return TransactionFiltersNotifier();
    });

// A stream provider that watches all transactions and returns them joined with their categories
class TransactionWithCategory {
  final Transaction transaction;
  final Category category;

  TransactionWithCategory({required this.transaction, required this.category});
}

class PaginatedTransactionsState {
  final List<TransactionWithCategory> transactions;
  final bool hasMore;
  final bool isLoadingMore;
  final int offset;

  PaginatedTransactionsState({
    required this.transactions,
    required this.hasMore,
    required this.isLoadingMore,
    required this.offset,
  });

  PaginatedTransactionsState copyWith({
    List<TransactionWithCategory>? transactions,
    bool? hasMore,
    bool? isLoadingMore,
    int? offset,
  }) {
    return PaginatedTransactionsState(
      transactions: transactions ?? this.transactions,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      offset: offset ?? this.offset,
    );
  }
}

class PaginatedTransactionsNotifier
    extends StateNotifier<AsyncValue<PaginatedTransactionsState>> {
  final AppDatabase db;
  final TransactionFilters filters;
  StreamSubscription? _subscription;
  bool _isDisposed = false;

  PaginatedTransactionsNotifier(this.db, this.filters)
    : super(const AsyncValue.loading()) {
    _loadInitial();

    _subscription = db.tableUpdates().listen((updates) {
      if (_isDisposed) return;
      final hasUpdate = updates.any(
        (u) => u.table == 'transactions' || u.table == 'categories',
      );
      if (hasUpdate) {
        _reload();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    super.dispose();
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildQuery() {
    final query = db.select(db.transactions).join([
      innerJoin(
        db.categories,
        db.categories.id.equalsExp(db.transactions.categoryId),
      ),
    ]);

    // Apply Date/Month Filter
    final startOfMonth = DateTime(filters.month.year, filters.month.month, 1);
    final endOfMonth = DateTime(
      filters.month.year,
      filters.month.month + 1,
      0,
      23,
      59,
      59,
    );
    query.where(db.transactions.date.isBetweenValues(startOfMonth, endOfMonth));

    // Apply Type Filter
    if (filters.type != null) {
      query.where(db.transactions.type.equals(filters.type!));
    }

    // Apply Category Filters
    if (filters.categoryIds.isNotEmpty) {
      query.where(db.transactions.categoryId.isIn(filters.categoryIds));
    }

    // Apply Search Filter (SQL LIKE for database matching and avoiding full table scans)
    if (filters.search.isNotEmpty) {
      final searchPattern = '%${filters.search}%';
      query.where(
        db.transactions.note.like(searchPattern) |
            db.categories.name.like(searchPattern),
      );
    }

    // Apply Sorting
    if (filters.sortBy == 'date_desc') {
      query.orderBy([OrderingTerm.desc(db.transactions.date)]);
    } else if (filters.sortBy == 'date_asc') {
      query.orderBy([OrderingTerm.asc(db.transactions.date)]);
    } else if (filters.sortBy == 'amount_desc') {
      query.orderBy([OrderingTerm.desc(db.transactions.amount)]);
    } else {
      query.orderBy([OrderingTerm.asc(db.transactions.amount)]);
    }

    return query;
  }

  Future<List<TransactionWithCategory>> _fetchRange(
    int limit,
    int offset,
  ) async {
    final query = _buildQuery();
    query.limit(limit, offset: offset);
    final rows = await query.get();
    return rows.map((row) {
      return TransactionWithCategory(
        transaction: row.readTable(db.transactions),
        category: row.readTable(db.categories),
      );
    }).toList();
  }

  Future<void> _loadInitial() async {
    try {
      state = const AsyncValue.loading();
      final items = await _fetchRange(30, 0);
      if (_isDisposed) return;
      state = AsyncValue.data(
        PaginatedTransactionsState(
          transactions: items,
          hasMore: items.length == 30,
          isLoadingMore: false,
          offset: items.length,
        ),
      );
    } catch (e, stack) {
      if (_isDisposed) return;
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _reload() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    try {
      final loadCount = currentState.offset > 0 ? currentState.offset : 30;
      final items = await _fetchRange(loadCount, 0);
      if (_isDisposed) return;
      state = AsyncValue.data(
        currentState.copyWith(
          transactions: items,
          hasMore: items.length >= loadCount,
        ),
      );
    } catch (e) {
      // Keep existing data in case of reload error
    }
  }

  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null ||
        !currentState.hasMore ||
        currentState.isLoadingMore) {
      return;
    }

    try {
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

      final nextItems = await _fetchRange(30, currentState.offset);

      if (_isDisposed) return;

      state = AsyncValue.data(
        PaginatedTransactionsState(
          transactions: [...currentState.transactions, ...nextItems],
          hasMore: nextItems.length == 30,
          isLoadingMore: false,
          offset: currentState.offset + nextItems.length,
        ),
      );
    } catch (e) {
      if (_isDisposed) return;
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: false));
    }
  }
}

final paginatedTransactionsProvider =
    StateNotifierProvider.family<
      PaginatedTransactionsNotifier,
      AsyncValue<PaginatedTransactionsState>,
      AppDatabase
    >((ref, db) {
      final filters = ref.watch(transactionFiltersProvider);
      return PaginatedTransactionsNotifier(db, filters);
    });

// A stream provider for recent 5 transactions
final recentTransactionsProvider =
    StreamProvider<List<TransactionWithCategory>>((ref) {
      final db = ref.watch(databaseProvider);
      final query = db.select(db.transactions).join([
        innerJoin(
          db.categories,
          db.categories.id.equalsExp(db.transactions.categoryId),
        ),
      ]);

      query.orderBy([OrderingTerm.desc(db.transactions.date)]);
      query.limit(5);

      return query.watch().map((rows) {
        return rows.map((row) {
          return TransactionWithCategory(
            transaction: row.readTable(db.transactions),
            category: row.readTable(db.categories),
          );
        }).toList();
      });
    });

class TransactionNotifier extends FamilyNotifier<void, AppDatabase> {
  @override
  void build(AppDatabase arg) {}

  Future<void> _checkBudgetAlert(String categoryId, DateTime date) async {
    final settings = ref.read(settingsProvider);
    if (!settings.budgetAlertsEnabled) return;

    final db = arg;

    // Find category name
    final category = await (db.select(
      db.categories,
    )..where((c) => c.id.equals(categoryId))).getSingleOrNull();
    if (category == null) return;

    // Find if budget exists for this month/year
    final budget =
        await (db.select(db.budgets)..where(
              (b) =>
                  b.categoryId.equals(categoryId) &
                  b.month.equals(date.month) &
                  b.year.equals(date.year),
            ))
            .getSingleOrNull();

    if (budget == null) return;

    // Calculate spent in this month
    final startOfMonth = DateTime(date.year, date.month, 1);
    final endOfMonth = DateTime(date.year, date.month + 1, 0, 23, 59, 59);

    final transactionsList =
        await (db.select(db.transactions)..where(
              (t) =>
                  t.categoryId.equals(categoryId) &
                  t.date.isBetweenValues(startOfMonth, endOfMonth) &
                  t.type.equals('expense'),
            ))
            .get();

    final totalSpent = transactionsList.fold<double>(
      0.0,
      (sum, t) => sum + t.amount,
    );

    if (totalSpent >= (budget.limitAmount * budget.alertThreshold)) {
      final double spentPercent = totalSpent / budget.limitAmount;
      await NotificationService().showBudgetAlert(
        categoryName: category.name,
        spentPercent: spentPercent,
      );
    }
  }

  Future<void> addTransaction({
    required double amount,
    required String type, // income | expense
    required String categoryId,
    required DateTime date,
    String? note,
    bool isRecurring = false,
    String? frequency,
  }) async {
    final db = arg;
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: const Uuid().v4(),
            amount: amount,
            type: type,
            categoryId: categoryId,
            date: date,
            note: Value(note),
            isRecurring: Value(isRecurring),
            frequency: Value(frequency),
            createdAt: Value(DateTime.now()),
          ),
        );

    if (type == 'expense') {
      await _checkBudgetAlert(categoryId, date);
    }
  }

  Future<void> updateTransaction({
    required String id,
    required double amount,
    required String type,
    required String categoryId,
    required DateTime date,
    String? note,
    bool isRecurring = false,
    String? frequency,
  }) async {
    final db = arg;
    await (db.update(db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        amount: Value(amount),
        type: Value(type),
        categoryId: Value(categoryId),
        date: Value(date),
        note: Value(note),
        isRecurring: Value(isRecurring),
        frequency: Value(frequency),
      ),
    );

    if (type == 'expense') {
      await _checkBudgetAlert(categoryId, date);
    }
  }

  Future<void> deleteTransaction(String id) async {
    final db = arg;
    await (db.delete(db.transactions)..where((t) => t.id.equals(id))).go();
  }
}

final transactionNotifierProvider =
    NotifierProvider.family<TransactionNotifier, void, AppDatabase>(() {
      return TransactionNotifier();
    });

final transactionDetailProvider =
    StreamProvider.family<TransactionWithCategory, String>((ref, id) {
      final db = ref.watch(databaseProvider);
      final query = db.select(db.transactions).join([
        innerJoin(
          db.categories,
          db.categories.id.equalsExp(db.transactions.categoryId),
        ),
      ])..where(db.transactions.id.equals(id));

      return query.watchSingle().map((row) {
        return TransactionWithCategory(
          transaction: row.readTable(db.transactions),
          category: row.readTable(db.categories),
        );
      });
    });
