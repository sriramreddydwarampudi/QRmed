import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    print('NotificationService: Initializing...');
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    try {
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('NotificationService: Notification tapped! Response: ${response.payload}');
        },
      );
      print('NotificationService: Plugin initialized successfully');

      // Create a high-importance channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'qrmed_notifications',
        'QRmed Notifications',
        description: 'Notifications for equipment status changes',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        print('NotificationService: Creating Android notification channel...');
        await androidPlugin.createNotificationChannel(channel);
        print('NotificationService: Channel created');
        
        // Request permissions for Android 13+
        print('NotificationService: Requesting Android 13+ permissions...');
        final granted = await androidPlugin.requestNotificationsPermission();
        print('NotificationService: Permission granted: $granted');
        if (granted != true) {
          print('WARNING: Notification permissions NOT granted. System notifications will NOT appear.');
        }
      } else {
        print('NotificationService: Android plugin NOT found (not on Android?)');
      }
    } catch (e) {
      print('NotificationService Error during initialization: $e');
    }
  }

  static Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    print('NotificationService: Attempting to show notification (ID: $id, Title: $title)');
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'qrmed_notifications', // Matches the channel ID created in initialize
      'QRmed Notifications',
      channelDescription: 'Notifications for equipment status changes',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      print('NotificationService: Notification shown successfully');
    } catch (e) {
      print('NotificationService Error showing notification: $e');
    }
  }
}
