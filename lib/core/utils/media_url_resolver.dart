import 'package:flutter/foundation.dart';

/// Resolves a media URL, ensuring that loopback host addresses (localhost / 127.0.0.1)
/// are correctly routed to the host machine IP (10.0.2.2) when running inside the Android emulator.
String? resolveMediaUrl(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  var trimmed = url.trim();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    if (trimmed.contains('http://localhost:9000')) {
      trimmed = trimmed.replaceAll(
        'http://localhost:9000',
        'http://10.0.2.2:9000',
      );
    } else if (trimmed.contains('http://127.0.0.1:9000')) {
      trimmed = trimmed.replaceAll(
        'http://127.0.0.1:9000',
        'http://10.0.2.2:9000',
      );
    } else if (trimmed.contains('http://localhost:8000')) {
      trimmed = trimmed.replaceAll(
        'http://localhost:8000',
        'http://10.0.2.2:8000',
      );
    } else if (trimmed.contains('http://127.0.0.1:8000')) {
      trimmed = trimmed.replaceAll(
        'http://127.0.0.1:8000',
        'http://10.0.2.2:8000',
      );
    }
  }

  return trimmed;
}
