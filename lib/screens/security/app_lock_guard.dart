import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:local_auth/local_auth.dart';
import '../../providers/settings_provider.dart';
import '../../router.dart';

class AppLockGuard extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockGuard({super.key, required this.child});

  @override
  ConsumerState<AppLockGuard> createState() => _AppLockGuardState();
}

class _AppLockGuardState extends ConsumerState<AppLockGuard>
    with WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isLocked = false;
  bool _authenticating = false;
  String _authError = '';
  bool _pausedByAuth = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Consolidate startup app locking in AppLockGuard
    final settings = ref.read(settingsProvider);
    final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (settings.isOnboardingComplete && settings.biometricEnabled && !isTest) {
      _isLocked = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final currentPath = goRouter.routerDelegate.currentConfiguration.uri.path;
    if (currentPath == '/splash' || currentPath == '/onboarding') {
      return;
    }

    final settings = ref.read(settingsProvider);
    if (!settings.isOnboardingComplete || !settings.biometricEnabled) {
      return;
    }

    if (state == AppLifecycleState.paused) {
      if (_authenticating) {
        _pausedByAuth = true;
      } else {
        setState(() {
          _isLocked = true;
          _pausedByAuth = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedByAuth) {
        _pausedByAuth = false;
        return;
      }
      if (_isLocked && !_authenticating) {
        _authenticate();
      }
    }
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _authError = '';
    });

    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Unlock BudgetWise to access your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (didAuthenticate) {
        setState(() {
          _isLocked = false;
          _authenticating = false;
        });
      } else {
        setState(() {
          _authenticating = false;
          _authError = 'Authentication failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _authenticating = false;
        _authError = 'Could not authenticate: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = goRouter.routerDelegate.currentConfiguration.uri.path;
    if (currentPath == '/splash' || currentPath == '/onboarding') {
      return widget.child;
    }

    if (_isLocked) {
      if (!_authenticating && _authError.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _authenticate();
        });
      }

      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF0F172A)
              : const Color(0xFFF8F9FA),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lock Icon Container
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFF59E0B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.lock,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Heading
                  Text(
                    'App Locked',
                    style: GoogleFonts.outfit(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  Text(
                    'BudgetWise is locked to secure your financial information.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Trigger Button
                  ElevatedButton.icon(
                    onPressed: _authenticate,
                    icon: Icon(
                      _authenticating
                          ? LucideIcons.loader
                          : LucideIcons.fingerprint,
                      size: 20,
                    ),
                    label: Text(
                      _authenticating
                          ? 'Authenticating...'
                          : 'Unlock Application',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                  if (_authError.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      _authError,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
