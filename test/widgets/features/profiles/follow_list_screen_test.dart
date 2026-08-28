import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/features/profiles/data/repositories/profile_repository.dart';
import 'package:client/features/profiles/presentation/screens/follow_list_screen.dart';
import 'package:client/features/profiles/presentation/widgets/user_tile_widget.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class AuthNotifierMock extends StateNotifier<AuthState> implements AuthNotifier {
  AuthNotifierMock(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockProfileRepository mockRepository;

  const mockCurrentUser = UserModel(
    id: 'u-self',
    username: 'self_user',
    email: 'self@example.com',
  );

  const mockUser1 = UserModel(
    id: 'u-1',
    username: 'alex_creator',
    email: 'alex@example.com',
    displayName: 'Alex Creator',
    followersCount: 10,
    followingCount: 5,
  );

  const mockUser2 = UserModel(
    id: 'u-2',
    username: 'sam_designer',
    email: 'sam@example.com',
    displayName: 'Sam Designer',
    followersCount: 20,
    followingCount: 15,
  );

  setUp(() {
    mockRepository = MockProfileRepository();
  });

  Widget createTestWidget({int initialTabIndex = 0}) {
    return ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockRepository),
        authNotifierProvider.overrideWith(
          (ref) => AuthNotifierMock(const AuthAuthenticated(mockCurrentUser)),
        ),
      ],
      child: MaterialApp(
        home: FollowListScreen(
          userId: 'u-target',
          username: 'janedoe',
          initialTabIndex: initialTabIndex,
        ),
      ),
    );
  }

  group('FollowListScreen Widget Tests', () {
    testWidgets('renders app bar with handle and tab bars with counts', (tester) async {
      when(() => mockRepository.getFollowers('u-target', limit: 20, offset: 0))
          .thenAnswer((_) async => [mockUser1]);
      when(() => mockRepository.getFollowing('u-target', limit: 20, offset: 0))
          .thenAnswer((_) async => [mockUser2]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('@janedoe'), findsOneWidget);
      expect(find.text('Followers (1)'), findsOneWidget);
      expect(find.text('Following (1)'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Alex Creator'), findsOneWidget);
    });

    testWidgets('switches to Following tab and displays following users', (tester) async {
      when(() => mockRepository.getFollowers('u-target', limit: 20, offset: 0))
          .thenAnswer((_) async => [mockUser1]);
      when(() => mockRepository.getFollowing('u-target', limit: 20, offset: 0))
          .thenAnswer((_) async => [mockUser2]);

      await tester.pumpWidget(createTestWidget(initialTabIndex: 1));
      await tester.pumpAndSettle();

      expect(find.text('Sam Designer'), findsOneWidget);
      expect(find.text('@sam_designer'), findsOneWidget);
    });

    testWidgets('search bar filters list content dynamically', (tester) async {
      when(() => mockRepository.getFollowers('u-target', limit: 20, offset: 0))
          .thenAnswer((_) async => [mockUser1, mockUser2]);
      when(() => mockRepository.getFollowing('u-target', limit: 20, offset: 0))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(UserTileWidget), findsNWidgets(2));

      await tester.enterText(find.byType(TextField), 'alex');
      await tester.pumpAndSettle();

      expect(find.text('Alex Creator'), findsOneWidget);
      expect(find.text('Sam Designer'), findsNothing);
    });

    testWidgets('displays empty state when list has no users', (tester) async {
      when(() => mockRepository.getFollowers('u-target', limit: 20, offset: 0))
          .thenAnswer((_) async => []);
      when(() => mockRepository.getFollowing('u-target', limit: 20, offset: 0))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No followers yet'), findsOneWidget);
    });
  });
}
