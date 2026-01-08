
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/college.dart';

class CollegeProvider with ChangeNotifier {
  final CollectionReference _collegeCollection =
      FirebaseFirestore.instance.collection('colleges');

  List<College> _colleges = [];
  List<College> get colleges => _colleges;

  Future<void> fetchColleges() async {
    try {
      final snapshot = await _collegeCollection.get();
      _colleges = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Use document ID if id field is missing or different
        final collegeId = data['id'] as String? ?? doc.id;
        return College.fromJson({
          ...data,
          'id': collegeId, // Ensure we use the document ID or the id from data
        });
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching colleges: $e');
      rethrow;
    }
  }

  Future<void> addCollege(College college) async {
    try {
      await _collegeCollection.doc(college.id).set(college.toJson());
      await fetchColleges();
    } catch (e) {
      debugPrint('Error adding college: $e');
      rethrow;
    }
  }

  Future<void> updateCollege(String id, College college) async {
    try {
      await _collegeCollection.doc(id).update(college.toJson());
      await fetchColleges();
    } catch (e) {
      debugPrint('Error updating college: $e');
      rethrow;
    }
  }

  /// Deletes a college and all its related data (cascade delete)
  /// This includes: equipments, employees, customers, departments
  Future<void> deleteCollege(String id) async {
    print('🔴 [deleteCollege] Starting deletion for college ID: $id');
    debugPrint('🔴 [deleteCollege] Starting deletion for college ID: $id');
    
    try {
      // First, try to find the college by document ID
      var collegeDoc = await _collegeCollection.doc(id).get();
      String actualDocumentId = id;
      
      // If not found by document ID, try to find by the id field in the data
      if (!collegeDoc.exists) {
        print('⚠️ [deleteCollege] College not found by document ID, searching by id field...');
        final allColleges = await _collegeCollection.get();
        DocumentSnapshot? matchingDoc;
        
        try {
          matchingDoc = allColleges.docs.firstWhere(
            (doc) {
              final data = doc.data() as Map<String, dynamic>;
              final docIdField = data['id'] as String? ?? '';
              return docIdField.trim() == id.trim() || doc.id.trim() == id.trim();
            },
          );
        } catch (e) {
          matchingDoc = null;
        }
        
        if (matchingDoc != null) {
          actualDocumentId = matchingDoc.id;
          collegeDoc = matchingDoc;
          print('✅ [deleteCollege] Found college with document ID: $actualDocumentId');
        }
      }
      
      if (!collegeDoc.exists) {
        // Log all existing college IDs to help debug
        final allColleges = await _collegeCollection.get();
        final existingIds = allColleges.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return 'doc.id: "${doc.id}", data.id: "${data['id'] ?? 'N/A'}"';
        }).toList();
        print('❌ [deleteCollege] College with ID "$id" does not exist in Firestore');
        print('📋 [deleteCollege] Existing colleges in Firestore:');
        for (var info in existingIds) {
          print('   - $info');
        }
        throw Exception('College with ID "$id" does not exist in Firestore');
      }
      
      print('✅ [deleteCollege] College exists, proceeding with deletion (document ID: $actualDocumentId)');
      debugPrint('✅ [deleteCollege] College exists, proceeding with deletion (document ID: $actualDocumentId)');
      
      // Get the college data to find the id field
      final collegeData = collegeDoc.data() as Map<String, dynamic>;
      final collegeIdField = (collegeData['id'] as String? ?? actualDocumentId).trim();
      
      print('🔍 [deleteCollege] College document ID: $actualDocumentId');
      print('🔍 [deleteCollege] College id field: $collegeIdField');
      
      // Delete all related data first (use the id field from data, as that's what equipments use)
      await _deleteAllRelatedDataForCollege(collegeIdField);
      // Also try with document ID in case some data uses that
      if (actualDocumentId != collegeIdField) {
        print('⚠️ [deleteCollege] Document ID differs from id field, also deleting with document ID');
        await _deleteAllRelatedDataForCollege(actualDocumentId);
      }
      
      // Then delete the college itself using the document ID
      print('🔴 [deleteCollege] Deleting college document: $actualDocumentId');
      debugPrint('🔴 [deleteCollege] Deleting college document: $actualDocumentId');
      await _collegeCollection.doc(actualDocumentId).delete();
      print('🔴 [deleteCollege] College document deleted successfully');
      debugPrint('🔴 [deleteCollege] College document deleted successfully');
      
      // Refresh the list
      await fetchColleges();
      notifyListeners();
      print('🔴 [deleteCollege] College deletion completed successfully');
      debugPrint('🔴 [deleteCollege] College deletion completed successfully');
    } catch (e, stackTrace) {
      print('🔴 [deleteCollege ERROR] Error deleting college $id: $e');
      print('🔴 [deleteCollege ERROR] Stack trace: $stackTrace');
      debugPrint('🔴 [deleteCollege ERROR] Error deleting college $id: $e');
      debugPrint('🔴 [deleteCollege ERROR] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Helper method to delete all related data for a college
  Future<void> _deleteAllRelatedDataForCollege(String collegeId) async {
    debugPrint('🗑️ [_deleteAllRelatedDataForCollege] Starting deletion for college: $collegeId');
    
    int totalDeletions = 0;
    
    try {
      // Delete all equipments for this college
      debugPrint('🔍 [_deleteAllRelatedDataForCollege] Fetching equipments...');
      final equipmentsSnapshot = await FirebaseFirestore.instance
          .collection('equipments')
          .where('collegeId', isEqualTo: collegeId)
          .get();
      debugPrint('📊 [_deleteAllRelatedDataForCollege] Found ${equipmentsSnapshot.docs.length} equipments');
      
      if (equipmentsSnapshot.docs.isNotEmpty) {
        final batch1 = FirebaseFirestore.instance.batch();
        for (var doc in equipmentsSnapshot.docs) {
          batch1.delete(doc.reference);
          totalDeletions++;
        }
        await batch1.commit();
        debugPrint('✅ [_deleteAllRelatedDataForCollege] Deleted ${equipmentsSnapshot.docs.length} equipments');
      }

      // Delete all employees for this college
      debugPrint('🔍 [_deleteAllRelatedDataForCollege] Fetching employees...');
      final employeesSnapshot = await FirebaseFirestore.instance
          .collection('employees')
          .where('collegeId', isEqualTo: collegeId)
          .get();
      debugPrint('📊 [_deleteAllRelatedDataForCollege] Found ${employeesSnapshot.docs.length} employees');
      
      if (employeesSnapshot.docs.isNotEmpty) {
        final batch2 = FirebaseFirestore.instance.batch();
        for (var doc in employeesSnapshot.docs) {
          batch2.delete(doc.reference);
          totalDeletions++;
        }
        await batch2.commit();
        debugPrint('✅ [_deleteAllRelatedDataForCollege] Deleted ${employeesSnapshot.docs.length} employees');
      }

      // Delete all customers for this college
      debugPrint('🔍 [_deleteAllRelatedDataForCollege] Fetching customers...');
      final customersSnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .where('collegeId', isEqualTo: collegeId)
          .get();
      debugPrint('📊 [_deleteAllRelatedDataForCollege] Found ${customersSnapshot.docs.length} customers');
      
      if (customersSnapshot.docs.isNotEmpty) {
        final batch3 = FirebaseFirestore.instance.batch();
        for (var doc in customersSnapshot.docs) {
          batch3.delete(doc.reference);
          totalDeletions++;
        }
        await batch3.commit();
        debugPrint('✅ [_deleteAllRelatedDataForCollege] Deleted ${customersSnapshot.docs.length} customers');
      }

      // Delete all departments for this college
      debugPrint('🔍 [_deleteAllRelatedDataForCollege] Fetching departments...');
      final departmentsSnapshot = await FirebaseFirestore.instance
          .collection('departments')
          .where('collegeId', isEqualTo: collegeId)
          .get();
      debugPrint('📊 [_deleteAllRelatedDataForCollege] Found ${departmentsSnapshot.docs.length} departments');
      
      if (departmentsSnapshot.docs.isNotEmpty) {
        final batch4 = FirebaseFirestore.instance.batch();
        for (var doc in departmentsSnapshot.docs) {
          batch4.delete(doc.reference);
          totalDeletions++;
        }
        await batch4.commit();
        debugPrint('✅ [_deleteAllRelatedDataForCollege] Deleted ${departmentsSnapshot.docs.length} departments');
      }

      // Delete all tickets for this college (if tickets have collegeId field)
      try {
        debugPrint('🔍 [_deleteAllRelatedDataForCollege] Fetching tickets...');
        final ticketsSnapshot = await FirebaseFirestore.instance
            .collection('tickets')
            .where('collegeId', isEqualTo: collegeId)
            .get();
        debugPrint('📊 [_deleteAllRelatedDataForCollege] Found ${ticketsSnapshot.docs.length} tickets');
        
        if (ticketsSnapshot.docs.isNotEmpty) {
          final batch5 = FirebaseFirestore.instance.batch();
          for (var doc in ticketsSnapshot.docs) {
            batch5.delete(doc.reference);
            totalDeletions++;
          }
          await batch5.commit();
          debugPrint('✅ [_deleteAllRelatedDataForCollege] Deleted ${ticketsSnapshot.docs.length} tickets');
        }
      } catch (e) {
        // Tickets might not have collegeId field, ignore this error
        debugPrint('ℹ️ [_deleteAllRelatedDataForCollege] Could not delete tickets (may not have collegeId): $e');
      }

      debugPrint('✅ [_deleteAllRelatedDataForCollege] Successfully deleted $totalDeletions related documents for college: $collegeId');
    } catch (e, stackTrace) {
      debugPrint('❌ [_deleteAllRelatedDataForCollege] Error deleting related data for college $collegeId: $e');
      debugPrint('❌ [_deleteAllRelatedDataForCollege] Stack trace: $stackTrace');
      rethrow;
    }
  }
}
