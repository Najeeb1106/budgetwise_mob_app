import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main_shell.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/budget/budgets_screen.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/goal/goals_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/transaction/transaction_list_screen.dart';
import 'screens/transaction/transaction_detail_screen.dart';
import 'screens/goal/goal_detail_screen.dart';
import 'screens/settings/category_manager_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellHomeNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final GlobalKey<NavigatorState> _shellBudgetsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellBudgets');
final GlobalKey<NavigatorState> _shellAnalyticsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellAnalytics');
final GlobalKey<NavigatorState> _shellGoalsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellGoals');

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Stateful Shell Route for Bottom Nav preserving state
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellHomeNavigatorKey,
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellBudgetsNavigatorKey,
          routes: [
            GoRoute(
              path: '/budgets',
              builder: (context, state) => const BudgetsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellAnalyticsNavigatorKey,
          routes: [
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellGoalsNavigatorKey,
          routes: [
            GoRoute(
              path: '/goals',
              builder: (context, state) => const GoalsScreen(),
            ),
          ],
        ),
      ],
    ),

    // Sub-route for Settings, accessible from any screen
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),

    // Sub-route for Category Manager
    GoRoute(
      path: '/settings/categories',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CategoryManagerScreen(),
    ),

    // Full screen history list
    GoRoute(
      path: '/transactions',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TransactionListScreen(),
    ),

    // Full screen detail view
    GoRoute(
      path: '/transaction/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TransactionDetailScreen(transactionId: id);
      },
    ),

    // Goal Detail Screen route
    GoRoute(
      path: '/goal/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return GoalDetailScreen(goalId: id);
      },
    ),
  ],
);
