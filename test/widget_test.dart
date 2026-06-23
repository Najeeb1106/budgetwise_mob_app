import 'package:flutter_test/flutter_test.dart';
import 'package:budgetwise/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App compiles and launches successfully smoke test', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Settle all animations and delayed navigations from the splash screen
    await tester.pumpAndSettle(const Duration(milliseconds: 2000));

    // Verify that our app main structure loaded
    expect(find.byType(MyApp), findsOneWidget);
  });
}
