import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'add_transaction_sheet.dart';

import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/database_provider.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

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

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Delete Transaction",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to permanently delete this transaction? This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final db = ref.read(databaseProvider);
                ref
                    .read(transactionNotifierProvider(db).notifier)
                    .deleteTransaction(transactionId);
                Navigator.pop(context); // Close Dialog
                context.pop(); // Go back to history

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Transaction deleted successfully!'),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: Text(
                "Delete",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openEditTransaction(
    BuildContext context,
    TransactionWithCategory item,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(transactionToEdit: item),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final detailAsync = ref.watch(transactionDetailProvider(transactionId));
    final item = detailAsync.valueOrNull;

    final currencyFormatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '${settings.currency} ',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Details",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (item != null)
            IconButton(
              key: const Key('edit_transaction_button'),
              icon: const Icon(LucideIcons.pencil),
              onPressed: () => _openEditTransaction(context, item),
            ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444)),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (item) {
          final color = _parseColor(item.category.color);
          final isExpense = item.transaction.type == 'expense';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _getIconData(item.category.icon),
                        color: color,
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Amount Typography
                  Center(
                    child: Text(
                      "${isExpense ? '-' : '+'}${currencyFormatter.format(item.transaction.amount)}",
                      style: GoogleFonts.outfit(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: isExpense
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Category Name & Type Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.tag, size: 12, color: color),
                          const SizedBox(width: 6),
                          Text(
                            item.category.name,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Information Cards
                  Card(
                    elevation: 0,
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF2D3748)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            icon: LucideIcons.activity,
                            title: "Transaction Type",
                            value: item.transaction.type.toUpperCase(),
                            valueColor: isExpense
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            icon: LucideIcons.calendar,
                            title: "Date",
                            value: DateFormat(
                              'EEEE, MMMM d, yyyy',
                            ).format(item.transaction.date),
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            icon: LucideIcons.clock,
                            title: "Time",
                            value: DateFormat(
                              'h:mm a',
                            ).format(item.transaction.date),
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            icon: LucideIcons.refreshCw,
                            title: "Recurring",
                            value: item.transaction.isRecurring
                                ? "YES (${item.transaction.frequency?.toUpperCase()})"
                                : "NO",
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes Card
                  Card(
                    elevation: 0,
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF2D3748)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                LucideIcons.fileText,
                                size: 18,
                                color: Color(0xFF4F46E5),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Notes",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item.transaction.note ??
                                "No notes written for this transaction.",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: item.transaction.note != null
                                  ? (isDark ? Colors.white : Colors.black)
                                  : Colors.grey,
                              fontStyle: item.transaction.note != null
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Text(title, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
