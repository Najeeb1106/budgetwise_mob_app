import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'transaction/add_transaction_sheet.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: navigationShell,
      floatingActionButton: Semantics(
        label: 'Add transaction',
        button: true,
        child: FloatingActionButton(
          heroTag: 'main_add_transaction_fab',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddTransactionSheet(),
            );
          },
          backgroundColor: const Color(0xFF4F46E5),
          elevation: 6,
          shape: const CircleBorder(),
          child: const Icon(LucideIcons.plus, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        clipBehavior: Clip.antiAlias,
        elevation: 12,
        padding: EdgeInsets.zero,
        height: 64,
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Row(
          children: [
            // Home Tab
            _buildTabItem(
              index: 0,
              icon: LucideIcons.layoutDashboard,
              label: 'Home',
              isSelected: navigationShell.currentIndex == 0,
              isDark: isDark,
            ),
            // Budgets Tab
            _buildTabItem(
              index: 1,
              icon: LucideIcons.pieChart,
              label: 'Budgets',
              isSelected: navigationShell.currentIndex == 1,
              isDark: isDark,
            ),
            // Center notch spacer
            const SizedBox(width: 72),
            // Analytics Tab
            _buildTabItem(
              index: 2,
              icon: LucideIcons.barChart3,
              label: 'Analytics',
              isSelected: navigationShell.currentIndex == 2,
              isDark: isDark,
            ),
            // Goals Tab
            _buildTabItem(
              index: 3,
              icon: LucideIcons.piggyBank,
              label: 'Goals',
              isSelected: navigationShell.currentIndex == 3,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
  }) {
    final activeColor = const Color(0xFF4F46E5);
    final inactiveColor = isDark
        ? const Color(0xCBD5E1FF)
        : const Color(0xFF4B5563);

    return Expanded(
      child: Semantics(
        label: '$label tab',
        button: true,
        selected: isSelected,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => _onTap(index),
            borderRadius: BorderRadius.circular(16),
            hoverColor: activeColor.withValues(alpha: 0.08),
            splashColor: activeColor.withValues(alpha: 0.15),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? activeColor.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isSelected ? activeColor : inactiveColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? activeColor : inactiveColor,
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
