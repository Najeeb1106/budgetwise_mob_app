import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'database_provider.dart';

class AppSettings {
  final String username;
  final String currency;
  final String themeMode; // 'light' | 'dark' | 'system'
  final double estimatedIncome;
  final bool includeSalaryInBalance;
  final bool isOnboardingComplete;
  final bool biometricEnabled;
  final bool budgetAlertsEnabled;
  final bool weeklySummaryEnabled;
  final bool goalRemindersEnabled;

  AppSettings({
    required this.username,
    required this.currency,
    required this.themeMode,
    required this.estimatedIncome,
    required this.includeSalaryInBalance,
    required this.isOnboardingComplete,
    required this.biometricEnabled,
    this.budgetAlertsEnabled = true,
    this.weeklySummaryEnabled = true,
    this.goalRemindersEnabled = true,
  });

  AppSettings copyWith({
    String? username,
    String? currency,
    String? themeMode,
    double? estimatedIncome,
    bool? includeSalaryInBalance,
    bool? isOnboardingComplete,
    bool? biometricEnabled,
    bool? budgetAlertsEnabled,
    bool? weeklySummaryEnabled,
    bool? goalRemindersEnabled,
  }) {
    return AppSettings(
      username: username ?? this.username,
      currency: currency ?? this.currency,
      themeMode: themeMode ?? this.themeMode,
      estimatedIncome: estimatedIncome ?? this.estimatedIncome,
      includeSalaryInBalance:
          includeSalaryInBalance ?? this.includeSalaryInBalance,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
      goalRemindersEnabled: goalRemindersEnabled ?? this.goalRemindersEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'username': username,
    'currency': currency,
    'themeMode': themeMode,
    'estimatedIncome': estimatedIncome,
    'includeSalaryInBalance': includeSalaryInBalance,
    'isOnboardingComplete': isOnboardingComplete,
    'biometricEnabled': biometricEnabled,
    'budgetAlertsEnabled': budgetAlertsEnabled,
    'weeklySummaryEnabled': weeklySummaryEnabled,
    'goalRemindersEnabled': goalRemindersEnabled,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    username: json['username'] ?? '',
    currency: json['currency'] ?? 'USD',
    themeMode: json['themeMode'] ?? 'system',
    estimatedIncome: (json['estimatedIncome'] ?? 0.0) as double,
    includeSalaryInBalance: json['includeSalaryInBalance'] ?? true,
    isOnboardingComplete: json['isOnboardingComplete'] ?? false,
    biometricEnabled: json['biometricEnabled'] ?? false,
    budgetAlertsEnabled: json['budgetAlertsEnabled'] ?? true,
    weeklySummaryEnabled: json['weeklySummaryEnabled'] ?? true,
    goalRemindersEnabled: json['goalRemindersEnabled'] ?? true,
  );

  factory AppSettings.defaultSettings() => AppSettings(
    username: '',
    currency: 'USD',
    themeMode: 'system',
    estimatedIncome: 0.0,
    includeSalaryInBalance: true,
    isOnboardingComplete: false,
    biometricEnabled: false,
    budgetAlertsEnabled: true,
    weeklySummaryEnabled: true,
    goalRemindersEnabled: true,
  );
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final _storage = const FlutterSecureStorage();
  static const _settingsKey = 'secure_app_settings';

  SettingsNotifier() : super(AppSettings.defaultSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    try {
      final jsonStr = await _storage.read(key: _settingsKey);
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        state = AppSettings.fromJson(json);
      } else {
        // Migration path: if old plain file exists, migrate it, then delete it
        final directory = await getApplicationDocumentsDirectory();
        final file = File(p.join(directory.path, 'budgetwise_settings.json'));
        if (await file.exists()) {
          final contents = await file.readAsString();
          final json = jsonDecode(contents) as Map<String, dynamic>;
          state = AppSettings.fromJson(json);
          await _storage.write(
            key: _settingsKey,
            value: jsonEncode(state.toJson()),
          );
          await file.delete();
        }
      }
    } catch (_) {
      // Keep defaults on failure
    }
  }

  Future<void> updateSettings({
    String? username,
    String? currency,
    String? themeMode,
    double? estimatedIncome,
    bool? includeSalaryInBalance,
    bool? isOnboardingComplete,
    bool? biometricEnabled,
    bool? budgetAlertsEnabled,
    bool? weeklySummaryEnabled,
    bool? goalRemindersEnabled,
  }) async {
    state = state.copyWith(
      username: username,
      currency: currency,
      themeMode: themeMode,
      estimatedIncome: estimatedIncome,
      includeSalaryInBalance: includeSalaryInBalance,
      isOnboardingComplete: isOnboardingComplete,
      biometricEnabled: biometricEnabled,
      budgetAlertsEnabled: budgetAlertsEnabled,
      weeklySummaryEnabled: weeklySummaryEnabled,
      goalRemindersEnabled: goalRemindersEnabled,
    );
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    try {
      await _storage.write(
        key: _settingsKey,
        value: jsonEncode(state.toJson()),
      );
    } catch (_) {}
  }

  ThemeMode get themeModeEnum {
    switch (state.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> clearAllData(WidgetRef ref) async {
    // Reset settings
    state = AppSettings.defaultSettings();
    try {
      await _storage.delete(key: _settingsKey);
      await _storage.delete(key: 'secure_db_key');
    } catch (_) {}

    // Close and completely delete SQLite database file and sidecars
    try {
      final db = ref.read(databaseProvider);
      await db.close();

      // Invalidate the provider so Riverpod releases the closed instance and will instantiate a fresh one
      ref.invalidate(databaseProvider);

      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, 'budgetwise.sqlite'));
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      final journalFile = File('${dbFile.path}-journal');
      if (await journalFile.exists()) {
        await journalFile.delete();
      }

      final walFile = File('${dbFile.path}-wal');
      if (await walFile.exists()) {
        await walFile.delete();
      }

      final shmFile = File('${dbFile.path}-shm');
      if (await shmFile.exists()) {
        await shmFile.delete();
      }
    } catch (_) {}
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier();
});
