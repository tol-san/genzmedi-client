import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/profiles/data/repositories/profile_repository.dart';
import 'package:client/features/profiles/presentation/screens/edit_profile_screen.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository mockProfileRepository;

  const testUser = UserModel(
    id: 'u-123',
    username: 'alex_creator',
    email: 'alex@example.com',
    displayName: 'Alex Creator',
    bio: 'Digital content & UI builder',
    interests: ['gaming', 'music'],
  );

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    when(() => mockProfileRepository.getInterests()).thenAnswer(
      (_) async => const [
        InterestModel(id: 'i-1', name: 'gaming', slug: 'gaming', icon: '🎮'),
        InterestModel(id: 'i-2', name: 'music', slug: 'music', icon: '🎵'),
        InterestModel(id: 'i-3', name: 'art', slug: 'art', icon: '🎨'),
      ],
    );
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockProfileRepository),
        authNotifierProvider.overrideWith(
          (ref) => AuthNotifierMock(const AuthAuthenticated(testUser)),
        ),
      ],
      child: const MaterialApp(
        home: EditProfileScreen(),
      ),
    );
  }

  group('EditProfileScreen Widget Tests', () {
    testWidgets('renders input fields with user initial data', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Change Photo'), findsOneWidget);

      expect(find.text('Alex Creator'), findsOneWidget);
      expect(find.text('alex_creator'), findsOneWidget);
      expect(find.text('Digital content & UI builder'), findsOneWidget);

      expect(find.text('#gaming'), findsOneWidget);
      expect(find.text('#music'), findsOneWidget);
    });

    testWidgets('opens interests sheet when tapping + Add / Edit', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final addInterestsBtn = find.text('+ Add / Edit');
      expect(addInterestsBtn, findsOneWidget);

      await tester.tap(addInterestsBtn);
      await tester.pumpAndSettle();

      expect(find.text('Select Interests'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });
  });
}

class AuthNotifierMock extends StateNotifier<AuthState> implements AuthNotifier {
  AuthNotifierMock(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
