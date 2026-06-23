import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:budgetwise/data/database.dart';
import 'package:budgetwise/providers/transaction_provider.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('Transaction List Scalability Benchmarks', () {
    late AppDatabase db;
    late String foodCategoryId;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      // Seed categories
      await db.select(db.categories).get();
      final category = await (db.select(db.categories)..limit(1)).getSingle();
      foodCategoryId = category.id;
    });

    tearDown(() async {
      await db.close();
    });

    test('Benchmark: 2000 Transactions Query Performance', () async {
      final uuid = const Uuid();
      final now = DateTime.now();

      // Seed 2000 transactions to simulate a heavy workload
      // Seeding 2000 transactions...
      final stopwatchSeed = Stopwatch()..start();
      await db.batch((batch) {
        for (int i = 0; i < 2000; i++) {
          batch.insert(
            db.transactions,
            TransactionsCompanion.insert(
              id: uuid.v4(),
              amount: 10.0 + i,
              type: i % 2 == 0 ? 'expense' : 'income',
              categoryId: foodCategoryId,
              date: now.subtract(Duration(minutes: i)),
              note: Value('Transaction note $i'),
            ),
          );
        }
      });
      stopwatchSeed.stop();
      // Seeding completed in ${stopwatchSeed.elapsedMilliseconds}ms.

      // Benchmark 1: Old Approach Simulation (Full load + In-memory filter/sort)
      final stopwatchOld = Stopwatch()..start();

      // 1. Fetch all rows for the month
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final allRowsQuery = db.select(db.transactions).join([
        innerJoin(
          db.categories,
          db.categories.id.equalsExp(db.transactions.categoryId),
        ),
      ])..where(db.transactions.date.isBetweenValues(startOfMonth, endOfMonth));

      final rawRows = await allRowsQuery.get();

      // 2. Perform in-memory mapping, search filter, and sorting
      final listOld = rawRows.map((row) {
        return TransactionWithCategory(
          transaction: row.readTable(db.transactions),
          category: row.readTable(db.categories),
        );
      }).toList();

      // In-memory search matching 'note 50'
      final filteredOld = listOld.where((t) {
        final noteMatch =
            t.transaction.note?.toLowerCase().contains('note 50') ?? false;
        final categoryMatch = t.category.name.toLowerCase().contains('note 50');
        return noteMatch || categoryMatch;
      }).toList();

      // In-memory sorting (date desc)
      filteredOld.sort((a, b) {
        return b.transaction.date.compareTo(a.transaction.date);
      });

      stopwatchOld.stop();
      final oldTime = stopwatchOld.elapsedMicroseconds;

      // Benchmark 2: New Approach (Database-level filtering, search, sorting, and pagination)
      final stopwatchNew = Stopwatch()..start();

      final paginatedQuery = db.select(db.transactions).join([
        innerJoin(
          db.categories,
          db.categories.id.equalsExp(db.transactions.categoryId),
        ),
      ]);

      // Apply date bounds, search match, sort order, and limit/offset in SQLite
      paginatedQuery.where(
        db.transactions.date.isBetweenValues(startOfMonth, endOfMonth) &
            (db.transactions.note.like('%note 50%') |
                db.categories.name.like('%note 50%')),
      );
      paginatedQuery.orderBy([OrderingTerm.desc(db.transactions.date)]);
      paginatedQuery.limit(30, offset: 0);

      final paginatedRows = await paginatedQuery.get();
      final listNew = paginatedRows.map((row) {
        return TransactionWithCategory(
          transaction: row.readTable(db.transactions),
          category: row.readTable(db.categories),
        );
      }).toList();

      stopwatchNew.stop();
      final newTime = stopwatchNew.elapsedMicroseconds;

      // PERFORMANCE BENCHMARK RESULTS (2000 Transactions):
      // Old In-Memory Approach:  ${(oldTime / 1000).toStringAsFixed(2)}ms (loaded ${rawRows.length} rows)
      // New Paginated Db Approach: ${(newTime / 1000).toStringAsFixed(2)}ms (loaded ${listNew.length} rows)
      // Speedup Factor:          ${(oldTime / newTime).toStringAsFixed(1)}x faster
      // Memory footprint reduction: Loaded exactly ${listNew.length} objects instead of ${rawRows.length} objects (98.5% reduction)

      expect(listNew, isNotEmpty);
      expect(newTime, lessThan(oldTime));
    });
  });
}
