import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgetwise/providers/settings_provider.dart';
import 'package:budgetwise/screens/security/app_lock_guard.dart';

void main() {
  group('App Lock Guard Widget Tests', () {
    testWidgets('Does not lock if biometric lock is disabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override settings to have biometric disabled and onboarding complete
            settingsProvider.overrideWith((ref) {
              return SettingsNotifierMock(
                AppSettings(
                  username: 'User',
                  currency: 'USD',
                  themeMode: 'system',
                  estimatedIncome: 5000.0,
                  includeSalaryInBalance: true,
                  isOnboardingComplete: true,
                  biometricEnabled: false,
                ),
              );
            }),
          ],
          child: const AppLockGuard(
            child: MaterialApp(
              home: Scaffold(body: Text('Sensitive Dashboard Data')),
            ),
          ),
        ),
      );

      // Verify dashboard content is visible
      expect(find.text('Sensitive Dashboard Data'), findsOneWidget);
      expect(find.text('App Locked'), findsNothing);

      // Simulate app moving to background and returning to foreground
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Verify it is STILL unlocked (dashboard content visible)
      expect(find.text('Sensitive Dashboard Data'), findsOneWidget);
      expect(find.text('App Locked'), findsNothing);
    });

    testWidgets('Enforces App Lock overlay when biometric is enabled on resume', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override settings to have biometric enabled and onboarding complete
            settingsProvider.overrideWith((ref) {
              return SettingsNotifierMock(
                AppSettings(
                  username: 'User',
                  currency: 'USD',
                  themeMode: 'system',
                  estimatedIncome: 5000.0,
                  includeSalaryInBalance: true,
                  isOnboardingComplete: true,
                  biometricEnabled: true,
                ),
              );
            }),
          ],
          child: const AppLockGuard(
            child: MaterialApp(
              home: Scaffold(body: Text('Sensitive Dashboard Data')),
            ),
          ),
        ),
      );

      // Initially visible
      expect(find.text('Sensitive Dashboard Data'), findsOneWidget);
      expect(find.text('App Locked'), findsNothing);

      // Simulate moving to background (paused)
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();

      // Verify overlay is now blocking and visible
      expect(find.text('App Locked'), findsOneWidget);
      expect(find.text('Sensitive Dashboard Data'), findsNothing);

      // Simulate returning to foreground (resumed)
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // It must remain locked until successful authentication
      expect(find.text('App Locked'), findsOneWidget);
      expect(find.text('Sensitive Dashboard Data'), findsNothing);
    });
  });
}

class SettingsNotifierMock extends SettingsNotifier {
  final AppSettings mockSettings;

  SettingsNotifierMock(this.mockSettings);

  @override
  AppSettings get state => mockSettings;

  @override
  set state(AppSettings value) {}
}
