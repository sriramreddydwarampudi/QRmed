import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/college.dart';
import 'package:supreme_institution/models/visitor.dart';
import 'package:supreme_institution/models/employee.dart';
import '../providers/college_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/visitor_provider.dart';
import '../widgets/app_loading_widget.dart';

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
  List<String> _filteredLogins = [];
  String? _selectedLogin;
  bool _isInitialLoad = true;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _fetchAllLogins();
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    final input = _emailController.text.trim();
    setState(() {
      if (input.isEmpty) {
        _filteredLogins = [];
        _showSuggestions = false;
      } else {
        _filteredLogins = _allLogins
            .where((login) => login.toLowerCase().contains(input.toLowerCase()))
            .toList();
        _showSuggestions = _filteredLogins.isNotEmpty;
      }
    });
  }

  void _selectLogin(String login) {
    setState(() {
      _selectedLogin = login;
      _emailController.text = login;
      _showSuggestions = false;
      _filteredLogins = [];
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialLoad) {
      _fetchAllLogins();
    }
    _isInitialLoad = false;
  }

  Future<void> _fetchAllLogins() async {
    final collegeProvider = Provider.of<CollegeProvider>(context, listen: false);
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final visitorProvider = Provider.of<VisitorProvider>(context, listen: false);
    await collegeProvider.fetchColleges();
    await employeeProvider.fetchEmployees();
    await visitorProvider.fetchVisitors();
    final logins = <String>[];
    logins.addAll(collegeProvider.colleges.map((c) => c.id));
    logins.addAll(employeeProvider.employees.map((e) => e.id));
    logins.addAll(visitorProvider.visitors.map((v) => v.id));
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

    if (email == 'supreme@supreme.com' && password == '1234567890') {
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacementNamed('/admin');
      return;
    }

    final collegeProvider = Provider.of<CollegeProvider>(context, listen: false);
    College? college;
    try {
      college = collegeProvider.colleges.firstWhere((c) => c.id == email && c.password == password);
    } catch (_) {
      college = null;
    }
    if (college != null) {
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacementNamed('/collegeDashboard', arguments: college.id);
      return;
    }

    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    Employee? employee;
    try {
      employee = employeeProvider.employees.firstWhere((e) => e.id == email && e.password == password);
    } catch (_) {
      employee = null;
    }
    if (employee != null) {
      final verifyEmployee = await employeeProvider.getEmployeeById(employee.id);
      if (verifyEmployee == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid credentials. Employee account not found.')),
        );
        return;
      }
      setState(() => _isLoading = false);
      String collegeName = 'College';
      try {
        final college = collegeProvider.colleges.firstWhere((c) => c.id == employee!.collegeId);
        collegeName = college.name;
      } catch (_) {
        collegeName = 'College';
      }
      Navigator.of(context).pushReplacementNamed('/employeeDashboard',
          arguments: {'employeeId': employee.id, 'collegeName': collegeName});
      return;
    }

    final visitorProvider = Provider.of<VisitorProvider>(context, listen: false);
    Visitor? visitor;
    try {
      visitor = visitorProvider.visitors.firstWhere((v) => v.id == email && v.password == password);
    } catch (_) {
      visitor = null;
    }
    if (visitor != null) {
      final verifyVisitor = await visitorProvider.getVisitorById(visitor.id);
      if (verifyVisitor == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid credentials. Visitor account not found.')),
        );
        return;
      }
      setState(() => _isLoading = false);
      String collegeName = 'College';
      try {
        final college = collegeProvider.colleges.firstWhere((c) => c.id == visitor!.collegeId);
        collegeName = college.name;
      } catch (_) {
        collegeName = 'College';
      }
      Navigator.of(context).pushReplacementNamed('/customerDashboard',
          arguments: {'name': visitor.name, 'collegeName': collegeName});
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
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Login ID',
                    prefixIcon: Icon(Icons.account_circle),
                    hintText: 'Type to search...',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a login ID';
                    }
                    return null;
                  },
                ),
                if (_showSuggestions)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredLogins.length,
                      itemBuilder: (context, index) {
                        final login = _filteredLogins[index];
                        return Material(
                          child: InkWell(
                            onTap: () => _selectLogin(login),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Text(login),
                            ),
                          ),
                        );
                      },
                    ),
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
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? Column(
                        children: [
                          Image.asset('assets/supreme logo.png', width: 60, height: 60),
                          const SizedBox(height: 8),
                          const CircularProgressIndicator(),
                        ],
                      )
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
