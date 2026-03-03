import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final CollectionReference _notificationCollection =
      FirebaseFirestore.instance.collection('notifications');
  
  StreamSubscription? _subscription;
  final Set<String> _seenNotificationIds = {};
  final _newNotificationController = StreamController<AppNotification>.broadcast();
  DateTime? _sessionStartTime;

  Stream<AppNotification> get newNotificationStream => _newNotificationController.stream;

  void startListening(String targetUserId) {
    print('DEBUG: NotificationProvider: Starting listener for targetUserId: $targetUserId');
    _sessionStartTime = DateTime.now();
    print('DEBUG: NotificationProvider: Session start time: $_sessionStartTime');
    
    _subscription?.cancel();
    _subscription = getNotifications(targetUserId).listen((notifications) {
      print('DEBUG: NotificationProvider: Received ${notifications.length} notifications from Firestore');
      if (notifications.isNotEmpty) {
        // Find all unread notifications we haven't seen in this session
        final unreadAndNew = notifications.where((n) {
          final isUnread = !n.isRead;
          final isNotSeen = !_seenNotificationIds.contains(n.id);
          // ONLY trigger system notification if it happened AFTER we started the app
          final isFromThisSession = _sessionStartTime != null && n.timestamp.isAfter(_sessionStartTime!);
          
          return isUnread && isNotSeen && isFromThisSession;
        }).toList();

        // Separate handling for in-app UI updates vs system notifications
        // We might want to show all unread in UI, but only beep for NEW ones
        final allUnseen = notifications.where((n) => !n.isRead && !_seenNotificationIds.contains(n.id)).toList();
        
        print('DEBUG: NotificationProvider: Found ${allUnseen.length} total unseen, ${unreadAndNew.length} are new to this session');
        
        for (var latest in allUnseen) {
          _seenNotificationIds.add(latest.id);
          
          // Broadcast to in-app listeners (snackbars, etc)
          _newNotificationController.add(latest);
          
          // ONLY show system notification if it's actually new from this session
          if (unreadAndNew.contains(latest)) {
            print('DEBUG: NotificationProvider: Triggering showSystemNotification for ${latest.title}');
            NotificationService.showSystemNotification(
              id: latest.id.hashCode,
              title: latest.title,
              body: latest.message,
            );
          }
        }
      }
      
      // Update seen IDs to only include current unread ones to prevent memory leak
      final currentUnreadIds = notifications.where((n) => !n.isRead).map((n) => n.id).toSet();
      _seenNotificationIds.retainAll(currentUnreadIds);
    }, onError: (error) {
      print('DEBUG ERROR: NotificationProvider listener error: $error');
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _newNotificationController.close();
    super.dispose();
  }

  Stream<List<AppNotification>> getNotifications(String targetUserId) {
    return _notificationCollection
        .where('targetUserId', isEqualTo: targetUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> addNotification(AppNotification notification) async {
    final docRef = _notificationCollection.doc();
    final newNotification = notification.copyWith(id: docRef.id);
    await docRef.set(newNotification.toJson());
  }

  Future<void> markAsRead(String notificationId) async {
    await _notificationCollection.doc(notificationId).update({'isRead': true});
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notificationCollection.doc(notificationId).delete();
  }

  Future<void> clearAll(String targetUserId) async {
    final snapshot = await _notificationCollection
        .where('targetUserId', isEqualTo: targetUserId)
        .get();
    
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
