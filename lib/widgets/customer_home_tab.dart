import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/college.dart';
import 'package:supreme_institution/models/equipment.dart';
import 'package:supreme_institution/models/inspection_result.dart';
import 'package:supreme_institution/models/ticket.dart';
import 'package:supreme_institution/providers/department_provider.dart';
import 'package:supreme_institution/providers/employee_provider.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';
import 'package:supreme_institution/providers/inspection_provider.dart';
import 'package:supreme_institution/providers/ticket_provider.dart';
import 'package:supreme_institution/screens/add_edit_ticket_screen.dart';
import 'package:supreme_institution/widgets/dashboard_tile.dart';

class CustomerHomeTab extends StatelessWidget {
  final College associatedCollege; // Changed from collegeName

  const CustomerHomeTab({super.key, required this.associatedCollege}); // Changed constructor

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
    
    debugPrint('🔍 [CustomerHomeTab] College: ${associatedCollege.name}');
    debugPrint('🔍 [CustomerHomeTab] College Equipments: $collegeEquipments');
    debugPrint('🔍 [CustomerHomeTab] Total Departments: $totalDepartments');
    debugPrint('🔍 [CustomerHomeTab] Total Employees: $totalEmployees');
    debugPrint('🔍 [CustomerHomeTab] Not Working Equipments: $notWorkingEquipments');

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
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
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Raise Support Ticket', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final newTicket = await Navigator.of(context).push<Ticket>(
                MaterialPageRoute(
                  builder: (context) => const AddEditTicketScreen(),
                ),
              );
              if (newTicket != null) {
                final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
                final ticket = Ticket(
                  id: DateTime.now().toString(),
                  title: newTicket.title,
                  description: newTicket.description,
                  status: newTicket.status,
                  raisedBy: associatedCollege.id, // Customer ID is the college ID in this context
                  raisedTo: 'admin',
                  timestamp: DateTime.now(),
                );
                ticketProvider.addTicket(ticket);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ticket raised successfully.')),
                );
              }
            },
            icon: const Icon(Icons.confirmation_number),
            label: const Text('Raise a Ticket'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}