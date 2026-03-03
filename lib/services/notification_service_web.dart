// lib/services/notification_service_web.dart
import 'dart:html' as html;

class NotificationService {
  static Future<void> initialize() async {
    print('NotificationService (Web): Initializing...');
    try {
      if (!html.Notification.supported) {
        print('NotificationService (Web): Notifications are NOT supported by this browser.');
        return;
      }
      print('NotificationService (Web): Current permission status: ${html.Notification.permission}');
    } catch (e) {
      print('NotificationService (Web) Error during initialization: $e');
    }
  }

  static Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    print('NotificationService (Web): Attempting to show notification (ID: $id, Title: $title)');
    
    try {
      if (!html.Notification.supported) {
        print('NotificationService (Web): Notifications are NOT supported by this browser.');
        return;
      }

      final status = html.Notification.permission;
      print('NotificationService (Web): Permission status is $status');

      if (status == 'granted') {
        _createNotification(title, body);
      } else if (status != 'denied') {
        print('NotificationService (Web): Requesting permission...');
        // In web, requestPermission MUST be triggered by a user gesture.
        // This function is typically called from a button click's onPressed.
        final result = await html.Notification.requestPermission();
        print('NotificationService (Web): Permission request result: $result');
        if (result == 'granted') {
          _createNotification(title, body);
        }
      } else {
        print('NotificationService (Web): Permission denied. Please enable notifications in your browser settings.');
      }
    } catch (e) {
      print('NotificationService (Web) Error in showSystemNotification: $e');
    }
  }

  static void _createNotification(String title, String body) {
    try {
      print('NotificationService (Web): Creating notification object...');
      
      // We try to find a suitable icon. Flutter's default icon for web is at icons/Icon-192.png
      final notification = html.Notification(
        title,
        body: body,
        icon: 'icons/Icon-192.png',
        tag: 'qrmed-notification',
      );

      notification.onClick.listen((event) {
        print('NotificationService (Web): Notification clicked');
        html.window.focus();
        notification.close();
      });
      
      print('NotificationService (Web): Notification triggered successfully');
    } catch (e) {
      print('NotificationService (Web) Error in _createNotification: $e');
      
      // Try with minimal options if it failed
      try {
        print('NotificationService (Web): Trying minimal notification...');
        html.Notification(title, body: body);
      } catch (e2) {
        print('NotificationService (Web): Minimal notification also failed: $e2');
      }
    }
  }
}
