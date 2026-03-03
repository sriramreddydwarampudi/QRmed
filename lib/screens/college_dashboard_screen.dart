import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/college.dart';
import 'package:supreme_institution/providers/notification_provider.dart';
import 'package:supreme_institution/screens/manage_employees_screen.dart';
import 'package:supreme_institution/screens/manage_equipments_screen.dart';
import 'package:supreme_institution/screens/manage_departments_screen.dart';
import 'package:supreme_institution/screens/manage_tickets_screen.dart';
import 'package:supreme_institution/services/auth_service.dart';
import 'package:supreme_institution/widgets/college_home_tab.dart';
import 'package:supreme_institution/widgets/notification_bell.dart';
import 'package:supreme_institution/models/app_notification.dart';

class CollegeDashboardScreen extends StatefulWidget {
  final College college;

  const CollegeDashboardScreen({super.key, required this.college});

  @override
  State<CollegeDashboardScreen> createState() => _CollegeDashboardScreenState();
}

class _CollegeDashboardScreenState extends State<CollegeDashboardScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;
  late final College _currentCollege;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _currentCollege = widget.college;
    _widgetOptions = <Widget>[
      CollegeHomeTab(
        college: _currentCollege,
        onTabSelected: _onItemTapped,
      ),
      ManageEquipmentsScreen(collegeName: _currentCollege.id),
      ManageEmployeesScreen(
        collegeId: _currentCollege.id,
        collegeType: _currentCollege.type, // Pass the college type here
      ),
      ManageDepartmentsScreen(college: _currentCollege),
      ManageTicketsScreen(
        userId: _currentCollege.id,
        userRole: 'college',
        collegeId: _currentCollege.id,
        collegeName: _currentCollege.name,
      ),
    ];

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentCollege.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.white),
            tooltip: 'Test Admin Notification',
            onPressed: () async {
              print('DEBUG: College Test Button Pressed (College: ${_currentCollege.id})');
              final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
              
              try {
                print('DEBUG: Sending test notification to Admin from College ${_currentCollege.id}...');
                await notificationProvider.addNotification(AppNotification(
                  id: '',
                  title: 'College Test: Failure',
                  message: 'College ${_currentCollege.name} sent a test alert.',
                  timestamp: DateTime.now(),
                  targetUserId: 'admin',
                ));
                print('DEBUG: Notification added to Firestore for Admin');

                print('DEBUG: Triggering LOCAL notification for College...');
                await NotificationService.showSystemNotification(
                  id: 777,
                  title: 'College Local Test',
                  body: 'Alert sent to Admin.',
                );
                print('DEBUG: Local notification trigger completed');

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test complete: Alert sent to Admin + Local triggered')),
                  );
                }
              } catch (e) {
                print('DEBUG ERROR: College test failed: $e');
              }
            },
          ),
          NotificationBell(targetUserId: _currentCollege.id),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).signOut(context);
            },
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).primaryColor,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: 'Equipments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Employees',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Departments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: 'Tickets',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white, // Ensure selected item is clearly visible
        unselectedItemColor: Colors.white.withOpacity(0.7), // Adjusted opacity
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
