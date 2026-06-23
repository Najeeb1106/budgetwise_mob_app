import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:budgetwise/data/database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('Database Integrity and Migration Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('CHECK constraints on negative/zero amounts', () async {
      // Create a category first
      const categoryId = 'test-cat-1';
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: categoryId,
              name: 'Food',
              icon: 'restaurant',
              color: '#EF4444',
              type: 'expense',
            ),
          );

      // 1. Transaction CHECK(amount > 0)
      expect(
        () => db
            .into(db.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: 'tx-1',
                amount: -10.0, // Invalid amount <= 0
                type: 'expense',
                categoryId: categoryId,
                date: DateTime.now(),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );

      expect(
        () => db
            .into(db.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: 'tx-2',
                amount: 0.0, // Invalid amount <= 0
                type: 'expense',
                categoryId: categoryId,
                date: DateTime.now(),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );

      // 2. Budgets CHECK(limit_amount > 0)
      expect(
        () => db
            .into(db.budgets)
            .insert(
              BudgetsCompanion.insert(
                id: 'budget-1',
                categoryId: categoryId,
                limitAmount: -100.0, // Invalid limit <= 0
                month: 6,
                year: 2026,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );

      // 3. SavingsGoals CHECK(target_amount > 0)
      expect(
        () => db
            .into(db.savingsGoals)
            .insert(
              SavingsGoalsCompanion.insert(
                id: 'goal-1',
                name: 'Holiday',
                icon: '🏖️',
                targetAmount: -50.0, // Invalid target <= 0
                deadline: DateTime.now().add(const Duration(days: 30)),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );

      // 4. GoalContributions CHECK(amount > 0)
      // First insert valid goal
      await db
          .into(db.savingsGoals)
          .insert(
            SavingsGoalsCompanion.insert(
              id: 'goal-2',
              name: 'Car',
              icon: '🚗',
              targetAmount: 5000.0,
              deadline: DateTime.now().add(const Duration(days: 30)),
            ),
          );

      expect(
        () => db
            .into(db.goalContributions)
            .insert(
              GoalContributionsCompanion.insert(
                id: 'contrib-1',
                goalId: 'goal-2',
                amount: 0.0, // Invalid amount <= 0
                date: DateTime.now(),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('UNIQUE(categoryId, month, year) constraint on Budgets', () async {
      const categoryId = 'test-cat-unique';
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: categoryId,
              name: 'Food',
              icon: 'restaurant',
              color: '#EF4444',
              type: 'expense',
            ),
          );

      // First budget for category-month-year
      await db
          .into(db.budgets)
          .insert(
            BudgetsCompanion.insert(
              id: 'budget-unique-1',
              categoryId: categoryId,
              limitAmount: 500.0,
              month: 6,
              year: 2026,
            ),
          );

      // Second budget for same category-month-year should throw UNIQUE constraint exception
      expect(
        () => db
            .into(db.budgets)
            .insert(
              BudgetsCompanion.insert(
                id: 'budget-unique-2',
                categoryId: categoryId,
                limitAmount: 600.0,
                month: 6,
                year: 2026,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test(
      'Migration v1 -> v2 preserves data and implements new constraints',
      () async {
        final dbFile = File('migration_test_temp.db');
        if (dbFile.existsSync()) {
          dbFile.deleteSync();
        }

        // Step 1: Open raw sqlite database and construct version 1 layout
        final rawSqliteDb = sqlite3.open(dbFile.path);

        // Set user_version pragma to 1
        rawSqliteDb.execute('PRAGMA user_version = 1;');

        // Create v1 tables manually
        rawSqliteDb.execute('''
        CREATE TABLE categories (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          icon TEXT NOT NULL,
          color TEXT NOT NULL,
          type TEXT NOT NULL,
          is_default BOOLEAN NOT NULL DEFAULT 0
        );
      ''');
        rawSqliteDb.execute('''
        CREATE TABLE transactions (
          id TEXT NOT NULL PRIMARY KEY,
          amount REAL NOT NULL,
          type TEXT NOT NULL,
          category_id TEXT NOT NULL REFERENCES categories (id) ON DELETE CASCADE,
          date INTEGER NOT NULL,
          note TEXT,
          is_recurring BOOLEAN NOT NULL DEFAULT 0,
          frequency TEXT,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        );
      ''');
        rawSqliteDb.execute('''
        CREATE TABLE budgets (
          id TEXT NOT NULL PRIMARY KEY,
          category_id TEXT NOT NULL REFERENCES categories (id) ON DELETE CASCADE,
          limit_amount REAL NOT NULL,
          month INTEGER NOT NULL,
          year INTEGER NOT NULL,
          alert_threshold REAL NOT NULL DEFAULT 0.80
        );
      ''');
        rawSqliteDb.execute('''
        CREATE TABLE savings_goals (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          icon TEXT NOT NULL,
          target_amount REAL NOT NULL,
          saved_amount REAL NOT NULL DEFAULT 0.0,
          deadline INTEGER NOT NULL,
          notes TEXT,
          is_completed BOOLEAN NOT NULL DEFAULT 0
        );
      ''');
        rawSqliteDb.execute('''
        CREATE TABLE goal_contributions (
          id TEXT NOT NULL PRIMARY KEY,
          goal_id TEXT NOT NULL REFERENCES savings_goals (id) ON DELETE CASCADE,
          amount REAL NOT NULL,
          date INTEGER NOT NULL,
          note TEXT
        );
      ''');

        // Seed v1 mock data
        const catId = 'mig-cat-1';
        rawSqliteDb.execute(
          "INSERT INTO categories (id, name, icon, color, type) VALUES ('$catId', 'Utilities', 'zap', '#F59E0B', 'expense');",
        );
        rawSqliteDb.execute(
          "INSERT INTO budgets (id, category_id, limit_amount, month, year) VALUES ('mig-bud-1', '$catId', 120.0, 6, 2026);",
        );
        rawSqliteDb.execute(
          "INSERT INTO transactions (id, amount, type, category_id, date) VALUES ('mig-tx-1', 45.0, 'expense', '$catId', 1718712000);",
        );

        // Close raw sqlite connection
        rawSqliteDb.dispose();

        // Step 2: Open database using Drift AppDatabase (which is version 2)
        final v2Executor = NativeDatabase(dbFile);
        final upgradeDb = AppDatabase(v2Executor);

        // Perform query to trigger onUpgrade migration sequence
        final list = await upgradeDb.select(upgradeDb.categories).get();
        expect(list.length, equals(1));
        expect(list.first.name, equals('Utilities'));

        final budget = await upgradeDb.select(upgradeDb.budgets).get();
        expect(budget.length, equals(1));
        expect(budget.first.limitAmount, equals(120.0));

        final tx = await upgradeDb.select(upgradeDb.transactions).get();
        expect(tx.length, equals(1));
        expect(tx.first.amount, equals(45.0));

        // Assert UNIQUE constraint is active on Budgets
        expect(
          () => upgradeDb
              .into(upgradeDb.budgets)
              .insert(
                BudgetsCompanion.insert(
                  id: 'mig-bud-duplicate',
                  categoryId: catId,
                  limitAmount: 150.0,
                  month: 6,
                  year: 2026, // Same category-month-year
                ),
              ),
          throwsA(isA<SqliteException>()),
        );

        // Assert CHECK constraints are active
        expect(
          () => upgradeDb
              .into(upgradeDb.transactions)
              .insert(
                TransactionsCompanion.insert(
                  id: 'mig-tx-invalid',
                  amount: 0.0, // Invalid CHECK constraint
                  type: 'expense',
                  categoryId: catId,
                  date: DateTime.now(),
                ),
              ),
          throwsA(isA<SqliteException>()),
        );

        // Cleanup
        await upgradeDb.close();
        if (dbFile.existsSync()) {
          dbFile.deleteSync();
        }
      },
    );
  });
}
