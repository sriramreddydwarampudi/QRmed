
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/college.dart';

class CollegeProvider with ChangeNotifier {
  final CollectionReference _collegeCollection =
      FirebaseFirestore.instance.collection('colleges');

  List<College> _colleges = [];
  List<College> get colleges => _colleges;

  Future<void> fetchColleges() async {
    final snapshot = await _collegeCollection.get();
    _colleges = snapshot.docs
        .map((doc) => College.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> addCollege(College college) async {
    await _collegeCollection.doc(college.id).set(college.toJson());
    await fetchColleges();
  }

  Future<void> updateCollege(String id, College college) async {
    await _collegeCollection.doc(id).update(college.toJson());
    await fetchColleges();
  }

  Future<void> deleteCollege(String id) async {
    await _collegeCollection.doc(id).delete();
    await fetchColleges();
  }
}
