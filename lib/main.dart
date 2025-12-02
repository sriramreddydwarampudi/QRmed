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
          title: 'QRmed',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2563EB),
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF1F2937),
              centerTitle: false,
              titleTextStyle: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
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
              final employeeId = args['employeeId'] ?? '';
              final collegeName = args['collegeName'] ?? 'College';
              return MaterialPageRoute(
                builder: (context) => EmployeeDashboardScreen(employeeId: employeeId, collegeName: collegeName),
              );
            }
            if (settings.name == '/customerDashboard') {
              final args = settings.arguments as Map<String, String>? ?? {};
              final name = args['name'] ?? 'Customer';
              final collegeId = args['collegeName'] ?? 'College';
              return MaterialPageRoute(
                builder: (context) => CustomerDashboardScreen(customerName: name, collegeName: collegeId),
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
