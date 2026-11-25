import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showCropAlert(String zoneName, String cropName, double score) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'crop_alert_channel',
      'Crop Recommendations',
      channelDescription: 'Alerts when a new crop is highly recommended',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF2E7D32),
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'New Recommendation for $zoneName',
      'Consider planting $cropName (Score: ${score.toStringAsFixed(1)}). Conditions are optimal.',
      platformChannelSpecifics,
    );
  }
}