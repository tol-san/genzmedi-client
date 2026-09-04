import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:client/core/network/api_client.dart';
import 'package:client/core/utils/media_url_resolver.dart';
import 'package:client/features/posts/data/models/post_models.dart';

/// Abstract adapter for saving image bytes to the platform photo library.
abstract class GallerySaver {
  Future<bool> hasAccess();
  Future<bool> requestAccess();
  Future<void> putImageBytes(Uint8List bytes, {required String name});
}

class DefaultGallerySaver implements GallerySaver {
  const DefaultGallerySaver();

  @override
  Future<bool> hasAccess() async {
    try {
      return await Gal.hasAccess(toAlbum: false);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestAccess() async {
    try {
      return await Gal.requestAccess(toAlbum: false);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> putImageBytes(Uint8List bytes, {required String name}) async {
    await Gal.putImageBytes(bytes, name: name);
  }
}

/// Abstract adapter for querying deep system permission settings.
abstract class PermissionChecker {
  Future<bool> isPermanentlyDenied();
  Future<bool> openSettings();
}

class DefaultPermissionChecker implements PermissionChecker {
  const DefaultPermissionChecker();

  @override
  Future<bool> isPermanentlyDenied() async {
    try {
      final photosStatus = await ph.Permission.photos.status;
      if (photosStatus.isPermanentlyDenied) return true;
      final storageStatus = await ph.Permission.storage.status;
      return storageStatus.isPermanentlyDenied;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> openSettings() async {
    try {
      return await ph.openAppSettings();
    } catch (_) {
      return false;
    }
  }
}

/// Result model for photo download and gallery save operations.
class PhotoDownloadResult {
  final bool isSuccess;
  final String? filename;
  final String? errorMessage;
  final bool isPermissionDenied;
  final bool isPermanentlyDenied;

  const PhotoDownloadResult._({
    required this.isSuccess,
    this.filename,
    this.errorMessage,
    this.isPermissionDenied = false,
    this.isPermanentlyDenied = false,
  });

  factory PhotoDownloadResult.success({required String filename}) {
    return PhotoDownloadResult._(isSuccess: true, filename: filename);
  }

  factory PhotoDownloadResult.permissionDenied({
    bool isPermanentlyDenied = false,
  }) {
    return PhotoDownloadResult._(
      isSuccess: false,
      errorMessage:
          'Photo library access was denied. Please grant permission to save photos to your gallery.',
      isPermissionDenied: true,
      isPermanentlyDenied: isPermanentlyDenied,
    );
  }

  factory PhotoDownloadResult.failure({required String errorMessage}) {
    return PhotoDownloadResult._(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}

/// Service that handles downloading original-resolution media and saving it
/// directly into the device's native photo gallery.
class PhotoDownloadService {
  final Dio dio;
  final GallerySaver gallerySaver;
  final PermissionChecker permissionChecker;

  PhotoDownloadService({
    required this.dio,
    this.gallerySaver = const DefaultGallerySaver(),
    this.permissionChecker = const DefaultPermissionChecker(),
  });

  /// Downloads a single photo from [url] and writes it to device gallery.
  Future<PhotoDownloadResult> downloadPhoto({
    required String url,
    required String postId,
    String? mediaId,
    void Function(double progress)? onProgress,
  }) async {
    final rawUrl = resolveMediaUrl(url);
    if (rawUrl == null || rawUrl.isEmpty) {
      return PhotoDownloadResult.failure(errorMessage: 'Invalid or missing media URL.');
    }

    // 1. Verify and request gallery write access
    final hasAccess = await gallerySaver.hasAccess();
    if (!hasAccess) {
      final granted = await gallerySaver.requestAccess();
      if (!granted) {
        final isPermanentlyDenied =
            await permissionChecker.isPermanentlyDenied();
        return PhotoDownloadResult.permissionDenied(
          isPermanentlyDenied: isPermanentlyDenied,
        );
      }
    }

    try {
      // 2. Stream bytes using Dio with receive progress callback
      final response = await dio.get<List<int>>(
        rawUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 15),
        ),
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            final progress = (received / total).clamp(0.0, 1.0);
            onProgress(progress);
          }
        },
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        return PhotoDownloadResult.failure(
          errorMessage: 'Downloaded image was empty or corrupt.',
        );
      }

      // 3. Determine file extension and generate safe, unique filename
      final ext = _detectExtension(rawUrl, response.headers.value(HttpHeaders.contentTypeHeader));
      final safePostId = postId.replaceAll('-', '');
      final shortPostId = safePostId.substring(0, min(8, safePostId.length));
      final cleanedMediaId = mediaId?.replaceAll('-', '');
      final safeMediaId = (cleanedMediaId != null && cleanedMediaId.isNotEmpty)
          ? cleanedMediaId.substring(0, min(6, cleanedMediaId.length))
          : DateTime.now().millisecondsSinceEpoch.toString();
      final filename = 'genz_${shortPostId}_$safeMediaId.$ext';

      // 4. Write image bytes to gallery
      await gallerySaver.putImageBytes(
        Uint8List.fromList(bytes),
        name: filename,
      );

      return PhotoDownloadResult.success(filename: filename);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return PhotoDownloadResult.failure(
          errorMessage: 'Download timed out. Please check your connection and retry.',
        );
      }
      return PhotoDownloadResult.failure(
        errorMessage: 'Failed to download photo: ${e.message ?? "Network error"}',
      );
    } on GalException catch (e) {
      return PhotoDownloadResult.failure(
        errorMessage: 'Failed to save to gallery: ${e.type.message}',
      );
    } catch (e) {
      return PhotoDownloadResult.failure(
        errorMessage: 'An unexpected error occurred while saving photo: $e',
      );
    }
  }

  /// Downloads all photos in [mediaList] sequentially with aggregate progress.
  Future<List<PhotoDownloadResult>> downloadAllPhotos({
    required List<MediaItemModel> mediaList,
    required String postId,
    void Function(int completed, int total, double currentProgress)? onProgress,
  }) async {
    final results = <PhotoDownloadResult>[];
    final total = mediaList.length;

    for (var i = 0; i < total; i++) {
      final media = mediaList[i];
      final url = media.url;
      if (url.isEmpty) continue;

      final result = await downloadPhoto(
        url: url,
        postId: postId,
        mediaId: media.id,
        onProgress: (p) {
          if (onProgress != null) {
            onProgress(i, total, p);
          }
        },
      );
      results.add(result);

      // If user denied permission on the first image, abort further downloads
      if (result.isPermissionDenied) {
        break;
      }
    }

    return results;
  }

  /// Direct helper to launch system app settings if permission is permanently blocked.
  Future<bool> openSettings() => permissionChecker.openSettings();

  String _detectExtension(String url, String? contentType) {
    if (contentType != null) {
      final ct = contentType.toLowerCase();
      if (ct.contains('image/png')) return 'png';
      if (ct.contains('image/webp')) return 'webp';
      if (ct.contains('image/gif')) return 'gif';
      if (ct.contains('image/jpeg') || ct.contains('image/jpg')) return 'jpg';
    }

    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();
      if (path.endsWith('.png')) return 'png';
      if (path.endsWith('.webp')) return 'webp';
      if (path.endsWith('.gif')) return 'gif';
      if (path.endsWith('.jpeg') || path.endsWith('.jpg')) return 'jpg';
    } catch (_) {}

    return 'jpg';
  }
}

/// Global Riverpod provider for PhotoDownloadService.
final photoDownloadServiceProvider = Provider<PhotoDownloadService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return PhotoDownloadService(dio: dio);
});
