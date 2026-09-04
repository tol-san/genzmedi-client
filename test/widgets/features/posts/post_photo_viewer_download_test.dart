import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/services/photo_download_service.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/posts/presentation/screens/post_photo_viewer_screen.dart';

class MockPhotoDownloadService extends Mock implements PhotoDownloadService {}

void main() {
  late MockPhotoDownloadService mockDownloadService;

  const singleImagePost = PostModel(
    id: 'photo-post-1',
    author: PostAuthorModel(
      id: 'author-1',
      username: 'art_lover',
      displayName: 'Art Lover',
    ),
    content: 'Sunset over the ocean',
    media: [
      MediaItemModel(
        id: 'm-photo-1',
        mediaType: 'image',
        url: 'https://example.com/sunset.jpg',
      ),
    ],
  );

  const multiImagePost = PostModel(
    id: 'photo-post-multi',
    author: PostAuthorModel(
      id: 'author-2',
      username: 'travel_lens',
      displayName: 'Travel Lens',
    ),
    content: 'Weekend in Tokyo',
    media: [
      MediaItemModel(
        id: 'm-photo-1',
        mediaType: 'image',
        url: 'https://example.com/tokyo_1.jpg',
      ),
      MediaItemModel(
        id: 'm-photo-2',
        mediaType: 'image',
        url: 'https://example.com/tokyo_2.jpg',
      ),
    ],
  );

  setUp(() {
    mockDownloadService = MockPhotoDownloadService();
  });

  Widget buildTestableWidget(PostModel post) {
    return ProviderScope(
      overrides: [
        photoDownloadServiceProvider.overrideWithValue(mockDownloadService),
      ],
      child: MaterialApp(
        home: PostPhotoViewerScreen(post: post),
      ),
    );
  }

  group('PostPhotoViewerScreen Photo Download Widget Tests', () {
    testWidgets('triggers successful photo download and shows success snackbar', (tester) async {
      when(
        () => mockDownloadService.downloadPhoto(
          url: any(named: 'url'),
          postId: any(named: 'postId'),
          mediaId: any(named: 'mediaId'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((invocation) async {
        final onProgress =
            invocation.namedArguments[#onProgress] as void Function(double)?;
        onProgress?.call(0.65);
        return PhotoDownloadResult.success(filename: 'genz_photopos_mpho1.jpg');
      });

      await tester.pumpWidget(buildTestableWidget(singleImagePost));
      await tester.pumpAndSettle();

      // Tap options menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Save to phone'), findsOneWidget);

      // Tap Save to phone
      await tester.tap(find.text('Save to phone'));
      await tester.pump();

      // Verify downloadPhoto called
      verify(
        () => mockDownloadService.downloadPhoto(
          url: 'https://example.com/sunset.jpg',
          postId: 'photo-post-1',
          mediaId: 'm-photo-1',
          onProgress: any(named: 'onProgress'),
        ),
      ).called(1);

      await tester.pumpAndSettle();

      // Verify success snackbar
      expect(find.textContaining('Photo saved to gallery'), findsOneWidget);
    });

    testWidgets('shows permission denied message and settings action when permanently denied', (tester) async {
      when(
        () => mockDownloadService.downloadPhoto(
          url: any(named: 'url'),
          postId: any(named: 'postId'),
          mediaId: any(named: 'mediaId'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer(
        (_) async => PhotoDownloadResult.permissionDenied(isPermanentlyDenied: true),
      );
      when(() => mockDownloadService.openSettings()).thenAnswer((_) async => true);

      await tester.pumpWidget(buildTestableWidget(singleImagePost));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save to phone'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Photo library access was denied'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      verify(() => mockDownloadService.openSettings()).called(1);
    });

    testWidgets('shows failure snackbar with Retry action when download fails', (tester) async {
      var callCount = 0;
      when(
        () => mockDownloadService.downloadPhoto(
          url: any(named: 'url'),
          postId: any(named: 'postId'),
          mediaId: any(named: 'mediaId'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return PhotoDownloadResult.failure(errorMessage: 'Network timeout.');
        }
        return PhotoDownloadResult.success(filename: 'genz_retried.jpg');
      });

      await tester.pumpWidget(buildTestableWidget(singleImagePost));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save to phone'));
      await tester.pumpAndSettle();

      expect(find.text('Network timeout.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Tap Retry
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(callCount, 2);
      expect(find.textContaining('Photo saved to gallery'), findsOneWidget);
    });

    testWidgets('shows Save this photo and Save all photos for multi-image posts', (tester) async {
      when(
        () => mockDownloadService.downloadAllPhotos(
          mediaList: any(named: 'mediaList'),
          postId: any(named: 'postId'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer(
        (_) async => [
          PhotoDownloadResult.success(filename: 'photo1.jpg'),
          PhotoDownloadResult.success(filename: 'photo2.jpg'),
        ],
      );

      await tester.pumpWidget(buildTestableWidget(multiImagePost));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Save this photo'), findsOneWidget);
      expect(find.text('Save all photos (2)'), findsOneWidget);

      await tester.tap(find.text('Save all photos (2)'));
      await tester.pumpAndSettle();

      verify(
        () => mockDownloadService.downloadAllPhotos(
          mediaList: any(named: 'mediaList'),
          postId: 'photo-post-multi',
          onProgress: any(named: 'onProgress'),
        ),
      ).called(1);

      expect(find.text('All 2 photos saved to gallery!'), findsOneWidget);
    });
  });
}
