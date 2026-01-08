import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/college.dart';
import 'package:supreme_institution/screens/manage_customers_screen.dart';
import 'package:supreme_institution/screens/manage_employees_screen.dart';
import 'package:supreme_institution/screens/manage_equipments_screen.dart';
import 'package:supreme_institution/screens/manage_departments_screen.dart';
import 'package:supreme_institution/screens/manage_tickets_screen.dart';
import 'package:supreme_institution/services/auth_service.dart';
import 'package:supreme_institution/widgets/college_home_tab.dart';

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

  @override
  void initState() {
    super.initState();
    _currentCollege = widget.college;
    _widgetOptions = <Widget>[
      CollegeHomeTab(college: _currentCollege),
      ManageEquipmentsScreen(collegeName: _currentCollege.id),
      ManageEmployeesScreen(
        collegeId: _currentCollege.id,
        collegeType: _currentCollege.type, // Pass the college type here
      ),
      ManageCustomersScreen(collegeName: _currentCollege.id),
      ManageDepartmentsScreen(college: _currentCollege),
      ManageTicketsScreen(
        userId: _currentCollege.id,
        userRole: 'college',
        collegeId: _currentCollege.id,
        collegeName: _currentCollege.name,
      ),
    ];
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
            icon: Icon(Icons.person_pin),
            label: 'Customers',
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