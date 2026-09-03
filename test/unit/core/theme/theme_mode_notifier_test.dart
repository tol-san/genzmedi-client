import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/core/theme/theme_mode_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeModeNotifier Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to ThemeMode.system when no preference is saved', () {
      final notifier = ThemeModeNotifier();
      expect(notifier.state, ThemeMode.system);
    });

    test('loads saved theme mode from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
      final notifier = ThemeModeNotifier();
      // Allow async SharedPreferences load to settle
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state, ThemeMode.dark);
    });

    test('setThemeMode updates state and persists to SharedPreferences', () async {
      final notifier = ThemeModeNotifier();
      await notifier.setThemeMode(ThemeMode.light);

      expect(notifier.state, ThemeMode.light);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'light');

      await notifier.setThemeMode(ThemeMode.dark);
      expect(notifier.state, ThemeMode.dark);
      expect(prefs.getString('app_theme_mode'), 'dark');
    });
  });
}
