import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/services/photo_download_service.dart';
import 'package:client/features/posts/data/models/post_models.dart';

class MockDio extends Mock implements Dio {}
class MockGallerySaver extends Mock implements GallerySaver {}
class MockPermissionChecker extends Mock implements PermissionChecker {}

void main() {
  late MockDio mockDio;
  late MockGallerySaver mockGallerySaver;
  late MockPermissionChecker mockPermissionChecker;
  late PhotoDownloadService service;

  final sampleBytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]); // PNG header bytes

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockDio = MockDio();
    mockGallerySaver = MockGallerySaver();
    mockPermissionChecker = MockPermissionChecker();

    service = PhotoDownloadService(
      dio: mockDio,
      gallerySaver: mockGallerySaver,
      permissionChecker: mockPermissionChecker,
    );
  });

  group('PhotoDownloadService Unit Tests', () {
    test('downloadPhoto returns success and writes bytes when access is granted', () async {
      when(() => mockGallerySaver.hasAccess()).thenAnswer((_) async => true);
      when(() => mockGallerySaver.putImageBytes(any(), name: any(named: 'name')))
          .thenAnswer((_) async {});

      final responseHeaders = Headers();
      responseHeaders.set(HttpHeaders.contentTypeHeader, 'image/png');

      when(
        () => mockDio.get<List<int>>(
          any(),
          options: any(named: 'options'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer(
        (_) async => Response<List<int>>(
          data: sampleBytes,
          statusCode: 200,
          headers: responseHeaders,
          requestOptions: RequestOptions(path: 'https://example.com/photo.png'),
        ),
      );

      final result = await service.downloadPhoto(
        url: 'https://example.com/photo.png',
        postId: 'p-12345678',
        mediaId: 'm-999',
      );

      expect(result.isSuccess, isTrue);
      expect(result.filename, contains('genz_p1234567_m999.png'));
      verify(() => mockGallerySaver.putImageBytes(any(), name: any(named: 'name'))).called(1);
    });

    test('downloadPhoto requests access when hasAccess is false and proceeds if granted', () async {
      when(() => mockGallerySaver.hasAccess()).thenAnswer((_) async => false);
      when(() => mockGallerySaver.requestAccess()).thenAnswer((_) async => true);
      when(() => mockGallerySaver.putImageBytes(any(), name: any(named: 'name')))
          .thenAnswer((_) async {});

      when(
        () => mockDio.get<List<int>>(
          any(),
          options: any(named: 'options'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer(
        (_) async => Response<List<int>>(
          data: sampleBytes,
          statusCode: 200,
          headers: Headers(),
          requestOptions: RequestOptions(path: 'https://example.com/photo.jpg'),
        ),
      );

      final result = await service.downloadPhoto(
        url: 'https://example.com/photo.jpg',
        postId: 'p-12345678',
      );

      expect(result.isSuccess, isTrue);
      verify(() => mockGallerySaver.requestAccess()).called(1);
      verify(() => mockGallerySaver.putImageBytes(any(), name: any(named: 'name'))).called(1);
    });

    test('downloadPhoto returns permissionDenied when requestAccess returns false', () async {
      when(() => mockGallerySaver.hasAccess()).thenAnswer((_) async => false);
      when(() => mockGallerySaver.requestAccess()).thenAnswer((_) async => false);
      when(() => mockPermissionChecker.isPermanentlyDenied()).thenAnswer((_) async => true);

      final result = await service.downloadPhoto(
        url: 'https://example.com/photo.jpg',
        postId: 'p-123',
      );

      expect(result.isSuccess, isFalse);
      expect(result.isPermissionDenied, isTrue);
      expect(result.isPermanentlyDenied, isTrue);
      verifyNever(() => mockDio.get<List<int>>(any(), options: any(named: 'options')));
    });

    test('downloadPhoto tracks progress during download', () async {
      when(() => mockGallerySaver.hasAccess()).thenAnswer((_) async => true);
      when(() => mockGallerySaver.putImageBytes(any(), name: any(named: 'name')))
          .thenAnswer((_) async {});

      when(
        () => mockDio.get<List<int>>(
          any(),
          options: any(named: 'options'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((invocation) async {
        final onReceiveProgress =
            invocation.namedArguments[#onReceiveProgress] as void Function(int, int)?;
        onReceiveProgress?.call(50, 100);
        onReceiveProgress?.call(100, 100);
        return Response<List<int>>(
          data: sampleBytes,
          statusCode: 200,
          headers: Headers(),
          requestOptions: RequestOptions(path: 'https://example.com/photo.jpg'),
        );
      });

      final recordedProgress = <double>[];
      final result = await service.downloadPhoto(
        url: 'https://example.com/photo.jpg',
        postId: 'p-123',
        onProgress: recordedProgress.add,
      );

      expect(result.isSuccess, isTrue);
      expect(recordedProgress, [0.5, 1.0]);
    });

    test('downloadPhoto returns failure on DioException timeout', () async {
      when(() => mockGallerySaver.hasAccess()).thenAnswer((_) async => true);
      when(
        () => mockDio.get<List<int>>(
          any(),
          options: any(named: 'options'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: 'https://example.com/photo.jpg'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      final result = await service.downloadPhoto(
        url: 'https://example.com/photo.jpg',
        postId: 'p-123',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('timed out'));
    });

    test('downloadAllPhotos downloads multiple photos and aggregates results', () async {
      when(() => mockGallerySaver.hasAccess()).thenAnswer((_) async => true);
      when(() => mockGallerySaver.putImageBytes(any(), name: any(named: 'name')))
          .thenAnswer((_) async {});

      when(
        () => mockDio.get<List<int>>(
          any(),
          options: any(named: 'options'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer(
        (_) async => Response<List<int>>(
          data: sampleBytes,
          statusCode: 200,
          headers: Headers(),
          requestOptions: RequestOptions(path: 'https://example.com/photo.jpg'),
        ),
      );

      final mediaList = [
        const MediaItemModel(id: 'm-1', url: 'https://example.com/1.jpg', mediaType: 'image'),
        const MediaItemModel(id: 'm-2', url: 'https://example.com/2.jpg', mediaType: 'image'),
      ];

      final results = await service.downloadAllPhotos(
        mediaList: mediaList,
        postId: 'p-multi-1',
      );

      expect(results.length, 2);
      expect(results.every((r) => r.isSuccess), isTrue);
      verify(() => mockGallerySaver.putImageBytes(any(), name: any(named: 'name'))).called(2);
    });
  });
}
