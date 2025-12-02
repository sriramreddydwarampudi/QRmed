import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/employee.dart';
import 'package:supreme_institution/providers/employee_provider.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';
import 'package:supreme_institution/services/auth_service.dart';
import 'package:supreme_institution/widgets/find_equipment_widget.dart';
import 'package:supreme_institution/widgets/my_equipments_widget.dart';
import 'package:supreme_institution/widgets/college_equipments_widget.dart';
import 'package:supreme_institution/widgets/employee_home_tab.dart';

class EmployeeDashboardScreen extends StatelessWidget {
  final String employeeId; // Renamed from employeeName
  final String collegeName; // This is likely collegeId
  const EmployeeDashboardScreen({super.key, required this.employeeId, required this.collegeName});

  @override
  Widget build(BuildContext context) {
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(employeeId), // Display employeeId or name here. Assuming it's ID for now.
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                Provider.of<AuthService>(context, listen: false).signOut(context);
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              const Tab(icon: Icon(Icons.home), text: 'Home'),
              const Tab(icon: Icon(Icons.search), text: 'Find Out'),
              const Tab(icon: Icon(Icons.person_pin_circle_outlined), text: 'My Equipments'),
              Tab(icon: const Icon(Icons.school), text: '$collegeName Equipments',),
            ],
          ),
        ),
        body: FutureBuilder<Employee?>(
          future: employeeProvider.getEmployeeById(employeeId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('Error: Employee not found.'));
            }
            final employee = snapshot.data!;
            final employeeName = employee.name;

            return FutureBuilder<void>(
              future: equipmentProvider.fetchEquipments(),
              builder: (context, equipmentSnapshot) {
                if (equipmentSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return TabBarView(
                  children: [
                    EmployeeHomeTab(collegeName: employee.collegeId, employeeId: employeeId),
                    const FindEquipmentWidget(),
                    MyEquipmentsWidget(employeeId: employeeId, collegeName: employee.collegeId),
                    CollegeEquipmentsWidget(collegeName: employee.collegeId),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}