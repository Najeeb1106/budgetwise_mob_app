import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../providers/database_provider.dart';
import '../../providers/category_provider.dart';

class CategoryManagerScreen extends ConsumerWidget {
  const CategoryManagerScreen({super.key});

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

  void _showAddCategorySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddCategorySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoryStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Category Manager",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: categoriesAsync.when(
        data: (list) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final cat = list[index];
              final color = _parseColor(cat.color);

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF2D3748)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getIconData(cat.icon), color: color, size: 20),
                  ),
                  title: Text(
                    cat.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    cat.type == 'both'
                        ? 'INCOME & EXPENSE'
                        : cat.type.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: cat.isDefault
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Default",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            LucideIcons.trash2,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                          onPressed: () {
                            final db = ref.read(databaseProvider);
                            ref
                                .read(categoryNotifierProvider(db).notifier)
                                .deleteCategory(cat.id);
                          },
                        ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'categories_add_category_fab',
        onPressed: () => _showAddCategorySheet(context, ref),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(LucideIcons.plus, size: 28),
      ),
    );
  }
}

class _AddCategorySheet extends ConsumerStatefulWidget {
  const _AddCategorySheet();

  @override
  ConsumerState<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends ConsumerState<_AddCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedType = 'expense'; // 'expense' | 'income' | 'both'
  String _selectedIcon = 'restaurant';
  String _selectedColorHex = '#4F46E5';

  final List<Map<String, dynamic>> _iconOptions = [
    {'name': 'restaurant', 'icon': LucideIcons.utensils},
    {'name': 'car', 'icon': LucideIcons.car},
    {'name': 'shopping-bag', 'icon': LucideIcons.shoppingBag},
    {'name': 'heart-pulse', 'icon': LucideIcons.heartPulse},
    {'name': 'tv', 'icon': LucideIcons.tv},
    {'name': 'zap', 'icon': LucideIcons.zap},
    {'name': 'book-open', 'icon': LucideIcons.bookOpen},
    {'name': 'home', 'icon': LucideIcons.home},
    {'name': 'briefcase', 'icon': LucideIcons.briefcase},
    {'name': 'piggy-bank', 'icon': LucideIcons.piggyBank},
  ];

  final List<String> _colorOptions = [
    '#4F46E5', // Indigo
    '#0D9488', // Teal
    '#10B981', // Emerald
    '#EF4444', // Red
    '#F59E0B', // Amber
    '#EC4899', // Pink
    '#8B5CF6', // Purple
    '#3B82F6', // Blue
    '#06B6D4', // Cyan
    '#6B7280', // Gray
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final db = ref.read(databaseProvider);
      ref
          .read(categoryNotifierProvider(db).notifier)
          .addCategory(
            name: _nameController.text.trim(),
            icon: _selectedIcon,
            colorHex: _selectedColorHex,
            type: _selectedType,
          );
      Navigator.pop(context);
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
                    "Create Custom Category",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Category Name & Type Row
                  Row(
                    children: [
                      // Category Name
                      Expanded(
                        flex: 6,
                        child: TextFormField(
                          controller: _nameController,
                          maxLength: 30,
                          style: GoogleFonts.inter(fontSize: 13.5),
                          decoration: InputDecoration(
                            labelText: "Category Name",
                            counterText: "",
                            prefixIcon: const Icon(LucideIcons.tag, size: 16),
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
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Dropdown Type suitability
                      Expanded(
                        flex: 5,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedType,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          dropdownColor: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          decoration: InputDecoration(
                            labelText: "Type",
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
                          items: const [
                            DropdownMenuItem(
                              value: 'expense',
                              child: Text("Expense"),
                            ),
                            DropdownMenuItem(
                              value: 'income',
                              child: Text("Income"),
                            ),
                            DropdownMenuItem(
                              value: 'both',
                              child: Text("Both"),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedType = val;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Horizontal Icon selector
                  Text(
                    "Select Icon",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _iconOptions.length,
                      itemBuilder: (context, index) {
                        final item = _iconOptions[index];
                        final isSelected = item['name'] == _selectedIcon;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIcon = item['name'] as String;
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
                                      0xFF4F46E5,
                                    ).withValues(alpha: 0.15)
                                  : (isDark
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFF1F5F9)),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF4F46E5)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                item['icon'] as IconData,
                                color: isSelected
                                    ? const Color(0xFF4F46E5)
                                    : (isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600]),
                                size: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Color Picker Horizontal List
                  Text(
                    "Select Color",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 34,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colorOptions.length,
                      itemBuilder: (context, index) {
                        final hex = _colorOptions[index];
                        final color = _parseColor(hex);
                        final isSelected = hex == _selectedColorHex;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColorHex = hex;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      },
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
                        "Create Category",
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
