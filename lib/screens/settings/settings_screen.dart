import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:drift/drift.dart' hide Column;

import '../../providers/settings_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/csv_exporter.dart';
import '../../services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
    double currentIncome,
  ) {
    final nameController = TextEditingController(text: currentName);
    final incomeController = TextEditingController(
      text: currentIncome.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Edit Profile",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Your Name"),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? "Name is required"
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: incomeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Estimated Income",
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Income is required";
                    }
                    if (double.tryParse(val) == null || double.parse(val) < 0) {
                      return "Enter a valid positive number";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateSettings(
                        username: nameController.text.trim(),
                        estimatedIncome: double.parse(incomeController.text),
                      );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
              ),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _confirmCsvExport(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Export Transactions",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to export all transactions as a CSV file?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              key: const Key('export_confirm_button'),
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                try {
                  final db = ref.read(databaseProvider);
                  final query = db.select(db.transactions).join([
                    innerJoin(
                      db.categories,
                      db.categories.id.equalsExp(db.transactions.categoryId),
                    ),
                  ]);
                  final rows = await query.get();
                  final transactions = rows.map((row) {
                    return TransactionWithCategory(
                      transaction: row.readTable(db.transactions),
                      category: row.readTable(db.categories),
                    );
                  }).toList();

                  final csvData = CsvExporter.generateCsv(transactions);

                  final directory = await getTemporaryDirectory();
                  final file = File(
                    p.join(directory.path, 'budgetwise_transactions.csv'),
                  );
                  await file.writeAsString(csvData);

                  final xFile = XFile(file.path);
                  await SharePlus.instance.share(
                    ShareParams(
                      files: [xFile],
                      text: 'Exported Transactions from BudgetWise',
                    ),
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transactions exported successfully.'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to export transactions: $e'),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
              ),
              child: const Text("Export"),
            ),
          ],
        );
      },
    );
  }

  void _confirmClearData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Clear All Data",
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: const Color(0xFFEF4444),
            ),
          ),
          content: const Text(
            "Warning! This is a highly destructive action and will permanently delete all your logged transactions, budgets, goals, and profile preferences from this device. Are you absolutely sure?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                // Clear settings and completely delete SQLite databases
                await ref.read(settingsProvider.notifier).clearAllData(ref);

                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  context.go('/splash'); // Reboot to splash and onboarding
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text("Clear Everything"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Profile Card ---
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
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF4F46E5),
                        child: Text(
                          settings.username.isNotEmpty
                              ? settings.username.substring(0, 1).toUpperCase()
                              : 'U',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              settings.username.isNotEmpty
                                  ? settings.username
                                  : 'User Name',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Income: ${settings.currency} ${settings.estimatedIncome.toStringAsFixed(0)}/mo",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          LucideIcons.edit2,
                          size: 20,
                          color: Color(0xFF4F46E5),
                        ),
                        onPressed: () => _showEditProfileDialog(
                          context,
                          ref,
                          settings.username,
                          settings.estimatedIncome,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Navigation & Preferences List ---
              Text(
                "Preferences",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),

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
                child: Column(
                  children: [
                    // Category Manager
                    ListTile(
                      leading: const Icon(
                        LucideIcons.tag,
                        color: Color(0xFF0D9488),
                      ),
                      title: const Text("Category Manager"),
                      subtitle: const Text(
                        "Customize transaction tags & icons",
                      ),
                      trailing: const Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () => context.push('/settings/categories'),
                    ),
                    const Divider(height: 1),

                    // Currency Switcher
                    ListTile(
                      leading: const Icon(
                        LucideIcons.banknote,
                        color: Colors.amber,
                      ),
                      title: const Text("Selected Currency"),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: settings.currency,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            items: ['PKR', 'USD', 'EUR', 'GBP', 'AED']
                                .map(
                                  (curr) => DropdownMenuItem(
                                    value: curr,
                                    child: Text(curr),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                    .read(settingsProvider.notifier)
                                    .updateSettings(currency: val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),

                    // Theme selector
                    ListTile(
                      leading: const Icon(
                        LucideIcons.moon,
                        color: Color(0xFF8B5CF6),
                      ),
                      title: const Text("Theme Mode"),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: settings.themeMode,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'light',
                                child: Text("Light"),
                              ),
                              DropdownMenuItem(
                                value: 'dark',
                                child: Text("Dark"),
                              ),
                              DropdownMenuItem(
                                value: 'system',
                                child: Text("System"),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                    .read(settingsProvider.notifier)
                                    .updateSettings(themeMode: val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),

                    // Biometric Lock Toggle
                    SwitchListTile(
                      secondary: const Icon(
                        LucideIcons.shieldAlert,
                        color: Color(0xFF10B981),
                      ),
                      title: const Text("Enable Biometric Lock"),
                      value: settings.biometricEnabled,
                      onChanged: (val) {
                        ref
                            .read(settingsProvider.notifier)
                            .updateSettings(biometricEnabled: val);
                      },
                      activeThumbColor: const Color(0xFF4F46E5),
                    ),
                    const Divider(height: 1),

                    // CSV Export Button
                    ListTile(
                      key: const Key('export_csv_tile'),
                      leading: const Icon(
                        LucideIcons.download,
                        color: Color(0xFF4F46E5),
                      ),
                      title: const Text("Export to CSV"),
                      subtitle: const Text(
                        "Share and save all transactions as CSV",
                      ),
                      trailing: const Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () => _confirmCsvExport(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Notifications ---
              Text(
                "Notifications",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),

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
                child: Column(
                  children: [
                    SwitchListTile(
                      key: const Key('budget_alerts_tile'),
                      secondary: const Icon(
                        LucideIcons.bellRing,
                        color: Color(0xFF3B82F6),
                      ),
                      title: const Text("Budget Threshold Alerts"),
                      subtitle: const Text("Notify when spent exceeds limit"),
                      value: settings.budgetAlertsEnabled,
                      onChanged: (val) async {
                        if (val) {
                          final granted = await NotificationService()
                              .requestPermissions();
                          if (!granted && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Notification permission is required to enable budget alerts.',
                                ),
                              ),
                            );
                            return;
                          }
                        }
                        ref
                            .read(settingsProvider.notifier)
                            .updateSettings(budgetAlertsEnabled: val);
                      },
                      activeThumbColor: const Color(0xFF4F46E5),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      key: const Key('weekly_summary_tile'),
                      secondary: const Icon(
                        LucideIcons.calendar,
                        color: Color(0xFF10B981),
                      ),
                      title: const Text("Weekly Spending Summary"),
                      subtitle: const Text("Get weekly scheduled summaries"),
                      value: settings.weeklySummaryEnabled,
                      onChanged: (val) async {
                        if (val) {
                          final granted = await NotificationService()
                              .requestPermissions();
                          if (!granted && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Notification permission is required to enable weekly summary.',
                                ),
                              ),
                            );
                            return;
                          }
                        }
                        await ref
                            .read(settingsProvider.notifier)
                            .updateSettings(weeklySummaryEnabled: val);
                        if (val) {
                          await NotificationService().scheduleWeeklySummary();
                        } else {
                          final notificationPlugin =
                              FlutterLocalNotificationsPlugin();
                          await notificationPlugin.cancel(id: 200);
                        }
                      },
                      activeThumbColor: const Color(0xFF4F46E5),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      key: const Key('goal_reminders_tile'),
                      secondary: const Icon(
                        LucideIcons.target,
                        color: Color(0xFFF59E0B),
                      ),
                      title: const Text("Goal Deadline Reminders"),
                      subtitle: const Text(
                        "Alert one day before goal deadline",
                      ),
                      value: settings.goalRemindersEnabled,
                      onChanged: (val) async {
                        if (val) {
                          final granted = await NotificationService()
                              .requestPermissions();
                          if (!granted && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Notification permission is required to enable goal reminders.',
                                ),
                              ),
                            );
                            return;
                          }
                        }
                        await ref
                            .read(settingsProvider.notifier)
                            .updateSettings(goalRemindersEnabled: val);
                        if (val) {
                          final db = ref.read(databaseProvider);
                          final goals = await db.select(db.savingsGoals).get();
                          for (final goal in goals) {
                            await NotificationService()
                                .scheduleGoalDeadlineReminder(goal);
                          }
                        } else {
                          final db = ref.read(databaseProvider);
                          final goals = await db.select(db.savingsGoals).get();
                          for (final goal in goals) {
                            await NotificationService().cancelGoalReminder(
                              goal.id,
                            );
                          }
                        }
                      },
                      activeThumbColor: const Color(0xFF4F46E5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Destructive Actions ---
              Text(
                "Data Safety",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),

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
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        LucideIcons.alertTriangle,
                        color: Color(0xFFEF4444),
                      ),
                      title: Text(
                        "Clear All Local Data",
                        style: GoogleFonts.inter(
                          color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        "Delete account profiles, logs, and budgets completely",
                      ),
                      onTap: () => _confirmClearData(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
