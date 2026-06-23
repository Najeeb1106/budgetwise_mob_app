import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../providers/settings_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

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

  void _showAddEditBudgetSheet(
    BuildContext context,
    WidgetRef ref,
    CategoryBudgetUsage usage,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditBudgetSheet(usage: usage),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final usagesAsync = ref.watch(budgetUsagesProvider);
    final filters = ref.watch(transactionFiltersProvider);

    final currencyFormatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '${settings.currency} ',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Budgets",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Month Selector
          TextButton.icon(
            icon: const Icon(LucideIcons.calendar, size: 16),
            label: Text(DateFormat('MMM yyyy').format(filters.month)),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: filters.month,
                firstDate: DateTime(2020),
                lastDate: DateTime(2101),
              );
              if (picked != null) {
                ref.read(transactionFiltersProvider.notifier).setMonth(picked);
              }
            },
          ),
        ],
      ),
      body: usagesAsync.when(
        data: (usages) {
          final budgeted = usages.where((u) => u.budget != null).toList();
          final unbudgeted = usages.where((u) => u.budget == null).toList();

          double totalBudgeted = 0.0;
          double totalSpent = 0.0;
          for (final u in budgeted) {
            totalBudgeted += u.limit;
            totalSpent += u.spent;
          }

          final overallPercentage = totalBudgeted > 0
              ? (totalSpent / totalBudgeted)
              : 0.0;

          // Combine showing budgeted first, sorted by overbudget usage
          budgeted.sort((a, b) => b.percentage.compareTo(a.percentage));
          final combined = [...budgeted, ...unbudgeted];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Overall Budget Summary Card ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2D3748)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Semantics(
                      label:
                          "Total monthly budget: ${currencyFormatter.format(totalBudgeted)}. ${(overallPercentage * 100).toStringAsFixed(0)}% spent. Spent ${currencyFormatter.format(totalSpent)} of ${currencyFormatter.format(totalBudgeted)} limit. Remaining: ${currencyFormatter.format((totalBudgeted - totalSpent).clamp(0.0, double.infinity))}.",
                      container: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TOTAL MONTHLY BUDGET",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.grey[300]
                                  : Colors
                                        .grey[700], // Increased contrast for grey text
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                currencyFormatter.format(totalBudgeted),
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${(overallPercentage * 100).toStringAsFixed(0)}% Spent",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _getSemanticColor(
                                    overallPercentage,
                                    isDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: overallPercentage.clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              color: _getSemanticColor(
                                overallPercentage,
                                isDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Spent ${currencyFormatter.format(totalSpent)} of ${currencyFormatter.format(totalBudgeted)} limit. Remaining: ${currencyFormatter.format((totalBudgeted - totalSpent).clamp(0.0, double.infinity))}",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                            ), // Increased contrast
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Category Budgets Lists ---
                  Text(
                    "Limits By Category",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: combined.length,
                    itemBuilder: (context, index) {
                      final u = combined[index];
                      final isSet = u.budget != null;
                      final color = _parseColor(u.category.color);

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF2D3748)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Semantics(
                          label: isSet
                              ? "${u.category.name} category. Spent ${currencyFormatter.format(u.spent)} of ${currencyFormatter.format(u.limit)} limit. ${(u.percentage * 100).toStringAsFixed(0)}% used. Double tap to edit limit."
                              : "${u.category.name} category. Spent ${currencyFormatter.format(u.spent)}. No budget limit set. Double tap to set limit.",
                          button: true,
                          child: InkWell(
                            onTap: () =>
                                _showAddEditBudgetSheet(context, ref, u),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          _getIconData(u.category.icon),
                                          color: color,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              u.category.name,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              isSet
                                                  ? "Limit: ${currencyFormatter.format(u.limit)}"
                                                  : "No budget limit set",
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: isDark
                                                    ? Colors.grey[300]
                                                    : Colors.grey[700],
                                              ), // Increased contrast
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            currencyFormatter.format(u.spent),
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (isSet)
                                            Text(
                                              "${(u.percentage * 100).toStringAsFixed(0)}% Used",
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: _getSemanticColor(
                                                  u.percentage,
                                                  isDark,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (isSet) ...[
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                        value: u.percentage.clamp(0.0, 1.0),
                                        minHeight: 6,
                                        backgroundColor: isDark
                                            ? Colors.grey[800]
                                            : Colors.grey[200],
                                        color: _getSemanticColor(
                                          u.percentage,
                                          isDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error loading budgets: $err")),
      ),
    );
  }
}

class _AddEditBudgetSheet extends ConsumerStatefulWidget {
  final CategoryBudgetUsage usage;

  const _AddEditBudgetSheet({required this.usage});

  @override
  ConsumerState<_AddEditBudgetSheet> createState() =>
      _AddEditBudgetSheetState();
}

class _AddEditBudgetSheetState extends ConsumerState<_AddEditBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();
  double _alertThreshold = 0.8;

  @override
  void initState() {
    super.initState();
    if (widget.usage.budget != null) {
      _limitController.text = widget.usage.limit.toStringAsFixed(2);
      _alertThreshold = widget.usage.budget!.alertThreshold;
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final limit = double.tryParse(_limitController.text) ?? 0.0;
      final db = ref.read(databaseProvider);
      final filters = ref.read(transactionFiltersProvider);

      ref
          .read(budgetNotifierProvider(db).notifier)
          .setOrUpdateBudget(
            categoryId: widget.usage.category.id,
            limitAmount: limit,
            month: filters.month.month,
            year: filters.month.year,
            alertThreshold: _alertThreshold,
          );

      Navigator.pop(context);
    }
  }

  void _delete() {
    if (widget.usage.budget != null) {
      final db = ref.read(databaseProvider);
      ref
          .read(budgetNotifierProvider(db).notifier)
          .deleteBudget(widget.usage.budget!.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          top: 14,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pull Bar
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    widget.usage.budget != null
                        ? "Edit ${widget.usage.category.name} Budget"
                        : "Set ${widget.usage.category.name} Budget",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Limit Amount
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          settings.currency,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _limitController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            autofocus: true,
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4F46E5),
                            ),
                            decoration: const InputDecoration(
                              hintText: "0.00",
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return "Required";
                              }
                              final amt = double.tryParse(val);
                              if (amt == null || amt <= 0) return "Must be > 0";
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Alert Threshold Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Warning Threshold",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${(_alertThreshold * 100).toStringAsFixed(0)}%",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Receive in-app warning notification when spending reaches this ratio.",
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4.5,
                      activeTrackColor: const Color(0xFF4F46E5),
                      inactiveTrackColor: isDark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                      thumbColor: const Color(0xFF4F46E5),
                      overlayColor: const Color(
                        0xFF4F46E5,
                      ).withValues(alpha: 0.12),
                      valueIndicatorColor: const Color(0xFF4F46E5),
                    ),
                    child: Slider(
                      value: _alertThreshold,
                      min: 0.50,
                      max: 0.90,
                      divisions: 8,
                      label: "${(_alertThreshold * 100).toStringAsFixed(0)}%",
                      onChanged: (val) {
                        setState(() {
                          _alertThreshold = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Actions Panel
                  Row(
                    children: [
                      if (widget.usage.budget != null) ...[
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: const Color(
                                0xFFEF4444,
                              ).withValues(alpha: 0.12),
                            ),
                            child: IconButton(
                              onPressed: _delete,
                              icon: const Icon(
                                LucideIcons.trash2,
                                color: Color(0xFFEF4444),
                                size: 20,
                              ),
                              tooltip: "Delete Limit",
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              widget.usage.budget != null
                                  ? "Update Budget"
                                  : "Save Budget",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
