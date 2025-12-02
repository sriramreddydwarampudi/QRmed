import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/screens/manage_colleges_screen.dart';
import 'package:supreme_institution/screens/manage_inspection_screen.dart';
import 'package:supreme_institution/screens/manage_tickets_screen.dart';
import 'package:supreme_institution/services/auth_service.dart';
import 'package:supreme_institution/widgets/admin_home_tab.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                Provider.of<AuthService>(context, listen: false).signOut(context);
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.home), text: 'Home'),
              Tab(icon: Icon(Icons.school), text: 'Colleges'),
              Tab(icon: Icon(Icons.fact_check), text: 'Inspection'),
              Tab(icon: Icon(Icons.confirmation_number), text: 'Tickets'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminHomeTab(),
            ManageCollegesScreen(),
            ManageInspectionScreen(),
            ManageTicketsScreen(userId: 'admin', userRole: 'admin', collegeId: ''),
          ],
        ),
      ),
    );
  }
}