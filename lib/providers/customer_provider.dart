
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';

class CustomerProvider with ChangeNotifier {
  final CollectionReference _customerCollection =
      FirebaseFirestore.instance.collection('customers');

  List<Customer> _customers = [];
  List<Customer> get customers => _customers;

  Future<void> fetchCustomers() async {
    final snapshot = await _customerCollection.get();
    _customers = snapshot.docs
        .map((doc) => Customer.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> addCustomer(Customer customer) async {
    await _customerCollection.doc(customer.id).set(customer.toJson());
    await fetchCustomers();
  }

  Future<void> updateCustomer(String id, Customer customer) async {
    await _customerCollection.doc(id).update(customer.toJson());
    await fetchCustomers();
  }

  Future<void> deleteCustomer(String id) async {
    await _customerCollection.doc(id).delete();
    await fetchCustomers();
  }
}
