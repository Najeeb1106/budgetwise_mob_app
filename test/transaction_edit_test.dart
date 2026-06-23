import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:budgetwise/providers/database_provider.dart';
import 'package:budgetwise/screens/transaction/transaction_detail_screen.dart';
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
  group('Transaction Editing SQA Tests', () {
    late AppDatabase db;

    setUp(() {
      GoogleFonts.config.allowRuntimeFetching = false;
      PathProviderPlatform.instance = FakePathProviderPlatform();
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('Pre-fills fields, updates database and UI reactively', (
      WidgetTester tester,
    ) async {
      await runZonedGuarded(
        () async {
          // Trigger DB creation and retrieve first category
          await db.select(db.categories).get();
          final category = await (db.select(
            db.categories,
          )..limit(1)).getSingle();

          // Seed an initial transaction
          const transactionId = 'test-tx-edit-1';
          final initialDate = DateTime(2026, 6, 18, 12, 0);
          await db
              .into(db.transactions)
              .insert(
                TransactionsCompanion.insert(
                  id: transactionId,
                  amount: 50.0,
                  type: 'expense',
                  categoryId: category.id,
                  date: initialDate,
                  note: const Value('Original Note'),
                ),
              );

          final router = GoRouter(
            initialLocation: '/transaction/$transactionId',
            routes: [
              GoRoute(
                path: '/transaction/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return TransactionDetailScreen(transactionId: id);
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
          expect(find.text('-USD 50.00'), findsOneWidget);
          expect(find.text('Original Note'), findsOneWidget);

          // Locate and tap the edit button in AppBar
          final editBtn = find.byKey(const Key('edit_transaction_button'));
          expect(editBtn, findsOneWidget);
          await tester.tap(editBtn);
          await tester.pumpAndSettle();

          // Verify prefilled form values inside AddTransactionSheet
          final amountField = find.descendant(
            of: find.byType(TextFormField),
            matching: find.text('50.0'),
          );
          expect(amountField, findsOneWidget);

          final noteField = find.descendant(
            of: find.byType(TextFormField),
            matching: find.text('Original Note'),
          );
          expect(noteField, findsOneWidget);

          // Edit amount and note
          await tester.enterText(amountField, '125.50');
          await tester.enterText(noteField, 'New Updated Note');
          await tester.pumpAndSettle();

          // Tap Save
          final saveBtn = find.text('Save');
          expect(saveBtn, findsOneWidget);
          await tester.tap(saveBtn);
          await tester.pumpAndSettle();

          // Verify database updated
          final updatedTx = await (db.select(
            db.transactions,
          )..where((t) => t.id.equals(transactionId))).getSingle();

          expect(updatedTx.amount, equals(125.50));
          expect(updatedTx.note, equals('New Updated Note'));

          // Verify detail screen refreshed reactively
          expect(find.text('-USD 125.50'), findsOneWidget);
          expect(find.text('New Updated Note'), findsOneWidget);
          expect(find.text('Original Note'), findsNothing);

          // Load an empty widget to force unmounting and disposal of the ProviderScope and DB streams
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        },
        (error, stack) {
          if (error.toString().contains('Failed to load font') ||
              error.toString().contains('allowRuntimeFetching')) {
            // Ignored Google Fonts exception in test zone
            return;
          }
          throw error;
        },
      );
    });
  });
}
