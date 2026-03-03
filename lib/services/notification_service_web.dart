// lib/services/notification_service_web.dart
import 'dart:html' as html;

class NotificationService {
  static Future<void> initialize() async {
    print('NotificationService (Web): Initializing...');
    if (html.Notification.permission == 'default') {
      print('NotificationService (Web): Requesting permission...');
      await html.Notification.requestPermission();
    }
    print('NotificationService (Web): Permission status: ${html.Notification.permission}');
  }

  static Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    print('NotificationService (Web): Attempting to show notification: $title');
    
    if (html.Notification.permission == 'granted') {
      html.Notification(title, body: body);
      print('NotificationService (Web): Notification shown');
    } else if (html.Notification.permission == 'default') {
      print('NotificationService (Web): Permission not yet requested/granted. Requesting now...');
      final permission = await html.Notification.requestPermission();
      if (permission == 'granted') {
        html.Notification(title, body: body);
      }
    } else {
      print('NotificationService (Web): Permission denied. Cannot show notification.');
    }
  }
}
