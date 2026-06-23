import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/native.dart';
import 'package:budgetwise/providers/database_provider.dart';
import 'package:budgetwise/providers/transaction_provider.dart';
import 'package:budgetwise/screens/settings/settings_screen.dart';
import 'package:budgetwise/utils/csv_exporter.dart';
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
  group('CSV Export Tests', () {
    late AppDatabase db;

    setUp(() {
      GoogleFonts.config.allowRuntimeFetching = false;
      PathProviderPlatform.instance = FakePathProviderPlatform();
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('CsvExporter correctly escapes CSV values and formats fields', () {
      final category = Category(
        id: 'cat-1',
        name: 'Dining Out, Coffee & Fast Food', // Contains comma
        icon: 'coffee',
        color: '#FF0000',
        type: 'expense',
        isDefault: false,
      );

      final tx = Transaction(
        id: 'tx-1',
        amount: 25.50,
        type: 'expense',
        categoryId: 'cat-1',
        date: DateTime(2026, 6, 18, 12, 0),
        note:
            'Pizza "Super" Treat\nWith double cheese', // Contains quotes and newline
        isRecurring: false,
        createdAt: DateTime.now(),
      );

      final items = [
        TransactionWithCategory(transaction: tx, category: category),
      ];

      final csv = CsvExporter.generateCsv(items);

      // Verify header
      expect(csv, contains('Date,Category,Amount,Type,Notes\n'));

      // Verify correct row and escaping
      // Date: 2026-06-18
      // Category: "Dining Out, Coffee & Fast Food"
      // Amount: 25.50
      // Type: expense
      // Note: "Pizza ""Super"" Treat\nWith double cheese"
      expect(
        csv,
        contains(
          '2026-06-18,"Dining Out, Coffee & Fast Food",25.50,expense,"Pizza ""Super"" Treat\nWith double cheese"',
        ),
      );
    });

    testWidgets('Tapping Export to CSV opens dialog and runs export workflow', (
      WidgetTester tester,
    ) async {
      await runZonedGuarded(
        () async {
          final router = GoRouter(
            initialLocation: '/settings',
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [databaseProvider.overrideWithValue(db)],
              child: MaterialApp.router(routerConfig: router),
            ),
          );

          await tester.pumpAndSettle();

          // Find and tap the Export to CSV tile
          final exportTile = find.byKey(const Key('export_csv_tile'));
          expect(exportTile, findsOneWidget);
          await tester.tap(exportTile);
          await tester.pumpAndSettle();

          // Verify confirmation dialog shows up
          expect(find.text('Export Transactions'), findsOneWidget);
          expect(
            find.text(
              'Are you sure you want to export all transactions as a CSV file?',
            ),
            findsOneWidget,
          );

          // Tap the confirmation Export button
          final confirmBtn = find.byKey(const Key('export_confirm_button'));
          expect(confirmBtn, findsOneWidget);
          await tester.tap(confirmBtn);
          await tester.pumpAndSettle();

          // Should return to Settings and trigger SnackBar (since sharing runs in test, it writes the file and completes)
          expect(find.text('Export Transactions'), findsNothing);

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
    });
  });
}
