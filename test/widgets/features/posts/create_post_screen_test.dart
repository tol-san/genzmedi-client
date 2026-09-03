import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/features/posts/data/repositories/post_repository.dart';
import 'package:client/features/posts/presentation/notifiers/create_post_notifier.dart';
import 'package:client/features/posts/presentation/notifiers/create_post_state.dart';
import 'package:client/features/posts/presentation/screens/create_post_screen.dart';

class MockPostRepository extends Mock implements PostRepository {}

void main() {
  late MockPostRepository mockPostRepository;

  setUp(() {
    mockPostRepository = MockPostRepository();
  });

  Widget buildTestWidget({
    String initialType = 'text',
    CreatePostState? initialState,
  }) {
    return ProviderScope(
      overrides: [
        postRepositoryProvider.overrideWithValue(mockPostRepository),
        if (initialState != null)
          createPostNotifierProvider.overrideWith(
            (ref) => FakeCreatePostNotifier(
              repository: mockPostRepository,
              initialState: initialState,
            ),
          ),
      ],
      child: MaterialApp(home: CreatePostScreen(initialPostType: initialType)),
    );
  }

  group('CreatePostScreen Widget Tests', () {
    testWidgets('renders segmented type switcher and content inputs', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Short'), findsOneWidget);
      expect(find.text('Post Content'), findsOneWidget);
      expect(find.text('Publish post'), findsOneWidget);
      expect(find.text('Your draft stays while you create'), findsOneWidget);
    });

    testWidgets(
      'switches to photos tab and displays photo picker placeholder',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Photos'));
        await tester.pumpAndSettle();

        expect(find.text('Select Photos from Gallery'), findsOneWidget);
        expect(
          find.text('Choose up to 10 images for your carousel'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'switches to short video tab and displays video picker placeholder',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Short'));
        await tester.pumpAndSettle();

        expect(find.text('Select Video from Gallery'), findsOneWidget);
        expect(
          find.text('Vertical videos work best for Shorts'),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders upload progress bar and status when uploading media', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          initialState: const CreatePostState(
            postType: 'image',
            isUploadingMedia: true,
            uploadProgress: 0.65,
            uploadStatusText: 'Uploading photo 2 of 3 (65%)',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Uploading photo 2 of 3 (65%)'), findsOneWidget);
      expect(find.text('65%'), findsWidgets);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
        find.text('Keep this screen open until publishing is complete.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders community badge when community is provided and allows clearing',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              postRepositoryProvider.overrideWithValue(mockPostRepository),
            ],
            child: const MaterialApp(
              home: CreatePostScreen(
                initialPostType: 'text',
                communityId: 'comm-123',
                communityName: 'FlutterDevs',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Posting to: FlutterDevs'), findsOneWidget);

        // Tap clear icon on the badge
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Posting to: FlutterDevs'), findsNothing);
      },
    );
  });
}

class FakeCreatePostNotifier extends CreatePostNotifier {
  FakeCreatePostNotifier({
    required super.repository,
    required CreatePostState initialState,
  }) {
    state = initialState;
  }
}
