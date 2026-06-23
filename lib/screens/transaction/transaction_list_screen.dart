import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/database_provider.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final db = ref.read(databaseProvider);
      ref.read(paginatedTransactionsProvider(db).notifier).loadMore();
    }
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

  String _formatGroupDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final compareDate = DateTime(date.year, date.month, date.day);

    if (compareDate == today) return "Today";
    if (compareDate == yesterday) return "Yesterday";

    if (date.year == now.year) {
      return DateFormat('EEEE, MMM d').format(date);
    }
    return DateFormat('EEEE, MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final filters = ref.watch(transactionFiltersProvider);
    final db = ref.watch(databaseProvider);
    final transactionsAsync = ref.watch(paginatedTransactionsProvider(db));

    final currencyFormatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '${settings.currency} ',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Transaction History",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Month Picker Action
          TextButton.icon(
            icon: const Icon(LucideIcons.calendar, size: 16),
            label: Text(DateFormat('MMM yyyy').format(filters.month)),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: filters.month,
                firstDate: DateTime(2020),
                lastDate: DateTime(2101),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null) {
                ref.read(transactionFiltersProvider.notifier).setMonth(picked);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Panel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Search Input
                TextField(
                  onChanged: (val) {
                    ref
                        .read(transactionFiltersProvider.notifier)
                        .setSearch(val);
                  },
                  decoration: InputDecoration(
                    hintText: "Search note or category...",
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Horizontal Type Filter Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // All Filter
                      Semantics(
                        label: "Filter by all transaction types",
                        selected: filters.type == null,
                        button: true,
                        child: FilterChip(
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          label: const Text("All"),
                          selected: filters.type == null,
                          onSelected: (val) {
                            ref
                                .read(transactionFiltersProvider.notifier)
                                .setType(null);
                          },
                          selectedColor: const Color(
                            0xFF4F46E5,
                          ).withValues(alpha: 0.15),
                          labelStyle: GoogleFonts.inter(
                            color: filters.type == null
                                ? const Color(0xFF4F46E5)
                                : (isDark ? Colors.white : Colors.black),
                            fontWeight: filters.type == null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Expenses Filter
                      Semantics(
                        label: "Filter by expenses only",
                        selected: filters.type == 'expense',
                        button: true,
                        child: FilterChip(
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          label: const Text("Expenses"),
                          selected: filters.type == 'expense',
                          onSelected: (val) {
                            ref
                                .read(transactionFiltersProvider.notifier)
                                .setType('expense');
                          },
                          selectedColor:
                              (isDark
                                      ? const Color(0xFFF87171)
                                      : const Color(0xFFD01C1C))
                                  .withValues(alpha: 0.15),
                          labelStyle: GoogleFonts.inter(
                            color: filters.type == 'expense'
                                ? (isDark
                                      ? const Color(0xFFF87171)
                                      : const Color(0xFFD01C1C))
                                : (isDark ? Colors.white : Colors.black),
                            fontWeight: filters.type == 'expense'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Income Filter
                      Semantics(
                        label: "Filter by income only",
                        selected: filters.type == 'income',
                        button: true,
                        child: FilterChip(
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          label: const Text("Income"),
                          selected: filters.type == 'income',
                          onSelected: (val) {
                            ref
                                .read(transactionFiltersProvider.notifier)
                                .setType('income');
                          },
                          selectedColor:
                              (isDark
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF0D7A57))
                                  .withValues(alpha: 0.15),
                          labelStyle: GoogleFonts.inter(
                            color: filters.type == 'income'
                                ? (isDark
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF0D7A57))
                                : (isDark ? Colors.white : Colors.black),
                            fontWeight: filters.type == 'income'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Sort Selector Dropdown
                      Semantics(
                        label: "Sort transactions dropdown",
                        button: true,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: filters.sortBy,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'date_desc',
                                  child: Text("Newest Date"),
                                ),
                                DropdownMenuItem(
                                  value: 'date_asc',
                                  child: Text("Oldest Date"),
                                ),
                                DropdownMenuItem(
                                  value: 'amount_desc',
                                  child: Text("Amount: High to Low"),
                                ),
                                DropdownMenuItem(
                                  value: 'amount_asc',
                                  child: Text("Amount: Low to High"),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  ref
                                      .read(transactionFiltersProvider.notifier)
                                      .setSortBy(val);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Transaction List Section
          Expanded(
            child: transactionsAsync.when(
              data: (paginatedState) {
                final list = paginatedState.transactions;
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.fileWarning,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No Transactions Found",
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "No transactions match the selected filters for this month.",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Group transactions by date
                final Map<String, List<TransactionWithCategory>> grouped = {};
                for (final item in list) {
                  final groupKey = _formatGroupDate(item.transaction.date);
                  grouped.putIfAbsent(groupKey, () => []).add(item);
                }

                final groupKeys = grouped.keys.toList();

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: groupKeys.length + 1,
                  itemBuilder: (context, index) {
                    if (index == groupKeys.length) {
                      if (paginatedState.isLoadingMore) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return const SizedBox(height: 32);
                    }

                    final groupKey = groupKeys[index];
                    final groupItems = grouped[groupKey]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Group Title
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: 8,
                          ),
                          child: Text(
                            groupKey.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        // Group Items Card List
                        ...List.generate(groupItems.length, (itemIndex) {
                          final item = groupItems[itemIndex];
                          final color = _parseColor(item.category.color);
                          final isExpense = item.transaction.type == 'expense';
                          final displayAmount = currencyFormatter.format(
                            item.transaction.amount,
                          );
                          final semanticLabel =
                              "Transaction in category ${item.category.name}. Note: ${item.transaction.note ?? 'None'}. Amount: ${isExpense ? 'Minus' : 'Plus'} $displayAmount.";

                          return Semantics(
                            label: semanticLabel,
                            button: true,
                            child: Card(
                              elevation: 0,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                onTap: () {
                                  context.push(
                                    '/transaction/${item.transaction.id}',
                                  );
                                },
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
                                        'h:mm a',
                                      ).format(item.transaction.date),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                trailing: Text(
                                  "${isExpense ? '-' : '+'}$displayAmount",
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isExpense
                                        ? (isDark
                                              ? const Color(0xFFF87171)
                                              : const Color(0xFFD01C1C))
                                        : (isDark
                                              ? const Color(0xFF34D399)
                                              : const Color(0xFF0D7A57)),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text("Error: $err")),
            ),
          ),
        ],
      ),
    );
  }
}
