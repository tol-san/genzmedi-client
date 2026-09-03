import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:client/core/network/api_client.dart';
import 'package:client/core/network/api_endpoints.dart';
import 'package:client/features/notifications/data/repositories/notification_repository.dart';

final notificationRealtimeServiceProvider =
    AutoDisposeProvider<NotificationRealtimeService>((ref) {
      final service = NotificationRealtimeService(
        repository: ref.watch(notificationRepositoryProvider),
        dio: ref.watch(dioClientProvider),
      );
      ref.onDispose(service.dispose);
      return service;
    });

class NotificationRealtimeService {
  final NotificationRepository repository;
  final Dio dio;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  VoidCallback? _onNotification;
  bool _disposed = false;
  int _reconnectAttempt = 0;

  NotificationRealtimeService({required this.repository, required this.dio});

  Future<void> connect(VoidCallback onNotification) async {
    _onNotification = onNotification;
    await _open();
  }

  Future<void> _open() async {
    if (_disposed || _channel != null) return;
    try {
      final ticket = await repository.requestWebSocketTicket();
      if (ticket.isEmpty || _disposed) return;
      final base = Uri.parse(dio.options.baseUrl);
      final socketUri = base.replace(
        scheme: base.scheme == 'https' ? 'wss' : 'ws',
        path: '${base.path}${ApiEndpoints.notificationWs}',
        queryParameters: {'ticket': ticket},
      );
      final channel = WebSocketChannel.connect(socketUri);
      _channel = channel;
      await channel.ready;
      _reconnectAttempt = 0;
      _subscription = channel.stream.listen(
        _handleMessage,
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
        cancelOnError: true,
      );
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        _channel?.sink.add(jsonEncode({'action': 'ping'}));
      });
    } catch (_) {
      _channel = null;
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw.toString()) as Map<String, dynamic>;
      if (data['event'] == 'connected' || data['event'] == 'pong') return;
      if (data['id'] != null || data['notification_type'] != null) {
        _onNotification?.call();
      }
    } catch (_) {
      _onNotification?.call();
    }
  }

  void _handleDisconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    _pingTimer?.cancel();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _reconnectTimer?.isActive == true) return;
    final seconds = (1 << _reconnectAttempt.clamp(0, 5)).clamp(1, 30);
    _reconnectAttempt++;
    _reconnectTimer = Timer(Duration(seconds: seconds), _open);
  }

  Future<void> dispose() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
  }
}

typedef VoidCallback = void Function();
