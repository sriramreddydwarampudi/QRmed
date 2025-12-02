import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/college.dart';
import 'package:supreme_institution/providers/college_provider.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';
import 'package:supreme_institution/providers/employee_provider.dart';
import 'package:supreme_institution/services/auth_service.dart';
import 'package:supreme_institution/widgets/find_equipment_widget.dart';
import 'package:supreme_institution/widgets/customer_home_tab.dart';
import 'package:supreme_institution/widgets/college_equipments_widget.dart';

class CustomerDashboardScreen extends StatefulWidget {
  final String customerName;
  final String collegeName; // This is actually collegeId
  const CustomerDashboardScreen({super.key, required this.customerName, required this.collegeName});

  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  College? _associatedCollege;

  @override
  void initState() {
    super.initState();
    _fetchAssociatedCollegeDetails();
  }

  Future<void> _fetchAssociatedCollegeDetails() async {
    final collegeProvider = Provider.of<CollegeProvider>(context, listen: false);
    final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    
    await collegeProvider.fetchColleges();
    await equipmentProvider.fetchEquipments();
    await employeeProvider.fetchEmployees();
    
    try {
      final college = collegeProvider.colleges.firstWhere(
        (c) => c.id == widget.collegeName,
      );
      debugPrint('✅ [CustomerDashboard] Loaded college: ${college.name}');
      debugPrint('✅ [CustomerDashboard] Total equipments: ${equipmentProvider.equipments.length}');
      debugPrint('✅ [CustomerDashboard] Total employees: ${employeeProvider.employees.length}');
      
      setState(() {
        _associatedCollege = college;
      });
    } catch (e) {
      debugPrint('❌ Associated college not found for customer: ${widget.collegeName}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_associatedCollege == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Associated College Data...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.customerName),
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
              Tab(icon: const Icon(Icons.school), text: '${_associatedCollege!.name} Equipments',),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            CustomerHomeTab(associatedCollege: _associatedCollege!),
            const FindEquipmentWidget(),
            CollegeEquipmentsWidget(collegeName: _associatedCollege!.id),
          ],
        ),
      ),
    );
  }
}