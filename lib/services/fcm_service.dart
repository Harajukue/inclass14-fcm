import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

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
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(onForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(onNotificationTap);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) onNotificationTap(initial);

    return _messaging.getToken();
  }
}
