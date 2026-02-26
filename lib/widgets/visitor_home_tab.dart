import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/college.dart';
import 'package:supreme_institution/models/equipment.dart';
import 'package:supreme_institution/models/inspection_result.dart';
import 'package:supreme_institution/providers/department_provider.dart';
import 'package:supreme_institution/providers/employee_provider.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';
import 'package:supreme_institution/providers/inspection_provider.dart';
import 'package:supreme_institution/widgets/dashboard_tile.dart';
import 'package:supreme_institution/utils/responsive_utils.dart';

class VisitorHomeTab extends StatelessWidget { // Renamed class
  final College associatedCollege;

  const VisitorHomeTab({super.key, required this.associatedCollege}); // Updated constructor

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = Provider.of<EquipmentProvider>(context);
    final List<Equipment> allEquipments = equipmentProvider.equipments;
    final employeeProvider = Provider.of<EmployeeProvider>(context);
    final departmentProvider = Provider.of<DepartmentProvider>(context);
    final inspectionProvider = Provider.of<InspectionProvider>(context, listen: false);

    // Filtering data based on collegeId
    final collegeEquipmentsList = equipmentProvider.equipments.where((e) => e.collegeId == associatedCollege.id).toList();
    final collegeEquipments = collegeEquipmentsList.length;
    final totalEmployees = employeeProvider.employees.where((e) => e.collegeId == associatedCollege.id).length;
    final totalDepartments = departmentProvider.departments.where((d) => d.collegeId == associatedCollege.id).length;
    final notWorkingEquipments = collegeEquipmentsList.where((e) => e.status != 'Working').length;
    
    debugPrint('🔍 [VisitorHomeTab] College: ${associatedCollege.name}'); // Updated debug print
    debugPrint('🔍 [VisitorHomeTab] College Equipments: $collegeEquipments'); // Updated debug print
    debugPrint('🔍 [VisitorHomeTab] Total Departments: $totalDepartments'); // Updated debug print
    debugPrint('🔍 [VisitorHomeTab] Total Employees: $totalEmployees'); // Updated debug print
    debugPrint('🔍 [VisitorHomeTab] Not Working Equipments: $notWorkingEquipments'); // Updated debug print

    void showInspectionResultDialog(InspectionResult result) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(result.passed ? 'Inspection Passed!' : 'Inspection Failed!'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Overall Status: ${result.passed ? 'PASS' : 'FAIL'}'),
                  if (result.missingEquipment.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text('Missing Equipment:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...result.missingEquipment.map((item) => Text('- $item')),
                  ],
                  if (result.missingStaff.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text('Missing Staff:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...result.missingStaff.map((item) => Text('- $item')),
                  ],
                  if (result.excessEquipment.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text('Excess Equipment:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...result.excessEquipment.map((item) => Text('- $item')),
                  ],
                  if (result.excessStaff.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text('Excess Staff:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...result.excessStaff.map((item) => Text('- $item')),
                  ],
                  if (result.notes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...result.notes.map((item) => Text('- $item')),
                  ],
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Okay'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          );
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ResponsiveUtils.getMaxWidth(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: ResponsiveUtils.getCrossAxisCount(context),
                crossAxisSpacing: 16, mainAxisSpacing: 16,
                childAspectRatio: ResponsiveUtils.getChildAspectRatio(context),
                children: [
                  DashboardTile(
                    count: collegeEquipments.toString(),
                    title: '${associatedCollege.name} Equipments',
                    icon: Icons.school,
                    color: Colors.blue,
                  ),
                  DashboardTile(
                    count: totalDepartments.toString(),
                    title: 'Total Departments',
                    icon: Icons.business,
                    color: Colors.purple,
                  ),
                  DashboardTile(
                    count: totalEmployees.toString(),
                    title: 'Total Employees',
                    icon: Icons.people,
                    color: Colors.green,
                  ),
                  DashboardTile(
                    count: notWorkingEquipments.toString(),
                    title: 'Equipments Not Working',
                    icon: Icons.build,
                    color: const Color(0xFFDC2626), // Red color for non-working equipment
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}