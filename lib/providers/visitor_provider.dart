
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/visitor.dart'; // Updated import

class VisitorProvider with ChangeNotifier { // Renamed class
  final CollectionReference _visitorCollection = // Renamed collection variable
      FirebaseFirestore.instance.collection('visitors'); // Updated Firestore collection name

  List<Visitor> _visitors = []; // Renamed list variable
  List<Visitor> get visitors => _visitors; // Renamed getter

  Future<void> fetchVisitors() async { // Renamed method
    final snapshot = await _visitorCollection.get(); // Using new collection variable
    _visitors = snapshot.docs
        .map((doc) => Visitor.fromJson(doc.data() as Map<String, dynamic>)) // Using Visitor model
        .toList();
    notifyListeners();
  }

  Future<Visitor?> getVisitorById(String visitorId) async { // Renamed method
    final doc = await _visitorCollection.doc(visitorId).get(); // Using new collection variable
    if (doc.exists) {
      return Visitor.fromJson(doc.data() as Map<String, dynamic>); // Using Visitor model
    }
    return null;
  }

  Future<void> addVisitor(Visitor visitor) async { // Renamed method
    await _visitorCollection.doc(visitor.id).set(visitor.toJson()); // Using new collection variable and Visitor model
    await fetchVisitors(); // Using new method
  }

  Future<void> updateVisitor(String id, Visitor visitor) async { // Renamed method
    await _visitorCollection.doc(id).update(visitor.toJson()); // Using new collection variable and Visitor model
    await fetchVisitors(); // Using new method
  }

  Future<void> deleteVisitor(String id) async { // Renamed method
    await _visitorCollection.doc(id).delete(); // Using new collection variable
    await fetchVisitors(); // Using new method
  }
}
