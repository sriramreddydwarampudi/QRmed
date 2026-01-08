import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/employee.dart';
import '../providers/employee_provider.dart';
import '../providers/department_provider.dart';
import 'add_edit_employee_screen.dart';
import '../widgets/management_list_widget.dart';
import '../widgets/modern_details_dialog.dart';

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
    // Fetch departments to ensure they're loaded for validation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DepartmentProvider>(context, listen: false)
          .fetchDepartmentsForCollege(widget.collegeId);
    });
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
      appBar: AppBar(
        title: const Text('Manage Employees'),
        elevation: 0,
      ),
      body: ManagementListWidget(
        items: _employees.map((e) => ManagementListItem(
          id: e.id,
          title: e.name,
          subtitle: '${e.role} • ${e.email}',
          icon: Icons.person_outline,
          iconColor: const Color(0xFF059669),
          badge: e.role,
          badgeColor: Colors.blue,
          actions: [
            ManagementAction(
              label: 'View',
              icon: Icons.remove_red_eye,
              color: const Color(0xFF2563EB),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => ModernDetailsDialog(
                    title: 'Employee Details',
                    details: [
                      DetailRow(label: 'Name', value: e.name),
                      DetailRow(label: 'ID', value: e.id),
                      DetailRow(label: 'Role', value: e.role ?? '-'),
                      DetailRow(label: 'Department', value: e.department ?? '-'),
                      DetailRow(label: 'Email', value: e.email ?? '-'),
                      DetailRow(label: 'Phone', value: e.phone ?? '-'),
                      DetailRow(label: 'College', value: e.collegeId),
                    ],
                  ),
                );
              },
            ),
            ManagementAction(
              label: 'Edit',
              icon: Icons.edit,
              color: const Color(0xFF16A34A),
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
            ManagementAction(
              label: 'Delete',
              icon: Icons.delete,
              color: const Color(0xFFDC2626),
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
        )).toList(),
        emptyMessage: 'No employees found. Add one to get started!',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final departmentProvider = Provider.of<DepartmentProvider>(context, listen: false);
          // Ensure departments are fetched before checking
          await departmentProvider.fetchDepartmentsForCollege(widget.collegeId);
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
