import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<RemoteMessage>? _foreground;
  StreamSubscription<RemoteMessage>? _opened;
  StreamSubscription<String>? _tokenRefresh;
  bool _disposed = false;

  Future<void> initialize({
    required void Function(RemoteMessage, String) onData,
    required void Function(String) onStatus,
  }) async {
    if (_disposed || _foreground != null) {
      throw StateError('Use a new service instance for initialization.');
    }

    void receive(String handler, RemoteMessage message) {
      if (_disposed) return;

      debugPrint('$handler: ${message.messageId}');
      onData(message, handler);
    }

    void handleStreamError(Object error, StackTrace stack) {
      if (_disposed) return;

      debugPrint('FCM stream error: $error');
      onStatus('Messaging stream error. Check the debug console.');
    }

    // Listen before awaiting setup so messages can reach the screen promptly.
    _foreground = FirebaseMessaging.onMessage.listen(
      (message) => receive('onMessage', message),
      onError: handleStreamError,
    );

    _opened = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => receive('onMessageOpenedApp', message),
      onError: handleStreamError,
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (_disposed) return;

    if (initialMessage != null) {
      receive('getInitialMessage', initialMessage);
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (_disposed) return;

    onStatus('Permission: ${settings.authorizationStatus.name}');

    _tokenRefresh = _messaging.onTokenRefresh.listen((token) {
      if (_disposed) return;

      if (kDebugMode) {
        debugPrint('FCM token refreshed: $token');
      }
    }, onError: handleStreamError);

    final token = await _messaging.getToken();
    if (_disposed) return;

    if (token == null || token.isEmpty) {
      throw StateError('No FCM token. Check network and Firebase setup.');
    }

    if (kDebugMode) {
      debugPrint('FCM token: $token');
    }
  }

  Future<void> dispose() async {
    _disposed = true;

    await Future.wait<void>([
      if (_foreground != null) _foreground!.cancel(),
      if (_opened != null) _opened!.cancel(),
      if (_tokenRefresh != null) _tokenRefresh!.cancel(),
    ]);
  }
}
