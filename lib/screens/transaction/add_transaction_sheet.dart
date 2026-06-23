import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../providers/database_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../../data/database.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final TransactionWithCategory? transactionToEdit;

  const AddTransactionSheet({super.key, this.transactionToEdit});

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _transactionType = 'expense'; // 'expense' | 'income'
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  String _recurringFrequency = 'monthly'; // 'daily' | 'weekly' | 'monthly'

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      final tx = widget.transactionToEdit!.transaction;
      _amountController.text = tx.amount.toString();
      _noteController.text = tx.note ?? '';
      _transactionType = tx.type;
      _selectedCategory = widget.transactionToEdit!.category;
      _selectedDate = tx.date;
      _isRecurring = tx.isRecurring;
      _recurringFrequency = tx.frequency ?? 'monthly';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4F46E5),
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a category'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final db = ref.read(databaseProvider);
      final isEdit = widget.transactionToEdit != null;

      if (isEdit) {
        ref
            .read(transactionNotifierProvider(db).notifier)
            .updateTransaction(
              id: widget.transactionToEdit!.transaction.id,
              amount: amount,
              type: _transactionType,
              categoryId: _selectedCategory!.id,
              date: _selectedDate,
              note: _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
              isRecurring: _isRecurring,
              frequency: _isRecurring ? _recurringFrequency : null,
            );
      } else {
        ref
            .read(transactionNotifierProvider(db).notifier)
            .addTransaction(
              amount: amount,
              type: _transactionType,
              categoryId: _selectedCategory!.id,
              date: _selectedDate,
              note: _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
              isRecurring: _isRecurring,
              frequency: _isRecurring ? _recurringFrequency : null,
            );
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                LucideIcons.checkCircle,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isEdit
                    ? 'Transaction updated successfully!'
                    : 'Transaction logged successfully!',
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoryStreamProvider);
    final settings = ref.watch(settingsProvider);

    final filteredCategories = (categoriesAsync.value ?? []).where((cat) {
      if (_transactionType == 'expense') {
        return cat.type == 'expense' || cat.type == 'both';
      } else {
        return cat.type == 'income' || cat.type == 'both';
      }
    }).toList();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          top: 12,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
              blurRadius: 20,
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
                  const SizedBox(height: 10),

                  // Header Row (Mini Type Selector & Mini Date Picker + Close Button)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Mini Expense/Income Switcher
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildMiniTypeBtn(
                              'expense',
                              'Expense',
                              const Color(0xFFEF4444),
                              isDark,
                            ),
                            _buildMiniTypeBtn(
                              'income',
                              'Income',
                              const Color(0xFF10B981),
                              isDark,
                            ),
                          ],
                        ),
                      ),

                      // Mini Date Picker Button
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.calendar,
                                size: 13,
                                color: Color(0xFF4F46E5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MMM d').format(_selectedDate),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Close icon button
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: isDark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // High-Density Input Row (Amount and Note combined side-by-side)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Compact Amount Card
                      Expanded(
                        flex: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _transactionType == 'expense'
                                  ? const Color(
                                      0xFFEF4444,
                                    ).withValues(alpha: 0.3)
                                  : const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                settings.currency,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: TextFormField(
                                  controller: _amountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  autofocus: true,
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _transactionType == 'expense'
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF10B981),
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: "0.00",
                                    hintStyle: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return "Required";
                                    }
                                    final amt = double.tryParse(val);
                                    if (amt == null || amt <= 0) return "> 0";
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Compact Notes field
                      Expanded(
                        flex: 4,
                        child: TextFormField(
                          controller: _noteController,
                          maxLength: 80,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: "Add note...",
                            counterText: "",
                            isDense: true,
                            prefixIcon: const Icon(
                              LucideIcons.fileText,
                              size: 14,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Compact Horizontal Category Chips (Scrolling list with locking 38dp height)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Category",
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedCategory != null)
                        Text(
                          _selectedCategory!.name,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _parseColor(_selectedCategory!.color),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  SizedBox(
                    height: 38,
                    child: filteredCategories.isEmpty
                        ? Center(
                            child: Text(
                              "No categories found",
                              style: GoogleFonts.inter(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: filteredCategories.length,
                            itemBuilder: (context, index) {
                              final cat = filteredCategories[index];
                              final isSelected =
                                  _selectedCategory?.id == cat.id;
                              final color = _parseColor(cat.color);

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = isSelected ? null : cat;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.withValues(alpha: 0.14)
                                        : (isDark
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? color
                                          : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getIconData(cat.icon),
                                        size: 13,
                                        color: isSelected
                                            ? color
                                            : (isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600]),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        cat.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? color
                                              : (isDark
                                                    ? Colors.grey[300]
                                                    : Colors.grey[700]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),

                  // Actions footer (Compact Recurring trigger & Clean Save button side-by-side)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Mini Recurring Switch
                      GestureDetector(
                        onTap: () =>
                            setState(() => _isRecurring = !_isRecurring),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _isRecurring
                                ? const Color(
                                    0xFF4F46E5,
                                  ).withValues(alpha: 0.12)
                                : (isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.repeat,
                                size: 13,
                                color: _isRecurring
                                    ? const Color(0xFF4F46E5)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "Recurring",
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: _isRecurring
                                      ? const Color(0xFF4F46E5)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Medium Clean Gradient Save Button
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 16,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            "Save",
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Frequency dropdown (Expanded inline only if recurring is true)
                  if (_isRecurring) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _recurringFrequency,
                          isExpanded: true,
                          icon: const Icon(LucideIcons.chevronDown, size: 14),
                          items: ['daily', 'weekly', 'monthly']
                              .map(
                                (freq) => DropdownMenuItem(
                                  value: freq,
                                  child: Text(
                                    freq.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _recurringFrequency = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTypeBtn(
    String type,
    String label,
    Color activeColor,
    bool isDark,
  ) {
    final isSelected = _transactionType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _transactionType = type;
          _selectedCategory = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? activeColor
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}
