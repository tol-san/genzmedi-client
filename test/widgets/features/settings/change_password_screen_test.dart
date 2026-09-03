import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/features/settings/data/repositories/settings_repository.dart';
import 'package:client/features/settings/presentation/screens/change_password_screen.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

Widget _buildTestableWidget({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      home: ChangePasswordScreen(),
    ),
  );
}

void main() {
  late MockSettingsRepository mockRepo;

  setUp(() {
    mockRepo = MockSettingsRepository();
  });

  group('ChangePasswordScreen Widget Tests', () {
    testWidgets('renders all fields and validation headers', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Protect your account'), findsOneWidget);
      expect(find.text('Current password'), findsOneWidget);
      expect(find.text('New password'), findsOneWidget);
      expect(find.text('Confirm new password'), findsOneWidget);
      expect(find.text('Update Password'), findsOneWidget);
    });

    testWidgets('shows validation error when fields are empty', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap submit without filling fields
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your current password.'), findsOneWidget);
      verifyZeroInteractions(mockRepo);
    });
  });
}
