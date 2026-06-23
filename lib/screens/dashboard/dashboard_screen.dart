import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../providers/settings_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/transaction_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Color _getSemanticColor(double percentage, bool isDark) {
    if (percentage < 0.70) {
      return isDark
          ? const Color(0xFF34D399)
          : const Color(0xFF0D7A57); // High contrast green
    }
    if (percentage <= 0.90) {
      return isDark
          ? const Color(0xFFFBBF24)
          : const Color(0xFFA35200); // High contrast amber
    }
    return isDark
        ? const Color(0xFFF87171)
        : const Color(0xFFD01C1C); // High contrast red
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'restaurant':
        return LucideIcons.utensils;
      case 'car':
        return LucideIcons.car;
      case 'shopping-bag':
        return LucideIcons.shoppingBag;
      case 'heart-pulse':
        return LucideIcons.heartPulse;
      case 'tv':
        return LucideIcons.tv;
      case 'zap':
        return LucideIcons.zap;
      case 'book-open':
        return LucideIcons.bookOpen;
      case 'home':
        return LucideIcons.home;
      case 'briefcase':
        return LucideIcons.briefcase;
      case 'piggy-bank':
        return LucideIcons.piggyBank;
      default:
        return LucideIcons.circleEllipsis;
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);

    final currencyFormatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '${settings.currency} ',
      decimalDigits: 2,
    );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Riverpod handles refresh automatically via streams, but we can invalidate providers
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(recentTransactionsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${_getGreeting()},",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.grey[300]
                                  : Colors
                                        .grey[700], // Increased contrast for grey text
                            ),
                          ),
                          Text(
                            settings.username.isNotEmpty
                                ? settings.username
                                : 'User',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                            ),
                          ),
                        ],
                      ),
                      // Profile Initials / Settings Tap (WCAG touch targets & semantics)
                      GestureDetector(
                        onTap: () => context.push('/settings'),
                        child: Semantics(
                          label: "Open profile settings",
                          button: true,
                          child: Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFF4F46E5),
                              child: Text(
                                settings.username.isNotEmpty
                                    ? settings.username
                                          .substring(
                                            0,
                                            min(2, settings.username.length),
                                          )
                                          .toUpperCase()
                                    : 'U',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Balance Card (Gradient) ---
                  statsAsync.when(
                    data: (stats) => Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF312E81)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF4F46E5,
                            ).withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Semantics(
                        label:
                            "Total Balance: ${currencyFormatter.format(stats.totalBalance)}. Income: ${currencyFormatter.format(stats.totalIncome)}. Expenses: ${currencyFormatter.format(stats.totalExpenses)}.",
                        container: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL BALANCE',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withValues(
                                  alpha: 0.9,
                                ), // Increased contrast on gradient
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormatter.format(stats.totalBalance),
                              style: GoogleFonts.outfit(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Income display
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        LucideIcons.arrowUpRight,
                                        color: Color(0xFF34D399),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Income',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        Text(
                                          currencyFormatter.format(
                                            stats.totalIncome,
                                          ),
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Expense display
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        LucideIcons.arrowDownLeft,
                                        color: Color(0xFFF87171),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Expenses',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        Text(
                                          currencyFormatter.format(
                                            stats.totalExpenses,
                                          ),
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    loading: () => const SizedBox(
                      height: 140,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, _) => Center(child: Text("Error: $err")),
                  ),
                  const SizedBox(height: 24),

                  // --- Visual Budget Ring Section ---
                  statsAsync.when(
                    data: (stats) {
                      if (stats.totalBudgetLimit == 0) {
                        return const SizedBox.shrink();
                      }

                      final percentage = stats.budgetPercentage;
                      final semanticColor = _getSemanticColor(
                        percentage,
                        isDark,
                      );

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF2D3748)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        child: Semantics(
                          label:
                              "Overall Monthly Budget: ${(percentage * 100).toStringAsFixed(0)}% used. ${currencyFormatter.format(stats.totalBudgetSpent)} spent of ${currencyFormatter.format(stats.totalBudgetLimit)}.",
                          container: true,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                // Circular Ring
                                SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: SizedBox(
                                          width: 84,
                                          height: 84,
                                          child: CircularProgressIndicator(
                                            value: percentage.clamp(0.0, 1.0),
                                            strokeWidth: 10,
                                            backgroundColor: isDark
                                                ? Colors.grey[800]
                                                : Colors.grey[200],
                                            color: semanticColor,
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Text(
                                          "${(percentage * 100).toStringAsFixed(0)}%",
                                          style: GoogleFonts.outfit(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: semanticColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Core stats
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Overall Monthly Budget',
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${currencyFormatter.format(stats.totalBudgetSpent)} spent of ${currencyFormatter.format(stats.totalBudgetLimit)}",
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.grey[300]
                                              : Colors
                                                    .grey[700], // Increased contrast
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (percentage >= 0.90)
                                        Text(
                                          "⚠️ Over-budget alert! Control spending.",
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: isDark
                                                ? const Color(0xFFFCA5A5)
                                                : const Color(0xFFD01C1C),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      else if (percentage >= 0.70)
                                        Text(
                                          "🔔 Approaching budget limits.",
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: isDark
                                                ? const Color(0xFFFBBF24)
                                                : const Color(0xFFA35200),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      else
                                        Text(
                                          "✅ Budget status is safe.",
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: isDark
                                                ? const Color(0xFF34D399)
                                                : const Color(0xFF0D7A57),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (err, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  // --- Top Category Budgets Row ---
                  statsAsync.when(
                    data: (stats) {
                      if (stats.topCategoryBudgets.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Category Budget Usage",
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/budgets'),
                                child: Semantics(
                                  label: "See all budget limits",
                                  button: true,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    child: Text(
                                      "See All",
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF4F46E5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height:
                                130, // Increased height to prevent clipping with dynamic font sizes
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: stats.topCategoryBudgets.length,
                              itemBuilder: (context, index) {
                                final usage = stats.topCategoryBudgets[index];
                                final color = _parseColor(usage.category.color);
                                final progress = usage.percentage.clamp(
                                  0.0,
                                  1.0,
                                );

                                return Container(
                                  width: 140,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: isDark
                                            ? const Color(0xFF2D3748)
                                            : const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white,
                                    child: Semantics(
                                      label:
                                          "${usage.category.name} category. Spent ${currencyFormatter.format(usage.spent)} of ${currencyFormatter.format(usage.limit)} limit.",
                                      container: true,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  _getIconData(
                                                    usage.category.icon,
                                                  ),
                                                  color: color,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    usage.category.name,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Spacer(),
                                            Text(
                                              currencyFormatter.format(
                                                usage.spent,
                                              ),
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "Limit: ${usage.limit.toStringAsFixed(0)}",
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                color: isDark
                                                    ? Colors.grey[300]
                                                    : Colors.grey[700],
                                              ), // High contrast grey
                                            ),
                                            const SizedBox(height: 4),
                                            // Mini progress bar
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                              child: LinearProgressIndicator(
                                                value: progress,
                                                minHeight: 4,
                                                backgroundColor: isDark
                                                    ? Colors.grey[800]
                                                    : Colors.grey[200],
                                                color: _getSemanticColor(
                                                  usage.percentage,
                                                  isDark,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (err, _) => const SizedBox.shrink(),
                  ),

                  // --- Recent Transactions ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recent Transactions",
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Tap to route to full transaction list screen
                      GestureDetector(
                        onTap: () => context.push('/transactions'),
                        child: Semantics(
                          label: "See all transactions history",
                          button: true,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Text(
                              "See All",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  recentAsync.when(
                    data: (list) {
                      if (list.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              const Icon(
                                LucideIcons.fileQuestion,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "No transactions logged yet",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          final color = _parseColor(item.category.color);
                          final isExpense = item.transaction.type == 'expense';

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getIconData(item.category.icon),
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                item.category.name,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                item.transaction.note ??
                                    DateFormat(
                                      'MMM d, h:mm a',
                                    ).format(item.transaction.date),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              trailing: Text(
                                "${isExpense ? '-' : '+'}${currencyFormatter.format(item.transaction.amount)}",
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isExpense
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF10B981),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) =>
                        Center(child: Text("Error loading transactions: $err")),
                  ),
                  const SizedBox(
                    height: 80,
                  ), // Padding below content to clear Bottom Nav & FAB
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
