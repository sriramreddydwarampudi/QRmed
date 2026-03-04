import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/providers/notification_provider.dart';
import 'package:supreme_institution/screens/manage_colleges_screen.dart';
import 'package:supreme_institution/screens/manage_inspection_screen.dart';
import 'package:supreme_institution/screens/manage_tickets_screen.dart';
import 'package:supreme_institution/screens/admin_equipments_not_working_screen.dart';
import 'package:supreme_institution/screens/admin_add_equipment_screen.dart';
import 'package:supreme_institution/screens/admin_mass_stickers_screen.dart';
import 'package:supreme_institution/services/auth_service.dart';
import 'package:supreme_institution/widgets/admin_home_tab.dart';
import 'package:supreme_institution/widgets/notification_bell.dart';
import 'package:supreme_institution/services/notification_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for real-time notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      _notificationSubscription = notificationProvider.newNotificationStream.listen((notification) {
        if (mounted) {
          // If system notification is enabled, we rely on that.
          // Otherwise show the in-app snackbar.
          if (!NotificationService.isSystemNotificationEnabled) {
            _showNotificationSnackBar(notification.title, notification.message);
          }
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
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.red),
              tooltip: 'Test Notification',
              onPressed: () async {
                print('DEBUG: Admin Test Button Pressed');
                try {
                  print('DEBUG: Calling NotificationService.showSystemNotification...');
                  await NotificationService.showSystemNotification(
                    id: 999,
                    title: 'Admin Local Test',
                    body: 'If you see this, local notifications are working!',
                  );
                  print('DEBUG: NotificationService call completed');
                } catch (e) {
                  print('DEBUG ERROR: Admin Test failed: $e');
                }
              },
            ),
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
