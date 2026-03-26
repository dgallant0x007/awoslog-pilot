import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'awoslog_tracking';
  static const _channelName = 'Flight Tracking';
  static const _notificationId = 1;

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );
    await _plugin.initialize(initSettings);

    // Create the notification channel explicitly (Android only).
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Shows when AWOSLOG is tracking your flight',
        importance: Importance.low,
        showBadge: false,
      ),
    );
  }

  static Future<void> requestPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      debugPrint('Notification permission: $granted');
    }
  }

  static Future<void> showTracking() async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Shows when AWOSLOG is tracking your flight',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      _notificationId,
      'AWOSLOG Pilot Tracker',
      'Tracking your flight',
      details,
    );
  }

  static Future<void> updateTracking(String text) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Shows when AWOSLOG is tracking your flight',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      _notificationId,
      'AWOSLOG Pilot Tracker',
      text,
      details,
    );
  }

  static Future<void> cancel() async {
    await _plugin.cancel(_notificationId);
  }
}
