import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/posts/data/repositories/post_repository.dart';
import 'package:client/features/posts/presentation/notifiers/create_post_notifier.dart';

class MockPostRepository extends Mock implements PostRepository {}

class FakePostCreateRequestModel extends Fake
    implements PostCreateRequestModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakePostCreateRequestModel());
    registerFallbackValue(File('test.jpg'));
  });

  late MockPostRepository mockRepository;

  const mockCreatedPost = PostModel(
    id: 'p-new-1',
    author: PostAuthorModel(id: 'u-1', username: 'alex', displayName: 'Alex'),
    title: 'My First Post',
    content: 'Excited to be here on GenZ Media!',
    visibility: 'public',
  );

  const mockMediaUpload = MediaUploadModel(
    url: 'https://example.com/media.jpg',
    mediaType: 'image',
    width: 1080,
    height: 1080,
  );

  setUp(() {
    mockRepository = MockPostRepository();
  });

  group('CreatePostNotifier Unit Tests', () {
    test('updates title, content, visibility, and post type', () {
      final notifier = CreatePostNotifier(repository: mockRepository);

      notifier.setPostType('image');
      expect(notifier.state.postType, 'image');

      notifier.setTitle('Awesome Title');
      expect(notifier.state.title, 'Awesome Title');

      notifier.setContent('This is the content');
      expect(notifier.state.content, 'This is the content');

      notifier.setVisibility('followers_only');
      expect(notifier.state.visibility, 'followers_only');
    });

    test('validates empty inputs and sets error message', () async {
      final notifier = CreatePostNotifier(repository: mockRepository);

      final success = await notifier.submitPost();
      expect(success, isFalse);
      expect(notifier.state.errorMessage, isNotNull);
    });

    test('submits valid text post successfully', () async {
      when(() => mockRepository.createPost(any()))
          .thenAnswer((_) async => mockCreatedPost);

      final notifier = CreatePostNotifier(repository: mockRepository);
      notifier.setTitle('My First Post');
      notifier.setContent('Excited to be here on GenZ Media!');

      final success = await notifier.submitPost();
      expect(success, isTrue);
      expect(notifier.state.isSuccess, isTrue);
      expect(notifier.state.createdPost?.id, 'p-new-1');
      verify(() => mockRepository.createPost(any())).called(1);
    });

    test('uploads image media and tracks progress', () async {
      when(() => mockRepository.uploadMedia(
            any(),
            mediaType: any(named: 'mediaType'),
            onSendProgress: any(named: 'onSendProgress'),
          )).thenAnswer((invocation) async {
        final onSendProgress =
            invocation.namedArguments[#onSendProgress] as dynamic;
        if (onSendProgress != null) {
          onSendProgress(500, 1000);
        }
        return mockMediaUpload;
      });

      when(() => mockRepository.createPost(any()))
          .thenAnswer((_) async => mockCreatedPost);

      final notifier = CreatePostNotifier(repository: mockRepository);
      notifier.addImages([File('test1.jpg')]);
      notifier.setContent('Check out my picture');

      final success = await notifier.submitPost();
      expect(success, isTrue);
      expect(notifier.state.isSuccess, isTrue);
      expect(notifier.state.uploadProgress, 1.0);
      verify(() => mockRepository.uploadMedia(
            any(),
            mediaType: 'image',
            onSendProgress: any(named: 'onSendProgress'),
          )).called(1);
    });
  });
}
