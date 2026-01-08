
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/equipment.dart'; // Changed from product.dart

class EquipmentProvider with ChangeNotifier {
  final CollectionReference _equipmentCollection =
      FirebaseFirestore.instance.collection('equipments'); // Changed from products

  List<Equipment> _equipments = []; // Changed from _products
  List<Equipment> get equipments => _equipments; // Changed from products

  Future<void> fetchEquipments() async { // Changed from fetchProducts
    final snapshot = await _equipmentCollection.get();
    _equipments = snapshot.docs
        .map((doc) => Equipment.fromJson(doc.data() as Map<String, dynamic>)) // Changed from Product.fromJson
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

  Future<void> addEquipment(Equipment equipment) async { // Changed from addProduct
    // Normalize status before saving to ensure consistency
    final normalizedEquipment = equipment.copyWith(
      status: equipment.status.trim(),
    );
    await _equipmentCollection.doc(normalizedEquipment.id).set(normalizedEquipment.toJson());
    await fetchEquipments(); // Changed from fetchProducts
  }

  Future<void> updateEquipment(String id, Equipment equipment) async { // Changed from updateProduct
    // Normalize status before saving to ensure consistency
    final normalizedEquipment = equipment.copyWith(
      status: equipment.status.trim(),
    );
    await _equipmentCollection.doc(id).update(normalizedEquipment.toJson());
    await fetchEquipments(); // Changed from fetchProducts
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
}
