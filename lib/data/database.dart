import 'dart:io';
import 'dart:ffi';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqlite3/open.dart';

part 'database.g.dart';

// Tables

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 30)();
  TextColumn get icon => text()(); // Icon key string for Lucide
  TextColumn get color => text()(); // Hex color string
  TextColumn get type => text().customConstraint(
    "NOT NULL CHECK(type IN ('income', 'expense', 'both'))",
  )(); // income | expense | both
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_transactions_category_id', columns: {#categoryId})
@TableIndex(name: 'idx_transactions_date', columns: {#date})
class Transactions extends Table {
  TextColumn get id => text()();
  RealColumn get amount =>
      real().customConstraint('NOT NULL CHECK(amount > 0)')();
  TextColumn get type => text().customConstraint(
    "NOT NULL CHECK(type IN ('income', 'expense'))",
  )(); // income | expense
  TextColumn get categoryId =>
      text().references(Categories, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable().withLength(max: 80)();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get frequency => text().nullable().customConstraint(
    "CHECK(frequency IS NULL OR frequency IN ('daily', 'weekly', 'monthly'))",
  )(); // daily | weekly | monthly
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_budgets_category_id', columns: {#categoryId})
@TableIndex(name: 'idx_budgets_month', columns: {#month})
@TableIndex(name: 'idx_budgets_year', columns: {#year})
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId =>
      text().references(Categories, #id, onDelete: KeyAction.cascade)();
  RealColumn get limitAmount =>
      real().customConstraint('NOT NULL CHECK(limit_amount > 0)')();
  IntColumn get month => integer().customConstraint(
    'NOT NULL CHECK(month >= 1 AND month <= 12)',
  )(); // 1-12
  IntColumn get year =>
      integer().customConstraint('NOT NULL CHECK(year > 0)')();
  RealColumn get alertThreshold => real().customConstraint(
    'NOT NULL DEFAULT 0.80 CHECK(alert_threshold >= 0.5 AND alert_threshold <= 0.9)',
  )(); // 0.5 - 0.9

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {categoryId, month, year},
  ];
}

class SavingsGoals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 40)();
  TextColumn get icon => text()();
  RealColumn get targetAmount =>
      real().customConstraint('NOT NULL CHECK(target_amount > 0)')();
  RealColumn get savedAmount => real().withDefault(const Constant(0.0))();
  DateTimeColumn get deadline => dateTime()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_goal_contributions_goal_id', columns: {#goalId})
@TableIndex(name: 'idx_goal_contributions_date', columns: {#date})
class GoalContributions extends Table {
  TextColumn get id => text()();
  TextColumn get goalId =>
      text().references(SavingsGoals, #id, onDelete: KeyAction.cascade)();
  RealColumn get amount =>
      real().customConstraint('NOT NULL CHECK(amount > 0)')();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Database implementation

@DriftDatabase(
  tables: [Categories, Transactions, Budgets, SavingsGoals, GoalContributions],
)
class AppDatabase extends _$AppDatabase {
  static AppDatabase? _instance;

  factory AppDatabase([QueryExecutor? executor]) {
    if (executor != null) {
      return AppDatabase._internal(executor);
    }
    _instance ??= AppDatabase._internal(_openConnection());
    return _instance!;
  }

  AppDatabase._internal(super.executor);

  @override
  Future<void> close() async {
    await super.close();
    if (_instance == this) {
      _instance = null;
    }
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();

      // Seed default categories
      final uuid = const Uuid();
      final defaultCats = [
        // Expense Categories
        CategoriesCompanion.insert(
          id: uuid.v4(),
          name: 'Food',
          icon: 'restaurant',
          color: '#EF4444', // Red
          type: 'expense',
          isDefault: const Value(true),
        ),
        CategoriesCompanion.insert(
          id: uuid.v4(),
          name: 'Transport',
          icon: 'car',
          color: '#3B82F6', // Blue
          type: 'expense',
          isDefault: const Value(true),
        ),
        CategoriesCompanion.insert(
          id: uuid.v4(),
          name: 'Shopping',
          icon: 'shopping-bag',
          color: '#EC4899', // Pink
          type: 'expense',
          isDefault: const Value(true),
        ),
        CategoriesCompanion.insert(
          id: uuid.v4(),
          name: 'Health',
          icon: 'heart-pulse',
          color: '#10B981', // Emerald
          type: 'expense',
          isDefault: const Value(true),
        ),
        CategoriesCompanion.insert(
          id: uuid.v4(),
          name: 'Entertainment',
          icon: 'tv',
          color: '#8B5CF6', // Purple
          type: 'expense',
          isDefault: const Value(true),
        ),
        CategoriesCompanion.insert(
          id: uuid.v4(),
          name: 'Utilities',
          icon: 'zap',
          color: '#F59E0B', // Amber
          type: 'expense',
          isDefault: const Value(true),
        ),
        CategoriesCompanion.insert(
          id: uuid.v4(),
          name: 'Education',
          icon: 'book-open',
          color: '#06B6D4', // Cyan
          type: 'expense',
          isDefault: const Value(true),
        ),
        CategoriesCompanion.insert(
          id: uuid.v4(),
          name: 'Rent',
          icon: 'home',
          color: '#6B7280', // Gray
          type: 'expense',
          isDefault: const Value(true),
        ),

        // Income Categories
        CategoriesCompanion.insert(
          id: uuid.v4(),
          name: 'Salary',
          icon: 'briefcase',
          color: '#10B981', // Emerald
          type: 'income',
          isDefault: const Value(true),
        ),
        CategoriesCompanion.insert(
          id: uuid.v4(),
          name: 'Savings',
          icon: 'piggy-bank',
          color: '#0D9488', // Teal Accent
          type: 'income',
          isDefault: const Value(true),
        ),
        CategoriesCompanion.insert(
          id: uuid.v4(),
          name: 'Other',
          icon: 'circle-ellipsis',
          color: '#6B7280', // Gray
          type: 'both',
          isDefault: const Value(true),
        ),
      ];

      for (final cat in defaultCats) {
        await into(categories).insert(cat);
      }
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Recreate tables to apply the new CHECK constraints and UNIQUE constraints
        await m.alterTable(TableMigration(categories));
        await m.alterTable(TableMigration(transactions));
        await m.alterTable(TableMigration(budgets));
        await m.alterTable(TableMigration(savingsGoals));
        await m.alterTable(TableMigration(goalContributions));

        // Create indexes
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_transactions_category_id ON transactions (category_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions (date);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_budgets_category_id ON budgets (category_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_budgets_month ON budgets (month);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_budgets_year ON budgets (year);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_goal_contributions_goal_id ON goal_contributions (goal_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_goal_contributions_date ON goal_contributions (date);',
        );
      }
    },
  );
}

Future<String> _getOrResetDbKey() async {
  const storage = FlutterSecureStorage();
  const keyName = 'secure_db_key';
  String? key = await storage.read(key: keyName);
  if (key == null) {
    key = const Uuid().v4();
    await storage.write(key: keyName, value: key);
  }
  return key;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'budgetwise.sqlite'));

    String dbKey;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      dbKey = 'test-key';
    } else {
      dbKey = await _getOrResetDbKey();
    }

    return NativeDatabase.createInBackground(
      file,
      isolateSetup: () async {
        open.overrideFor(OperatingSystem.android, () {
          return DynamicLibrary.open('libsqlcipher.so');
        });
      },
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = '${dbKey.replaceAll("'", "''")}';");
      },
    );
  });
}
