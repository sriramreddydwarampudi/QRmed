import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/college.dart';
import 'package:supreme_institution/models/customer.dart';
import 'package:supreme_institution/models/employee.dart';
import '../providers/college_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/customer_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  List<String> _allLogins = [];
  String? _selectedLogin;

  @override
  void initState() {
    super.initState();
    _fetchAllLogins();
  }

  Future<void> _fetchAllLogins() async {
    final collegeProvider = Provider.of<CollegeProvider>(context, listen: false);
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    await collegeProvider.fetchColleges();
    await employeeProvider.fetchEmployees();
    await customerProvider.fetchCustomers();
    final logins = <String>[];
    logins.addAll(collegeProvider.colleges.map((c) => c.id));
    logins.addAll(employeeProvider.employees.map((e) => e.id));
    logins.addAll(customerProvider.customers.map((c) => c.id));
    logins.add('supreme@supreme.com');
    setState(() {
      _allLogins = logins;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    await Future.delayed(const Duration(milliseconds: 500));

    // Admin login
    if (email == 'supreme@supreme.com' && password == '1234567890') {
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacementNamed('/admin');
      return;
    }

    // College login
    final collegeProvider = Provider.of<CollegeProvider>(context, listen: false);
    College? college;
    try {
      college = collegeProvider.colleges.firstWhere((c) => c.id == email && c.password == password);
    } catch (_) {
      college = null;
    }
    if (college != null) {
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacementNamed(
        '/collegeDashboard',
        arguments: college.id,
      );
      return;
    }

    // Employee login
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    Employee? employee;
    try {
      employee = employeeProvider.employees.firstWhere((e) => e.id == email && e.password == password);
    } catch (_) {
      employee = null;
    }
    if (employee != null) {
      setState(() => _isLoading = false);
      final collegeProvider = Provider.of<CollegeProvider>(context, listen: false);
      String collegeName = 'College'; // Default name
      try {
        final college = collegeProvider.colleges.firstWhere((c) => c.id == employee!.collegeId);
        collegeName = college.name;
      } catch (_) {
        collegeName = 'College'; // College not found, use default
        debugPrint("Could not find college for employee. Using default name.");
      }
      Navigator.of(context).pushReplacementNamed('/employeeDashboard',
          arguments: {'name': employee.name, 'collegeName': collegeName});
      return;
    }

    // Customer login
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    Customer? customer;
    try {
      customer = customerProvider.customers.firstWhere((c) => c.id == email && c.password == password);
    } catch (_) {
      customer = null;
    }
    if (customer != null) {
      setState(() => _isLoading = false);
      final collegeProvider = Provider.of<CollegeProvider>(context, listen: false);
      String collegeName = 'College'; // Default name
      try {
        final college = collegeProvider.colleges.firstWhere((c) => c.id == customer!.collegeId);
        collegeName = college.name;
      } catch (_) {
        collegeName = 'College'; // College not found, use default
        debugPrint("Could not find college for customer. Using default name.");
      }
      Navigator.of(context).pushReplacementNamed('/customerDashboard',
          arguments: {'name': customer.name, 'collegeName': collegeName});
      return;
    }

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid credentials.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supreme Institution Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedLogin,
                  items: _allLogins.map((id) => DropdownMenuItem(
                    value: id,
                    child: Text(id),
                  )).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedLogin = val;
                      _emailController.text = val ?? '';
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Select Login ID',
                    prefixIcon: Icon(Icons.account_circle),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a login ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _login,
                              child: const Text('Login'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Already logged in successfully',
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
