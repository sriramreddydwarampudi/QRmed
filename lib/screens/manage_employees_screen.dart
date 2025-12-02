import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/employee.dart';
import '../providers/employee_provider.dart';
import '../providers/department_provider.dart'; // Add department provider
import 'add_edit_employee_screen.dart'; // Import the new screen

class ManageEmployeesScreen extends StatefulWidget {
  final String collegeId;
  final String collegeType; // 'Dental' or 'MBBS'
  const ManageEmployeesScreen({super.key, required this.collegeId, required this.collegeType});

  @override
  State<ManageEmployeesScreen> createState() => _ManageEmployeesScreenState();
}

class _ManageEmployeesScreenState extends State<ManageEmployeesScreen> {
  List<Employee> _employees = [];

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    await Provider.of<EmployeeProvider>(context, listen: false).fetchEmployees();
    setState(() {
      _employees = Provider.of<EmployeeProvider>(context, listen: false)
          .employees
          .where((e) => e.collegeId == widget.collegeId)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Employees')),
      body: _employees.isEmpty
          ? const Center(child: Text('No employees found.'))
          : ListView.builder(
              itemCount: _employees.length,
              itemBuilder: (context, idx) {
                final e = _employees[idx];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(e.name),
                    subtitle: Text('ID: ${e.id}\nRole: ${e.role}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_red_eye),
                          tooltip: 'View',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Employee Details'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Name:${e.name}'),
                                      Text('ID: ${e.id}'),
                                      Text('Role: \\${e.role}'),
                                      Text('Email: \\${e.email}'),
                                      Text('Phone: \\${e.phone}'),
                                      Text('College: \\${e.collegeId}'),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit',
                          onPressed: () async {
                            final updatedEmployee = await Navigator.of(context).push<Employee>(
                              MaterialPageRoute(
                                builder: (context) => AddEditEmployeeScreen(
                                  employee: e,
                                  collegeId: widget.collegeId,
                                  collegeType: widget.collegeType,
                                ),
                              ),
                            );
                            if (updatedEmployee != null) {
                              await Provider.of<EmployeeProvider>(context, listen: false)
                                  .updateEmployee(e.id, updatedEmployee);
                              await _fetchEmployees();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Employee updated successfully.')),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: 'Delete',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Employee'),
                                content: const Text('Are you sure you want to delete this employee?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await Provider.of<EmployeeProvider>(context, listen: false)
                                  .deleteEmployee(e.id);
                              await _fetchEmployees();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Employee deleted.')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Check if departments exist (handle both null and empty)
          final departmentProvider = Provider.of<DepartmentProvider>(context, listen: false);
          final departments = departmentProvider.getDepartmentsForCollege(widget.collegeId);
          
          if (departments == null || departments.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Create departments first! Employees must be assigned to departments.'),
                duration: Duration(seconds: 4),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          final newEmployee = await Navigator.of(context).push<Employee>(
            MaterialPageRoute(
              builder: (context) => AddEditEmployeeScreen(
                collegeId: widget.collegeId,
                collegeType: widget.collegeType,
              ),
            ),
          );
          if (newEmployee != null) {
            await Provider.of<EmployeeProvider>(context, listen: false)
                .addEmployee(newEmployee);
            await _fetchEmployees();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Employee added successfully.')),
            );
          }
        },
        tooltip: 'Add Employee',
        child: const Icon(Icons.add),
      ),
    );
  }
}
