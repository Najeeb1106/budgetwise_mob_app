import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:budgetwise/providers/database_provider.dart';
import 'package:budgetwise/screens/goal/goal_detail_screen.dart';
import 'package:budgetwise/data/database.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:google_fonts/google_fonts.dart';

class FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getTemporaryPath() async => '.';

  @override
  Future<String?> getApplicationSupportPath() async => '.';

  @override
  Future<String?> getLibraryPath() async => '.';

  @override
  Future<String?> getApplicationDocumentsPath() async => '.';

  @override
  Future<String?> getExternalStoragePath() async => '.';

  @override
  Future<List<String>?> getExternalCachePaths() async => ['.'];

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async => ['.'];

  @override
  Future<String?> getDownloadsPath() async => '.';
}

void main() {
  group('Savings Goal Editing SQA Tests', () {
    late AppDatabase db;

    setUp(() {
      GoogleFonts.config.allowRuntimeFetching = false;
      PathProviderPlatform.instance = FakePathProviderPlatform();
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'Pre-fills fields, updates database and UI reactively (excluding Initial Saved)',
      (WidgetTester tester) async {
        await runZonedGuarded(
          () async {
            const goalId = 'test-goal-edit-1';
            final deadlineDate = DateTime(2026, 7, 18, 12, 0);

            // Seed an initial savings goal
            await db
                .into(db.savingsGoals)
                .insert(
                  SavingsGoalsCompanion.insert(
                    id: goalId,
                    name: 'Original Goal',
                    icon: '💰',
                    targetAmount: 1000.0,
                    savedAmount: const Value(250.0),
                    deadline: deadlineDate,
                    notes: const Value('Original notes for goal'),
                    isCompleted: const Value(false),
                  ),
                );

            final router = GoRouter(
              initialLocation: '/goal/$goalId',
              routes: [
                GoRoute(
                  path: '/goal/:id',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return GoalDetailScreen(goalId: id);
                  },
                ),
              ],
            );

            await tester.pumpWidget(
              ProviderScope(
                overrides: [databaseProvider.overrideWithValue(db)],
                child: MaterialApp.router(routerConfig: router),
              ),
            );

            // Allow streams to load
            await tester.pumpAndSettle();

            // Verify initial details displayed
            expect(find.text('Original Goal'), findsOneWidget);
            expect(find.text('Notes: Original notes for goal'), findsOneWidget);

            // Locate and tap the edit button in AppBar
            final editBtn = find.byKey(const Key('edit_goal_button'));
            expect(editBtn, findsOneWidget);
            await tester.tap(editBtn);
            await tester.pumpAndSettle();

            // Verify prefilled form values inside AddGoalSheet
            final nameField = find.descendant(
              of: find.byType(TextFormField),
              matching: find.text('Original Goal'),
            );
            expect(nameField, findsOneWidget);

            final targetField = find.descendant(
              of: find.byType(TextFormField),
              matching: find.text('1000.0'),
            );
            expect(targetField, findsOneWidget);

            // Initial Saved field must be hidden/excluded in edit mode
            final initialSavedField = find.text('Initial Saved (Opt)');
            expect(initialSavedField, findsNothing);

            // Edit fields
            await tester.enterText(nameField, 'Updated Goal Name');
            await tester.enterText(targetField, '1500.0');
            await tester.pumpAndSettle();

            // Tap Save Changes
            final saveBtn = find.text('Save Changes');
            expect(saveBtn, findsOneWidget);
            await tester.tap(saveBtn);
            await tester.pumpAndSettle();

            // Verify database updated
            final updatedGoal = await (db.select(
              db.savingsGoals,
            )..where((g) => g.id.equals(goalId))).getSingle();

            expect(updatedGoal.name, equals('Updated Goal Name'));
            expect(updatedGoal.targetAmount, equals(1500.0));
            // Verify savedAmount was preserved
            expect(updatedGoal.savedAmount, equals(250.0));

            // Verify detail screen refreshed reactively
            expect(find.text('Updated Goal Name'), findsOneWidget);
            expect(find.text('Original Goal'), findsNothing);

            // Cleanup
            await tester.pumpWidget(const SizedBox());
            await tester.pumpAndSettle();
          },
          (error, stack) {
            if (error.toString().contains('Failed to load font') ||
                error.toString().contains('allowRuntimeFetching')) {
              return;
            }
            throw error;
          },
        );
      },
    );
  });
}
