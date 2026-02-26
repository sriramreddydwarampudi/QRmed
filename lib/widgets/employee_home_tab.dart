import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';
import 'package:supreme_institution/providers/notification_provider.dart';
import 'package:supreme_institution/screens/my_equipments_screen.dart';
import 'package:supreme_institution/widgets/dashboard_tile.dart';

class EmployeeHomeTab extends StatefulWidget {
  final String collegeName; // This seems to be collegeId based on previous context
  final String employeeId; // Renamed from employeeName

  const EmployeeHomeTab({
    super.key,
    required this.collegeName,
    required this.employeeId, // Renamed from employeeName
  });

  @override
  State<EmployeeHomeTab> createState() => _EmployeeHomeTabState();
}

class _EmployeeHomeTabState extends State<EmployeeHomeTab> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAppProviders();
  }

  Future<void> _initializeAppProviders() async {
    final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    // Initialize system notification listening
    notificationProvider.startListening(widget.employeeId);

    await equipmentProvider.fetchEquipments();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final equipmentProvider = Provider.of<EquipmentProvider>(context);

    // Filtering data based on collegeId
    final collegeEquipments = equipmentProvider.equipments.where((e) => e.collegeId == widget.collegeName);
    final myEquipments = collegeEquipments.where((e) => e.assignedEmployeeId == widget.employeeId); // Use employeeId

    final notWorkingCount = myEquipments.where((e) => e.status != 'Working').length;

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
            childAspectRatio: 0.9,
            children: [
              DashboardTile(
                count: collegeEquipments.length.toString(),
                title: 'College Equipments',
                icon: Icons.school,
                color: Colors.blue,
                onTap: () => DefaultTabController.of(context).animateTo(3),
              ),
              DashboardTile(
                count: myEquipments.length.toString(),
                title: 'My Equipments',
                icon: Icons.person_pin_circle,
                color: Colors.green,
                onTap: () => DefaultTabController.of(context).animateTo(2),
              ),
              DashboardTile(
                count: notWorkingCount.toString(),
                title: 'My Equipments Not Working',
                icon: Icons.build,
                color: Colors.red,
                onTap: () => DefaultTabController.of(context).animateTo(2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}