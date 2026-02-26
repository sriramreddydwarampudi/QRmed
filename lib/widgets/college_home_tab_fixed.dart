import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/college.dart';
import 'package:supreme_institution/models/visitor.dart';
import 'package:supreme_institution/models/department.dart';
import 'package:supreme_institution/models/employee.dart';
import 'package:supreme_institution/models/inspection_result.dart'; // Import InspectionResult
import 'package:supreme_institution/providers/visitor_provider.dart';
import 'package:supreme_institution/providers/department_provider.dart';
import 'package:supreme_institution/providers/employee_provider.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';
import 'package:supreme_institution/providers/inspection_provider.dart'; // Import InspectionProvider
import 'package:supreme_institution/widgets/dashboard_tile.dart';
import 'package:url_launcher/url_launcher.dart';

class CollegeHomeTab extends StatefulWidget {
  final College college;

  const CollegeHomeTab({super.key, required this.college});

  @override
  State<CollegeHomeTab> createState() => _CollegeHomeTabState();
}

class _CollegeHomeTabState extends State<CollegeHomeTab> {
  void _showInspectionResultDialog(InspectionResult result) {
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

  void _showDepartmentSelectionDialog() {
    Department? selectedDepartment;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final departmentProvider = Provider.of<DepartmentProvider>(context, listen: false);
            return AlertDialog(
              title: const Text('Select Department'),
              content: DropdownButtonFormField<Department>(
                isExpanded: true,
                initialValue: selectedDepartment,
                decoration: const InputDecoration(labelText: 'Department'),
                selectedItemBuilder: (BuildContext context) {
                  return departmentProvider.getDepartmentsForCollege(widget.college.id).map((department) {
                    return Text(
                      department.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    );
                  }).toList();
                },
                items: departmentProvider.getDepartmentsForCollege(widget.college.id).map((department) {
                  return DropdownMenuItem<Department>(
                    value: department,
                    child: Text(
                      department.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (department) {
                  setState(() {
                    selectedDepartment = department;
                  });
                },
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Inspect'),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop(); // Close the dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Performing inspection...')),
                    );

                    final inspectionProvider = Provider.of<InspectionProvider>(context, listen: false);
                    final result = await inspectionProvider.performInspectionForCollege(
                      college: widget.college,
                      department: selectedDepartment,
                    );

                    _showInspectionResultDialog(result);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fetching providers to get data
    final employeeProvider = Provider.of<EmployeeProvider>(context);
    final equipmentProvider = Provider.of<EquipmentProvider>(context);
    final visitorProvider = Provider.of<VisitorProvider>(context);
    final departmentProvider = Provider.of<DepartmentProvider>(context, listen: false);

    // Filtering data based on collegeId
    final totalEquipments = equipmentProvider.equipments.where((e) => e.collegeId == widget.college.id).length;
    final totalEmployees = employeeProvider.employees.where((e) => e.collegeId == widget.college.id).length;
    final totalVisitors = visitorProvider.visitors.where((v) => v.collegeId == widget.college.id).length;

    // Calculate departments and not working equipment for this college
    final totalDepartments = departmentProvider.getDepartmentsForCollege(widget.college.id).length;
    final notWorkingEquipments = equipmentProvider.equipments
        .where((e) => e.collegeId == widget.college.id && e.status != 'Working')
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
            children: [
              DashboardTile(
                count: totalEquipments.toString(),
                title: 'Total Equipments',
                icon: Icons.devices_other,
                color: Colors.green,
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
                color: Colors.blue,
              ),
              DashboardTile(
                count: totalVisitors.toString(),
                title: 'Total Visitors',
                icon: Icons.person_pin,
                color: Colors.teal,
              ),
              DashboardTile(
                count: notWorkingEquipments.toString(),
                title: 'Equipments Not Working',
                icon: Icons.build,
                color: Colors.red,
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              _showDepartmentSelectionDialog();
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Perform Inspection Verification'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50), // Make button full width
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _launchUrl('https://dciindia.gov.in/InspetionProfomas.aspx'),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text(
                  'Check DCI Inspection Proformas',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
