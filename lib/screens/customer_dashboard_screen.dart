import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/college.dart';
import 'package:supreme_institution/providers/college_provider.dart';
import 'package:supreme_institution/services/auth_service.dart';
import 'package:supreme_institution/widgets/find_equipment_widget.dart';
import 'package:supreme_institution/widgets/customer_home_tab.dart';

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
    await collegeProvider.fetchColleges(); // Ensure colleges are fetched
    try {
      final college = collegeProvider.colleges.firstWhere(
        (c) => c.id == widget.collegeName, // collegeName is collegeId
      );
      setState(() {
        _associatedCollege = college;
      });
    } catch (e) {
      debugPrint('Associated college not found for customer: ${widget.collegeName}');
      // Handle error, e.g., show a message or navigate away
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_associatedCollege == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Associated College Data...')),
        body: const Center(child: const CircularProgressIndicator()),
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
            const Center(child: Text('College Equipments Page')), // Placeholder
          ],
        ),
      ),
    );
  }
}