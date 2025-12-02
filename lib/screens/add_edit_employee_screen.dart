import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/department.dart';
import 'package:supreme_institution/models/employee.dart';
import 'package:supreme_institution/providers/department_provider.dart';

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
      'Non-Teaching Staff',
    ],
    'MBBS': [
      'Dean / Principal',
      'Professor',
      'Associate Professor',
      'Assistant Professor',
      'Senior Resident',
      'Junior Resident',
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
    _passwordController.dispose();
    super.dispose();
  }

  void _saveEmployee() {
    if (_formKey.currentState!.validate()) {
      final employeeId = widget.employee?.id ?? '${_nameController.text.trim().toLowerCase().replaceAll(' ', '.')}@${widget.collegeId}';

      final newEmployee = Employee(
        id: employeeId,
        name: _nameController.text.trim(),
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
              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                decoration: const InputDecoration(labelText: 'Department'),
                items: departments.map((Department department) {
                  return DropdownMenuItem<String>(
                    value: department.name,
                    child: Text(department.name),
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
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: _availableRoles.map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
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
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
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