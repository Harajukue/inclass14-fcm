import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// Must be top-level — runs in a separate Dart isolate when app is terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background handler: ${message.messageId}');
}

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String?> initialize({
    required void Function(RemoteMessage) onForegroundMessage,
    required void Function(RemoteMessage) onNotificationTap,
  }) async {
    // Register background handler (must be top-level function).
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission (required on Android 13+ and iOS).
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground message handler.
    FirebaseMessaging.onMessage.listen(onForegroundMessage);

    // Tapped while app was in background.
    FirebaseMessaging.onMessageOpenedApp.listen(onNotificationTap);

    // Tapped while app was terminated — get the initial message.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) onNotificationTap(initial);

    return _messaging.getToken();
  }
}
