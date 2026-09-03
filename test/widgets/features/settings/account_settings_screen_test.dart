import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/core/theme/theme_mode_notifier.dart';
import 'package:client/features/settings/presentation/screens/account_settings_screen.dart';

Widget _buildTestableWidget({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      home: AccountSettingsScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AccountSettingsScreen Widget Tests', () {
    testWidgets('renders all core settings sections and items', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestableWidget());
      await tester.pumpAndSettle();

      // Check section titles
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Account Management'), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Active Sessions & Devices'), findsOneWidget);
      expect(find.text('Privacy Settings'), findsOneWidget);
      expect(find.text('Blocked Accounts'), findsOneWidget);
      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Community Guidelines'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('tapping Appearance opens theme selection modal and changes mode', (tester) async {
      final notifier = ThemeModeNotifier();

      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            themeModeProvider.overrideWith((ref) => notifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap Appearance tile
      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();

      // Modal is visible
      expect(find.text('Choose Theme'), findsOneWidget);
      expect(find.text('Light Mode'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);

      // Tap Dark Mode
      await tester.tap(find.text('Dark Mode'));
      await tester.pumpAndSettle();

      expect(notifier.state, ThemeMode.dark);
    });

    testWidgets('tapping Community Guidelines opens legal bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Community Guidelines'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Welcome to GenZ Media!'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);

      // Dismiss
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Welcome to GenZ Media!'), findsNothing);
    });

    testWidgets('tapping Sign Out shows confirmation dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to sign out of GenZ Media?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to sign out of GenZ Media?'), findsNothing);
    });
  });
}

