
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/equipment.dart';
import '../models/app_notification.dart';
import 'notification_provider.dart';

class EquipmentProvider with ChangeNotifier {
  final CollectionReference _equipmentCollection =
      FirebaseFirestore.instance.collection('equipments');

  List<Equipment> _equipments = [];
  List<Equipment> get equipments => _equipments;

  Future<void> fetchEquipments() async {
    final snapshot = await _equipmentCollection.get();
    _equipments = snapshot.docs
        .map((doc) => Equipment.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<Equipment?> getEquipmentById(String equipmentId) async {
    final doc = await _equipmentCollection.doc(equipmentId).get();
    if (doc.exists) {
      return Equipment.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> addEquipment(Equipment equipment, {NotificationProvider? notificationProvider}) async {
    final normalizedEquipment = equipment.copyWith(
      status: equipment.status.trim(),
    );
    await _equipmentCollection.doc(normalizedEquipment.id).set(normalizedEquipment.toJson());
    
    // If a college adds a "Not Working" equipment initially
    if (notificationProvider != null && normalizedEquipment.status == 'Not Working') {
      await notificationProvider.addNotification(AppNotification(
        id: '',
        title: 'New Failure Reported',
        message: 'College ${normalizedEquipment.collegeId} added: ${normalizedEquipment.name} (ID: ${normalizedEquipment.id}) as Not Working.',
        timestamp: DateTime.now(),
        targetUserId: 'admin',
        equipmentId: normalizedEquipment.id,
      ));
    }
    
    await fetchEquipments();
  }

  Future<void> updateEquipment(String id, Equipment updatedEquipment, {NotificationProvider? notificationProvider, String? updatedByRole}) async {
    final oldEquipment = _equipments.firstWhere((e) => e.id == id);
    final normalizedEquipment = updatedEquipment.copyWith(
      status: updatedEquipment.status.trim(),
    );
    
    await _equipmentCollection.doc(id).update(normalizedEquipment.toJson());

    if (notificationProvider != null) {
      // Scenario 1: College sets status to Not Working -> Admin gets notification
      if (oldEquipment.status != 'Not Working' && normalizedEquipment.status == 'Not Working' && updatedByRole != 'admin') {
        await notificationProvider.addNotification(AppNotification(
          id: '',
          title: 'Equipment Failure',
          message: 'College ${normalizedEquipment.collegeId} marked: ${normalizedEquipment.name} (ID: ${normalizedEquipment.id}) as Not Working.',
          timestamp: DateTime.now(),
          targetUserId: 'admin',
          equipmentId: normalizedEquipment.id,
        ));
      }
      
      // Scenario 2: Admin sets status from Not Working to Working -> College gets notification
      if (oldEquipment.status == 'Not Working' && normalizedEquipment.status == 'Working' && updatedByRole == 'admin') {
        await notificationProvider.addNotification(AppNotification(
          id: '',
          title: 'Equipment Restored',
          message: 'Admin marked: ${normalizedEquipment.name} (ID: ${normalizedEquipment.id}) as Working.',
          timestamp: DateTime.now(),
          targetUserId: normalizedEquipment.collegeId,
          equipmentId: normalizedEquipment.id,
        ));
      }
    }

    await fetchEquipments();
  }

  Future<void> deleteEquipment(String id) async { // Changed from deleteProduct
    await _equipmentCollection.doc(id).delete();
    await fetchEquipments(); // Changed from fetchProducts
  }

  // NEW: Function to delete all equipments for a given college
  Future<void> deleteAllEquipmentsForCollege(String collegeName) async {
    final QuerySnapshot snapshot = await _equipmentCollection.where('collegeId', isEqualTo: collegeName).get();
    
    final WriteBatch batch = FirebaseFirestore.instance.batch();
    for (DocumentSnapshot doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    await fetchEquipments(); // Refresh the list after deletion
  }

  /// Generates the next 7-digit equipment ID for a college.
  /// First 3 digits are the college code.
  /// Last 4 digits are sequential.
  String generateNextEquipmentId(String collegeCode) {
    // Filter equipments that belong to this college and have a 7-digit numeric ID starting with collegeCode
    final collegeEquipments = _equipments.where((e) => 
      e.id.length == 7 && 
      e.id.startsWith(collegeCode) && 
      int.tryParse(e.id) != null
    ).toList();

    if (collegeEquipments.isEmpty) {
      return '${collegeCode}0001';
    }

    // Find the maximum sequential number
    int maxSeq = 0;
    for (var e in collegeEquipments) {
      final seqPart = e.id.substring(3);
      final seq = int.tryParse(seqPart) ?? 0;
      if (seq > maxSeq) {
        maxSeq = seq;
      }
    }

    final nextSeq = maxSeq + 1;
    return collegeCode + nextSeq.toString().padLeft(4, '0');
  }
}
