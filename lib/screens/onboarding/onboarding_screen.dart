import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/settings_provider.dart';
import '../../providers/database_provider.dart';
import '../../services/notification_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1 Controllers
  final _nameController = TextEditingController();
  final _formKeyStep1 = GlobalKey<FormState>();

  // Step 2 Controllers
  String _selectedCurrency = 'USD';
  final _incomeController = TextEditingController();
  bool _includeSalaryInBalance = true;
  final _formKeyStep2 = GlobalKey<FormState>();

  // Step 3 state
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Food',
      'icon': LucideIcons.utensils,
      'color': Colors.red,
      'selected': true,
    },
    {
      'name': 'Transport',
      'icon': LucideIcons.car,
      'color': Colors.blue,
      'selected': true,
    },
    {
      'name': 'Shopping',
      'icon': LucideIcons.shoppingBag,
      'color': Colors.pink,
      'selected': true,
    },
    {
      'name': 'Health',
      'icon': LucideIcons.heartPulse,
      'color': Colors.teal,
      'selected': true,
    },
    {
      'name': 'Entertainment',
      'icon': LucideIcons.tv,
      'color': Colors.purple,
      'selected': true,
    },
    {
      'name': 'Utilities',
      'icon': LucideIcons.zap,
      'color': Colors.amber,
      'selected': true,
    },
    {
      'name': 'Education',
      'icon': LucideIcons.bookOpen,
      'color': Colors.cyan,
      'selected': true,
    },
    {
      'name': 'Rent',
      'icon': LucideIcons.home,
      'color': Colors.grey,
      'selected': true,
    },
    {
      'name': 'Salary',
      'icon': LucideIcons.briefcase,
      'color': Colors.teal,
      'selected': true,
    },
    {
      'name': 'Savings',
      'icon': LucideIcons.piggyBank,
      'color': Colors.teal,
      'selected': true,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_formKeyStep1.currentState?.validate() ?? false) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else if (_currentStep == 1) {
      if (_formKeyStep2.currentState?.validate() ?? false) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else if (_currentStep == 2) {
      _completeOnboarding();
    }
  }

  void _prevStep() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    final income = double.tryParse(_incomeController.text) ?? 0.0;

    // Request notification permissions and schedule summary if granted
    try {
      final granted = await NotificationService().requestPermissions();
      if (granted) {
        await NotificationService().scheduleWeeklySummary();
      }
    } catch (_) {
      // Graceful error handler for notification request
    }

    // Save to settings
    try {
      await ref
          .read(settingsProvider.notifier)
          .updateSettings(
            username: _nameController.text.trim(),
            currency: _selectedCurrency,
            estimatedIncome: income,
            includeSalaryInBalance: _includeSalaryInBalance,
            isOnboardingComplete: true,
          );
    } catch (_) {
      // Graceful error handler for settings update
    }

    // Get the database instance and delete deselected categories
    try {
      final db = ref.read(databaseProvider);
      final deselectedNames = _categories
          .where((cat) => !(cat['selected'] as bool))
          .map((cat) => cat['name'] as String)
          .toList();

      if (deselectedNames.isNotEmpty) {
        await (db.delete(
          db.categories,
        )..where((c) => c.name.isIn(deselectedNames))).go();
      }
    } catch (_) {
      // Graceful error handler to prevent blocking navigation if database query fails
    }

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: Icon(
                  LucideIcons.arrowLeft,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: _prevStep,
              )
            : null,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final active = index == _currentStep;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: active ? 24 : 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: active
                    ? const Color(0xFF4F46E5)
                    : (isDark ? Colors.grey[700] : Colors.grey[300]),
              ),
            );
          }),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              _currentStep = index;
            });
          },
          children: [
            _buildStep1(isDark),
            _buildStep2(isDark),
            _buildStep3(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1(bool isDark) {
    return Form(
      key: _formKeyStep1,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.user,
                  size: 48,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "What should we call you?",
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Enter your name to personalize your budgeting experience.",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              style: GoogleFonts.inter(fontSize: 16),
              decoration: InputDecoration(
                hintText: "Your Name",
                prefixIcon: const Icon(LucideIcons.user, size: 20),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return "Name is required";
                }
                if (val.trim().length > 30) {
                  return "Name must be under 30 characters";
                }
                return null;
              },
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              key: const Key('continue_button_step1'),
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                "Continue",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2(bool isDark) {
    return Form(
      key: _formKeyStep2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              "Income & Currency",
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Set your default currency and monthly income so we can establish your monthly starting balance.",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Currency selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCurrency,
                  decoration: const InputDecoration(
                    labelText: "Select Currency",
                    border: InputBorder.none,
                  ),
                  items: ['PKR', 'USD', 'EUR', 'GBP', 'AED']
                      .map(
                        (curr) => DropdownMenuItem(
                          value: curr,
                          child: Text(
                            curr,
                            style: GoogleFonts.inter(fontSize: 16),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCurrency = val;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Income input
            TextFormField(
              controller: _incomeController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(fontSize: 16),
              decoration: InputDecoration(
                labelText: "Estimated Monthly Income",
                prefixText: "$_selectedCurrency ",
                prefixIcon: const Icon(LucideIcons.banknote, size: 20),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return "Monthly Income is required";
                }
                if (double.tryParse(val) == null || double.parse(val) < 0) {
                  return "Enter a valid positive number";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Toggle Include Salary
            SwitchListTile(
              title: Text(
                "Include salary in dashboard balance",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                "If enabled, salary transaction logs will add to your total available balance.",
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
              ),
              value: _includeSalaryInBalance,
              onChanged: (val) {
                setState(() {
                  _includeSalaryInBalance = val;
                });
              },
              activeThumbColor: const Color(0xFF4F46E5),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              key: const Key('continue_button_step2'),
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                "Continue",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Text(
            "Default Categories",
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Select the standard categories you would like to track. You can modify these anytime in Settings.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Custom chip grid
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: List.generate(_categories.length, (index) {
                  final cat = _categories[index];
                  final selected = cat['selected'] as bool;
                  return ChoiceChip(
                    label: Text(cat['name']),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        _categories[index]['selected'] = val;
                      });
                    },
                    avatar: Icon(
                      cat['icon'] as IconData,
                      size: 16,
                      color: selected ? Colors.white : cat['color'] as Color,
                    ),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? Colors.white
                          : (isDark ? Colors.grey[300] : Colors.grey[700]),
                    ),
                    selectedColor: const Color(0xFF4F46E5),
                    backgroundColor: isDark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  );
                }),
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            key: const Key('get_started_button'),
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              "Get Started",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
