import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api.dart';

/// Top-level background handler — MUST be a top-level function (not a class method).
/// For background/terminated state, Android shows the 'notification' payload in the
/// system tray automatically, so nothing extra is needed here.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'hcp_hrms_default',
    'HCP HRMS Notifications',
    description: 'Leave and attendance approval alerts',
    importance: Importance.high,
  );

  /// Call once at startup (after Firebase.initializeApp).
  static Future<void> init() async {
    // Local notifications — used to show FCM messages while the app is in foreground.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(const InitializationSettings(android: androidInit));

    final androidImpl = _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_channel);
    await androidImpl?.requestNotificationsPermission(); // Android 13+ POST_NOTIFICATIONS

    // iOS/general FCM permission (harmless on Android).
    await FirebaseMessaging.instance.requestPermission();

    // Foreground messages: show a local notification.
    FirebaseMessaging.onMessage.listen(_showForeground);

    // Register token now (works if already logged in) and on refresh.
    await registerToken();
    FirebaseMessaging.instance.onTokenRefresh.listen(_upload);
  }

  /// Fetch the current FCM token and upload it to the backend.
  /// Safe to call after login; no-ops silently if not logged in or on error.
  static Future<void> registerToken() async {
    try {
      final t = await FirebaseMessaging.instance.getToken();
      if (t != null && t.isNotEmpty) await _upload(t);
    } catch (_) {}
  }

  static Future<void> _upload(String token) async {
    try {
      await Api.registerDevice(token, 'android');
    } catch (_) {}
  }

  static void _showForeground(RemoteMessage m) {
    final n = m.notification;
    if (n == null) return;
    _local.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
