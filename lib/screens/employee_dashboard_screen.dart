import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/employee.dart';
import 'package:supreme_institution/providers/employee_provider.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';
import 'package:supreme_institution/providers/notification_provider.dart';
import 'package:supreme_institution/services/auth_service.dart';
import 'package:supreme_institution/widgets/find_equipment_widget.dart';
import 'package:supreme_institution/widgets/my_equipments_widget.dart';
import 'package:supreme_institution/widgets/college_equipments_widget.dart';
import 'package:supreme_institution/widgets/employee_home_tab.dart';
import 'package:supreme_institution/widgets/notification_bell.dart';
import 'package:supreme_institution/services/notification_service.dart';
import 'package:supreme_institution/models/app_notification.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  final String employeeId;
  final String collegeName;

  const EmployeeDashboardScreen({
    super.key,
    required this.employeeId,
    required this.collegeName,
  });

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for real-time notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      _notificationSubscription = notificationProvider.newNotificationStream.listen((notification) {
        if (mounted) {
          _showNotificationSnackBar(notification.title, notification.message);
        }
      });
    });
  }

  void _showNotificationSnackBar(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E40AF).withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.employeeId),
          actions: [
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.red),
              tooltip: 'Test Notification Flow',
              onPressed: () async {
                final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
                
                // 1. Notify Admin
                await notificationProvider.addNotification(AppNotification(
                  id: '',
                  title: 'Employee Test: Equipment Failure',
                  message: 'Employee ${widget.employeeId} reported a test failure in ${widget.collegeName}.',
                  timestamp: DateTime.now(),
                  targetUserId: 'admin',
                ));

                // 2. Notify College
                await notificationProvider.addNotification(AppNotification(
                  id: '',
                  title: 'Employee Test: Equipment Failure',
                  message: 'Employee ${widget.employeeId} reported a test failure in your college.',
                  timestamp: DateTime.now(),
                  targetUserId: widget.collegeName, // Assuming collegeName is the ID used for notifications
                ));

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test alerts sent to Admin and College')),
                  );
                }
              },
            ),
            NotificationBell(targetUserId: widget.employeeId),
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
              Tab(icon: const Icon(Icons.school), text: '${widget.collegeName} Equipments'),
            ],
          ),
        ),
        body: FutureBuilder<Employee?>(
          future: employeeProvider.getEmployeeById(widget.employeeId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('Error: Employee not found.'));
            }
            final employee = snapshot.data!;

            return FutureBuilder<void>(
              future: equipmentProvider.fetchEquipments(),
              builder: (context, equipmentSnapshot) {
                if (equipmentSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return TabBarView(
                  children: [
                    EmployeeHomeTab(collegeName: employee.collegeId, employeeId: widget.employeeId),
                    const FindEquipmentWidget(),
                    MyEquipmentsWidget(employeeId: widget.employeeId, collegeName: employee.collegeId),
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
