import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../data/database.dart';
import 'database_provider.dart';
import 'settings_provider.dart';
import '../services/notification_service.dart';

final savingsGoalsStreamProvider = StreamProvider<List<SavingsGoal>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.savingsGoals).watch();
});

class GoalWithContributions {
  final SavingsGoal goal;
  final List<GoalContribution> contributions;

  GoalWithContributions({required this.goal, required this.contributions});
}

final goalDetailStreamProvider =
    StreamProvider.family<GoalWithContributions, String>((ref, goalId) {
      final db = ref.watch(databaseProvider);

      final goalQuery = db.select(db.savingsGoals)
        ..where((g) => g.id.equals(goalId));
      final contributionsQuery = db.select(db.goalContributions)
        ..where((c) => c.goalId.equals(goalId));

      return goalQuery.watchSingle().asyncMap((goal) async {
        final contributions = await contributionsQuery.get();
        return GoalWithContributions(goal: goal, contributions: contributions);
      });
    });

class GoalNotifier extends FamilyNotifier<void, AppDatabase> {
  @override
  void build(AppDatabase arg) {}

  Future<void> _scheduleReminder(SavingsGoal goal) async {
    final settings = ref.read(settingsProvider);
    if (!settings.goalRemindersEnabled || goal.isCompleted) return;
    await NotificationService().scheduleGoalDeadlineReminder(goal);
  }

  Future<void> _cancelReminder(String goalId) async {
    await NotificationService().cancelGoalReminder(goalId);
  }

  Future<void> addGoal({
    required String name,
    required String icon,
    required double targetAmount,
    required double initialSavedAmount,
    required DateTime deadline,
    String? notes,
  }) async {
    final db = arg;
    final goalId = const Uuid().v4();
    final isCompleted = initialSavedAmount >= targetAmount;

    await db
        .into(db.savingsGoals)
        .insert(
          SavingsGoalsCompanion.insert(
            id: goalId,
            name: name,
            icon: icon,
            targetAmount: targetAmount,
            savedAmount: Value(initialSavedAmount),
            deadline: deadline,
            notes: Value(notes),
            isCompleted: Value(isCompleted),
          ),
        );

    // If initial savings are provided, create an initial contribution record
    if (initialSavedAmount > 0) {
      await db
          .into(db.goalContributions)
          .insert(
            GoalContributionsCompanion.insert(
              id: const Uuid().v4(),
              goalId: goalId,
              amount: initialSavedAmount,
              date: DateTime.now(),
              note: const Value('Initial Savings'),
            ),
          );
    }

    final newGoal = SavingsGoal(
      id: goalId,
      name: name,
      icon: icon,
      targetAmount: targetAmount,
      savedAmount: initialSavedAmount,
      deadline: deadline,
      notes: notes,
      isCompleted: isCompleted,
    );
    await _scheduleReminder(newGoal);
  }

  Future<void> updateGoal({
    required String id,
    required String name,
    required String icon,
    required double targetAmount,
    required DateTime deadline,
    String? notes,
  }) async {
    final db = arg;

    // Retrieve existing to re-verify completion
    final goalQuery = db.select(db.savingsGoals)..where((g) => g.id.equals(id));
    final existing = await goalQuery.getSingle();
    final isCompleted = existing.savedAmount >= targetAmount;

    await (db.update(db.savingsGoals)..where((g) => g.id.equals(id))).write(
      SavingsGoalsCompanion(
        name: Value(name),
        icon: Value(icon),
        targetAmount: Value(targetAmount),
        deadline: Value(deadline),
        notes: Value(notes),
        isCompleted: Value(isCompleted),
      ),
    );

    final updatedGoal = SavingsGoal(
      id: id,
      name: name,
      icon: icon,
      targetAmount: targetAmount,
      savedAmount: existing.savedAmount,
      deadline: deadline,
      notes: notes,
      isCompleted: isCompleted,
    );

    if (isCompleted) {
      await _cancelReminder(id);
    } else {
      await _scheduleReminder(updatedGoal);
    }
  }

  Future<void> deleteGoal(String id) async {
    final db = arg;
    await _cancelReminder(id);
    await (db.delete(db.savingsGoals)..where((g) => g.id.equals(id))).go();
  }

  Future<void> addContribution({
    required String goalId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final db = arg;

    // 1. Insert contribution record
    await db
        .into(db.goalContributions)
        .insert(
          GoalContributionsCompanion.insert(
            id: const Uuid().v4(),
            goalId: goalId,
            amount: amount,
            date: date,
            note: Value(note),
          ),
        );

    // 2. Fetch all contributions for this goal and recalculate savedAmount
    final contributionsQuery = db.select(db.goalContributions)
      ..where((c) => c.goalId.equals(goalId));
    final list = await contributionsQuery.get();
    final totalSaved = list.fold<double>(0.0, (sum, item) => sum + item.amount);

    // 3. Fetch goal details to check targets
    final goalQuery = db.select(db.savingsGoals)
      ..where((g) => g.id.equals(goalId));
    final goal = await goalQuery.getSingle();
    final isCompleted = totalSaved >= goal.targetAmount;

    // 4. Update the goal with new amount
    await (db.update(db.savingsGoals)..where((g) => g.id.equals(goalId))).write(
      SavingsGoalsCompanion(
        savedAmount: Value(totalSaved),
        isCompleted: Value(isCompleted),
      ),
    );

    if (isCompleted) {
      await _cancelReminder(goalId);
    } else {
      final updatedGoal = goal.copyWith(
        savedAmount: totalSaved,
        isCompleted: isCompleted,
      );
      await _scheduleReminder(updatedGoal);
    }
  }

  Future<void> deleteContribution({
    required String contributionId,
    required String goalId,
  }) async {
    final db = arg;

    // 1. Delete contribution
    await (db.delete(
      db.goalContributions,
    )..where((c) => c.id.equals(contributionId))).go();

    // 2. Recalculate contributions
    final contributionsQuery = db.select(db.goalContributions)
      ..where((c) => c.goalId.equals(goalId));
    final list = await contributionsQuery.get();
    final totalSaved = list.fold<double>(0.0, (sum, item) => sum + item.amount);

    // 3. Fetch goal details
    final goalQuery = db.select(db.savingsGoals)
      ..where((g) => g.id.equals(goalId));
    final goal = await goalQuery.getSingle();
    final isCompleted = totalSaved >= goal.targetAmount;

    // 4. Update goal
    await (db.update(db.savingsGoals)..where((g) => g.id.equals(goalId))).write(
      SavingsGoalsCompanion(
        savedAmount: Value(totalSaved),
        isCompleted: Value(isCompleted),
      ),
    );

    if (isCompleted) {
      await _cancelReminder(goalId);
    } else {
      final updatedGoal = goal.copyWith(
        savedAmount: totalSaved,
        isCompleted: isCompleted,
      );
      await _scheduleReminder(updatedGoal);
    }
  }
}

final goalNotifierProvider =
    NotifierProvider.family<GoalNotifier, void, AppDatabase>(() {
      return GoalNotifier();
    });
