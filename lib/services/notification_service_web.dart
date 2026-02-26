// lib/services/notification_service_web.dart

class NotificationService {
  static Future<void> initialize() async {
    // Notifications not supported on web in this implementation
  }

  static Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Notifications not supported on web in this implementation
  }
}
