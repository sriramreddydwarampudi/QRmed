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

  Stream<AppNotification> get newNotificationStream => _newNotificationController.stream;

  void startListening(String targetUserId) {
    _subscription?.cancel();
    _subscription = getNotifications(targetUserId).listen((notifications) {
      if (notifications.isNotEmpty) {
        // Find all unread notifications we haven't seen in this session
        final unreadAndNew = notifications.where((n) => !n.isRead && !_seenNotificationIds.contains(n.id)).toList();
        
        for (var latest in unreadAndNew) {
          _seenNotificationIds.add(latest.id);
          
          // Broadcast to in-app listeners
          _newNotificationController.add(latest);
          
          // Also show system notification
          NotificationService.showSystemNotification(
            id: latest.id.hashCode,
            title: latest.title,
            body: latest.message,
          );
        }
      }
      
      // Update seen IDs to only include current unread ones to prevent memory leak
      final currentUnreadIds = notifications.where((n) => !n.isRead).map((n) => n.id).toSet();
      _seenNotificationIds.retainAll(currentUnreadIds);
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
