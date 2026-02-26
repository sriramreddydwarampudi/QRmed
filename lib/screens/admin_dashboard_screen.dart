import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/screens/manage_colleges_screen.dart';
import 'package:supreme_institution/screens/manage_inspection_screen.dart';
import 'package:supreme_institution/screens/manage_tickets_screen.dart';
import 'package:supreme_institution/screens/admin_equipments_not_working_screen.dart';
import 'package:supreme_institution/screens/admin_add_equipment_screen.dart';
import 'package:supreme_institution/screens/admin_mass_stickers_screen.dart';
import 'package:supreme_institution/services/auth_service.dart';
import 'package:supreme_institution/widgets/admin_home_tab.dart';
import 'package:supreme_institution/widgets/notification_bell.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            const NotificationBell(targetUserId: 'admin'),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                Provider.of<AuthService>(context, listen: false).signOut(context);
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.home), text: 'Home'),
              Tab(icon: Icon(Icons.school), text: 'Colleges'),
              Tab(icon: Icon(Icons.add_circle_outline), text: 'Add Equipment'),
              Tab(icon: Icon(Icons.folder_zip_outlined), text: 'Mass Stickers'),
              Tab(icon: Icon(Icons.fact_check), text: 'Inspection'),
              Tab(icon: Icon(Icons.confirmation_number), text: 'Tickets'),
              Tab(icon: Icon(Icons.error_outline), text: 'Equipments Not Working'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminHomeTab(),
            ManageCollegesScreen(),
            AdminAddEquipmentScreen(),
            AdminMassStickersScreen(),
            ManageInspectionScreen(),
            ManageTicketsScreen(userId: 'admin', userRole: 'admin', collegeId: ''),
            AdminEquipmentsNotWorkingScreen(),
          ],
        ),
      ),
    );
  }
}