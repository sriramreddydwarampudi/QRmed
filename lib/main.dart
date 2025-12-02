import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Required for Firebase.initializeApp
import 'package:supreme_institution/firebase_options.dart'; // Required for DefaultFirebaseOptions
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/manage_colleges_screen.dart';
import 'screens/add_edit_college_screen.dart';
import 'screens/manage_inspection_screen.dart';
import 'screens/employee_dashboard_screen.dart';
import 'screens/customer_dashboard_screen.dart';
import 'screens/college_dashboard_screen.dart';
import 'models/college.dart';
import 'providers/college_provider.dart';
import 'providers/employee_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/product_provider.dart';
import 'providers/equipment_provider.dart'; // Import EquipmentProvider
import 'providers/inspection_provider.dart'; // Import InspectionProvider
import 'providers/requirements_provider.dart'; // Import RequirementsProvider
import 'package:supreme_institution/providers/department_provider.dart'; // Import DepartmentProvider
import 'package:supreme_institution/providers/ticket_provider.dart'; // Import TicketProvider
import 'package:supreme_institution/services/auth_service.dart'; // Import AuthService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CollegeProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => EquipmentProvider()), // Add EquipmentProvider
        ChangeNotifierProvider(create: (_) => InspectionProvider()), // Add InspectionProvider
        ChangeNotifierProvider(create: (_) => RequirementsProvider()), // Add RequirementsProvider
        ChangeNotifierProvider(create: (_) => DepartmentProvider()), // Add DepartmentProvider
        ChangeNotifierProvider(create: (_) => TicketProvider()), // Add TicketProvider
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: Builder(builder: (context) {
        return MaterialApp(
          title: 'Supreme Institution',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const LoginScreen(),
            '/admin': (context) => const AdminDashboardScreen(),
            '/manageColleges': (context) => const ManageCollegesScreen(),
            '/manageInspection': (context) => const ManageInspectionScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/addEditCollege') {
              final college = settings.arguments as dynamic;
              return MaterialPageRoute(
                builder: (context) => AddEditCollegeScreen(college: college is College ? college : null),
              );
            }
            if (settings.name == '/employeeDashboard') {
              final args = settings.arguments as Map<String, String>? ?? {};
              final name = args['name'] ?? 'Employee';
              final collegeName = args['collegeName'] ?? 'College';
              return MaterialPageRoute(
                builder: (context) => EmployeeDashboardScreen(employeeId: name, collegeName: collegeName),
              );
            }
            if (settings.name == '/customerDashboard') {
              final args = settings.arguments as Map<String, String>? ?? {};
              final name = args['name'] ?? 'Customer';
              final collegeName = args['collegeName'] ?? 'College';
              return MaterialPageRoute(
                builder: (context) => CustomerDashboardScreen(customerName: name, collegeName: collegeName),
              );
            }
            if (settings.name == '/collegeDashboard') {
              final collegeId = settings.arguments as String? ?? '';
              final collegeProvider = Provider.of<CollegeProvider>(context, listen: false);
              final college = collegeProvider.colleges.firstWhere(
                (c) => c.id == collegeId,
                orElse: () => College(id: 'not-found', name: 'Error', city: '', type: '', seats: '', password: ''),
              );
              if (college.id == 'not-found') {
                return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('College not found'))));
              }
              return MaterialPageRoute(
                builder: (context) => CollegeDashboardScreen(college: college),
              );
            }
            return null;
          },
        );
      }),
    );
  }
}
