// lib/services/notification_service.dart
import 'notification_service_stub.dart'
    if (dart.library.html) 'notification_service_web.dart'
    if (dart.library.io) 'notification_service_mobile.dart';

abstract class NotificationServiceBase {
  static Future<void> initialize() async => throw UnimplementedError();
  static Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async => throw UnimplementedError();
  static Future<bool> requestPermission() async => throw UnimplementedError();
  static bool get isSystemNotificationSupported => false;
  static bool get isSystemNotificationEnabled => false;
}
