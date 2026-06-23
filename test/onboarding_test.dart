import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/native.dart';
import 'package:budgetwise/providers/database_provider.dart';
import 'package:budgetwise/screens/onboarding/onboarding_screen.dart';
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
  group('Onboarding SQA Category Persistence Tests', () {
    late AppDatabase db;

    setUp(() {
      GoogleFonts.config.allowRuntimeFetching = false;
      PathProviderPlatform.instance = FakePathProviderPlatform();
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('Step 3 deselected categories are removed from DB on completion', (
      WidgetTester tester,
    ) async {
      await runZonedGuarded(
        () async {
          final router = GoRouter(
            initialLocation: '/onboarding',
            routes: [
              GoRoute(
                path: '/onboarding',
                builder: (context, state) => const OnboardingScreen(),
              ),
              GoRoute(
                path: '/home',
                builder: (context, state) =>
                    const Scaffold(body: Text('Home Screen')),
              ),
            ],
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [databaseProvider.overrideWithValue(db)],
              child: MaterialApp.router(routerConfig: router),
            ),
          );

          expect(find.text("What should we call you?"), findsOneWidget);

          // --- Step 1: Input Profile Name ---
          final nameField = find.byWidgetPredicate(
            (widget) =>
                widget is TextField &&
                widget.decoration?.hintText == "Your Name",
          );
          expect(nameField, findsOneWidget);
          await tester.enterText(nameField, "QA Tester");

          // Tap Continue inside Form 1
          final continueBtn1 = find.byKey(const Key('continue_button_step1'));
          expect(continueBtn1, findsOneWidget);
          await tester.tap(continueBtn1);
          await tester.pumpAndSettle();

          // --- Step 2: Currency & Income ---
          expect(find.text("Income & Currency"), findsOneWidget);
          final incomeField = find.byWidgetPredicate(
            (widget) =>
                widget is TextField &&
                widget.decoration?.labelText == "Estimated Monthly Income",
          );
          expect(incomeField, findsOneWidget);
          await tester.enterText(incomeField, "6000");

          // Tap Continue inside Form 2
          final continueBtn2 = find.byKey(const Key('continue_button_step2'));
          expect(continueBtn2, findsOneWidget);
          await tester.tap(continueBtn2);
          await tester.pumpAndSettle();

          // --- Step 3: Default Categories Selection ---
          expect(find.text("Default Categories"), findsOneWidget);

          var dbCategories = await db.select(db.categories).get();
          expect(dbCategories.length, equals(11));

          final healthChip = find.widgetWithText(ChoiceChip, "Health");
          final utilitiesChip = find.widgetWithText(ChoiceChip, "Utilities");

          expect(healthChip, findsOneWidget);
          expect(utilitiesChip, findsOneWidget);

          await tester.tap(healthChip);
          await tester.tap(utilitiesChip);
          await tester.pumpAndSettle();

          // Tap "Get Started" to complete onboarding
          final getStartedBtn = find.byKey(const Key('get_started_button'));
          expect(getStartedBtn, findsOneWidget);
          await tester.tap(getStartedBtn);
          await tester.pumpAndSettle();

          // Verify routing transitioned to Home Screen
          expect(find.text("Home Screen"), findsOneWidget);

          // --- Verification of Database State ---
          dbCategories = await db.select(db.categories).get();

          // The 2 deselected categories (Health, Utilities) should have been deleted, leaving 9 categories (8 other defaults + "Other")
          expect(dbCategories.length, equals(9));

          // Verify "Health" and "Utilities" are no longer present in DB
          final healthExists = dbCategories.any((c) => c.name == "Health");
          final utilitiesExists = dbCategories.any(
            (c) => c.name == "Utilities",
          );
          expect(healthExists, isFalse);
          expect(utilitiesExists, isFalse);

          // Verify "Food" and "Transport" (which were left selected) are still present in DB
          final foodExists = dbCategories.any((c) => c.name == "Food");
          final transportExists = dbCategories.any(
            (c) => c.name == "Transport",
          );
          expect(foodExists, isTrue);
          expect(transportExists, isTrue);
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
