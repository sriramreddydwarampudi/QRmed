import 'package:flutter/material.dart';
import 'package:supreme_institution/models/department.dart';

class DepartmentProvider with ChangeNotifier {
  final List<Department> _departments = [
    // Dummy data for testing
    Department(id: 'd1', name: 'Cardiology', collegeId: 'c1'),
    Department(id: 'd2', name: 'Neurology', collegeId: 'c1'),
    Department(id: 'd3', name: 'Computer Science', collegeId: 'c2'),
  ];

  List<Department> get departments => _departments;

  List<Department> getDepartmentsForCollege(String collegeId) {
    return _departments.where((dep) => dep.collegeId == collegeId).toList();
  }

  void addDepartment(Department department) {
    _departments.add(department);
    notifyListeners();
  }

  void deleteDepartment(String departmentId) {
    _departments.removeWhere((dep) => dep.id == departmentId);
    notifyListeners();
  }

  void updateDepartment(Department department) {
    final index = _departments.indexWhere((dep) => dep.id == department.id);
    if (index != -1) {
      _departments[index] = department;
      notifyListeners();
    }
  }
}
