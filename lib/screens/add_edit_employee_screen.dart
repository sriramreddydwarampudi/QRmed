import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Ensure this is imported
import 'package:supreme_institution/models/department.dart'; // Ensure this is imported
import 'package:supreme_institution/models/employee.dart'; // Ensure this is imported
import 'package:supreme_institution/providers/department_provider.dart'; // Ensure this is imported
import 'dart:math'; // Added for Random class
import 'package:english_words/english_words.dart' as english_words; // Added for meaningful words

class AddEditEmployeeScreen extends StatefulWidget {
  final Employee? employee;
  final String collegeId;
  final String collegeType; // 'Dental' or 'MBBS'

  const AddEditEmployeeScreen({
    super.key,
    this.employee,
    required this.collegeId,
    required this.collegeType,
  });

  @override
  State<AddEditEmployeeScreen> createState() => _AddEditEmployeeScreenState();
}

class _AddEditEmployeeScreenState extends State<AddEditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedDepartment;
  String? _selectedRole;
  bool _obscurePassword = true;

  // Predefined roles based on college type, as per inspection data requirements.
  final Map<String, List<String>> _rolesByCollegeType = {
    'Dental': [
      'Principal / Dean',
      'Professor',
      'Reader',
      'Senior Lecturer',
      'Lecturer / Tutor',
      'Student',
      'Non-Teaching Staff',
    ],
    'MBBS': [
      'Dean / Principal',
      'Professor',
      'Associate Professor',
      'Assistant Professor',
      'Senior Resident',
      'Junior Resident',
      'Student',
      'Non-Teaching Staff',
    ],
  };

  late List<String> _availableRoles;

  @override
  void initState() {
    super.initState();
    // Determine available roles based on the college type passed to the screen.
    _availableRoles = _rolesByCollegeType[widget.collegeType] ?? [];

    if (widget.employee != null) {
      _nameController.text = widget.employee!.name;
      _emailController.text = widget.employee!.email ?? '';
      _phoneController.text = widget.employee!.phone ?? '';
      _passwordController.text = widget.employee!.password;
      _selectedDepartment = widget.employee!.department;
      // Ensure the existing role is valid, otherwise, it will be null.
      if (_availableRoles.contains(widget.employee!.role)) {
        _selectedRole = widget.employee!.role;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _generatePassword() {
    final random = Random();
    String word = "";
    // Keep picking until we find a word with 6-10 letters
    while (word.length < 6 || word.length > 10) {
      word = english_words.all.elementAt(random.nextInt(english_words.all.length));
    }
    return word;
  }

  void _saveEmployee() {
    if (_formKey.currentState!.validate()) {
      final employeeId = widget.employee?.id ?? '${_nameController.text.trim().toLowerCase().replaceAll(' ', '.')}@${widget.collegeId}';

      final newEmployee = Employee(
        id: employeeId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        collegeId: widget.collegeId,
        role: _selectedRole!,
        department: _selectedDepartment,
      );
      Navigator.of(context).pop(newEmployee);
    }
  }

  @override
  Widget build(BuildContext context) {
    final departmentProvider = Provider.of<DepartmentProvider>(context);
    final departments = departmentProvider.getDepartmentsForCollege(widget.collegeId);
    
    // Ensure unique department names to avoid "Duplicate value" error in Dropdown
    final uniqueDepartmentNames = departments.map((d) {
      return d.subSelectionType != null ? "${d.name} (${d.subSelectionType})" : d.name;
    }).toSet().toList()..sort();
    
    // Safety check: if _selectedDepartment is not in the list, add it to avoid assertion error
    if (_selectedDepartment != null && !uniqueDepartmentNames.contains(_selectedDepartment)) {
      uniqueDepartmentNames.add(_selectedDepartment!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee == null ? 'Add Employee' : 'Edit Employee'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Employee Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the employee name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email address.';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^\d{10}').hasMatch(value)) {
                      return 'Please enter a valid phone number (at least 10 digits).';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedDepartment, // Use value instead of initialValue for better reactivity
                decoration: const InputDecoration(labelText: 'Department'),
                selectedItemBuilder: (BuildContext context) {
                  return uniqueDepartmentNames.map((String name) {
                    return Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    );
                  }).toList();
                },
                items: uniqueDepartmentNames.map((String name) {
                  return DropdownMenuItem<String>(
                    value: name,
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedDepartment = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a department.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                selectedItemBuilder: (BuildContext context) {
                  return _availableRoles.map((String role) {
                    return Text(
                      role,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    );
                  }).toList();
                },
                items: _availableRoles.map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(
                      role,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedRole = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a role.';
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
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min, // Important to prevent Row from expanding
                    children: [
                      IconButton(
                        icon: const Icon(Icons.vpn_key), // Icon for generate password
                        tooltip: 'Generate Password',
                        onPressed: () {
                          setState(() {
                            _passwordController.text = _generatePassword();
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password.';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveEmployee,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.employee == null ? 'Add Employee' : 'Update Employee',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
