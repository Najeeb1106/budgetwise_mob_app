import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../providers/settings_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/goal_provider.dart';
import '../../data/database.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  int _calculateDaysRemaining(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;
    return max(0, difference);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final goalsAsync = ref.watch(savingsGoalsStreamProvider);

    final currencyFormatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '${settings.currency} ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Savings Goals",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.piggyBank,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No Savings Goals Yet",
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Set a target goal for a trip, vehicle, or emergency fund, and track your saving milestones.",
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

          final activeGoals = goals.where((g) => !g.isCompleted).toList();
          final completedGoals = goals.where((g) => g.isCompleted).toList();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (activeGoals.isNotEmpty) ...[
                    Text(
                      "Active Goals",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeGoals.length,
                      itemBuilder: (context, index) {
                        final goal = activeGoals[index];
                        final progress = (goal.savedAmount / goal.targetAmount)
                            .clamp(0.0, 1.0);
                        final daysLeft = _calculateDaysRemaining(goal.deadline);

                        return _buildGoalCard(
                          context: context,
                          goal: goal,
                          progress: progress,
                          daysLeft: daysLeft,
                          currencyFormatter: currencyFormatter,
                          isDark: isDark,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (completedGoals.isNotEmpty) ...[
                    Text(
                      "Completed Goals 🎉",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: completedGoals.length,
                      itemBuilder: (context, index) {
                        final goal = completedGoals[index];
                        return _buildGoalCard(
                          context: context,
                          goal: goal,
                          progress: 1.0,
                          daysLeft: 0,
                          currencyFormatter: currencyFormatter,
                          isDark: isDark,
                          isCompleted: true,
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'goals_add_goal_fab',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddGoalSheet(),
          );
        },
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(LucideIcons.plus, size: 28),
      ),
    );
  }

  Widget _buildGoalCard({
    required BuildContext context,
    required SavingsGoal goal,
    required double progress,
    required int daysLeft,
    required NumberFormat currencyFormatter,
    required bool isDark,
    bool isCompleted = false,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE5E7EB),
        ),
      ),
      child: InkWell(
        onTap: () {
          context.push('/goal/${goal.id}');
        },
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
                      color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      goal.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isCompleted
                              ? "Goal Achieved!"
                              : "$daysLeft days remaining",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isCompleted
                                ? const Color(0xFF10B981)
                                : Colors.grey,
                            fontWeight: isCompleted
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCompleted)
                    const Icon(
                      LucideIcons.checkCircle2,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${currencyFormatter.format(goal.savedAmount)} saved",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Target: ${currencyFormatter.format(goal.targetAmount)}",
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : const Color(0xFF0D9488),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddGoalSheet extends ConsumerStatefulWidget {
  final SavingsGoal? goalToEdit;

  const AddGoalSheet({super.key, this.goalToEdit});

  @override
  ConsumerState<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<AddGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _initialController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedEmoji = '💰';
  DateTime _deadline = DateTime.now().add(const Duration(days: 30));

  final List<String> _emojiOptions = [
    '💰',
    '🚗',
    '✈️',
    '🏠',
    '🎓',
    '💻',
    '🎮',
    '🏖️',
    '🏥',
    '🎁',
    '🚀',
    '💎',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.goalToEdit != null) {
      final goal = widget.goalToEdit!;
      _nameController.text = goal.name;
      _targetController.text = goal.targetAmount.toString();
      _selectedEmoji = goal.icon;
      _deadline = goal.deadline;
      _notesController.text = goal.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _initialController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final target = double.tryParse(_targetController.text) ?? 0.0;
      final db = ref.read(databaseProvider);
      final isEdit = widget.goalToEdit != null;

      if (isEdit) {
        ref
            .read(goalNotifierProvider(db).notifier)
            .updateGoal(
              id: widget.goalToEdit!.id,
              name: _nameController.text.trim(),
              icon: _selectedEmoji,
              targetAmount: target,
              deadline: _deadline,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );
      } else {
        final initial = double.tryParse(_initialController.text) ?? 0.0;
        ref
            .read(goalNotifierProvider(db).notifier)
            .addGoal(
              name: _nameController.text.trim(),
              icon: _selectedEmoji,
              targetAmount: target,
              initialSavedAmount: initial,
              deadline: _deadline,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );
      }

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
                    widget.goalToEdit != null
                        ? "Edit Savings Goal"
                        : "Create New Goal",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Goal name
                  TextFormField(
                    controller: _nameController,
                    maxLength: 40,
                    style: GoogleFonts.inter(fontSize: 13.5),
                    decoration: InputDecoration(
                      labelText: "Goal Name (e.g. Laptop, Trip)",
                      counterText: "",
                      prefixIcon: const Icon(LucideIcons.pencil, size: 16),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 10,
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return "Goal name is required";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Emoji Selection Horizontal Chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Icon / Emoji",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _selectedEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _emojiOptions.length,
                      itemBuilder: (context, index) {
                        final emoji = _emojiOptions[index];
                        final isSelected = emoji == _selectedEmoji;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedEmoji = emoji;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 6),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(
                                      0xFF0D9488,
                                    ).withValues(alpha: 0.15)
                                  : (isDark
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFF1F5F9)),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0D9488)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Side-by-Side Target and Initial Amount
                  Row(
                    children: [
                      // Target Amount
                      Expanded(
                        child: TextFormField(
                          controller: _targetController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(fontSize: 13.5),
                          decoration: InputDecoration(
                            labelText: "Target Amount",
                            prefixText: "${settings.currency} ",
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 10,
                            ),
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
                      if (widget.goalToEdit == null) ...[
                        const SizedBox(width: 8),
                        // Initial Amount
                        Expanded(
                          child: TextFormField(
                            controller: _initialController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(fontSize: 13.5),
                            decoration: InputDecoration(
                              labelText: "Initial Saved (Opt)",
                              prefixText: "${settings.currency} ",
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Date Deadline selector
                  InkWell(
                    onTap: () => _selectDeadline(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 11,
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.calendar,
                            size: 16,
                            color: Color(0xFF0D9488),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Target Date: ${DateFormat('MMM d, yyyy').format(_deadline)}",
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Save button
                  Container(
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
                        widget.goalToEdit != null
                            ? "Save Changes"
                            : "Save Goal",
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
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
