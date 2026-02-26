import 'package:flutter/material.dart';
import 'package:supreme_institution/data/requirements_data.dart' as data;

class RequirementsProvider with ChangeNotifier {
  // Declare the field, but initialize it in the constructor.
  late Map<String, Map<String, Map<String, Map<String, dynamic>>>> _requirements;
  Map<String, List<String>> _equipmentDepartments = {};

  // Getter should return the initialized field.
  Map<String, Map<String, Map<String, Map<String, dynamic>>>> get requirements => _requirements;
  Map<String, List<String>> get equipmentDepartments => _equipmentDepartments;

  RequirementsProvider() {
    // Initialize the late field using the imported 'requirements' constant, aliased as 'data'
    _requirements = data.requirements;
    _prepareEquipmentData();
  }

  void _prepareEquipmentData() {
    final Map<String, List<String>> equipmentDepts = {};
    // Use the _requirements field for processing
    _requirements.forEach((collegeType, seatData) {
      seatData.forEach((seats, departmentData) {
        departmentData.forEach((departmentName, requirements) {
          final equipments =
              Map<String, int>.from(requirements['equipments'] as Map);
          equipments.forEach((equipmentName, count) {
            if (!equipmentDepts.containsKey(equipmentName)) {
              equipmentDepts[equipmentName] = [];
            }
            if (!equipmentDepts[equipmentName]!.contains(departmentName)) {
              equipmentDepts[equipmentName]!.add(departmentName);
            }
          });
        });
      });
    });
    _equipmentDepartments = equipmentDepts;
    notifyListeners();
  }

  void updateRequirements(
      Map<String, Map<String, Map<String, Map<String, dynamic>>>>
          newRequirements) {
    _requirements = newRequirements;
    _prepareEquipmentData();
    notifyListeners();
  }
}