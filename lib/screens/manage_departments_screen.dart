import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/college.dart';
import 'package:supreme_institution/models/department.dart';
import 'package:supreme_institution/providers/department_provider.dart';

class ManageDepartmentsScreen extends StatefulWidget {
  final College college;

  const ManageDepartmentsScreen({super.key, required this.college});

  @override
  _ManageDepartmentsScreenState createState() => _ManageDepartmentsScreenState();
}

class _ManageDepartmentsScreenState extends State<ManageDepartmentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final departmentProvider = Provider.of<DepartmentProvider>(context);
    final departments = departmentProvider.getDepartmentsForCollege(widget.college.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Departments for ${widget.college.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Department Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a department name';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final newDepartment = Department(
                          id: DateTime.now().toString(),
                          name: _nameController.text,
                          collegeId: widget.college.id,
                        );
                        departmentProvider.addDepartment(newDepartment);
                        _nameController.clear();
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: departments.length,
                itemBuilder: (context, index) {
                  final department = departments[index];
                  return Card(
                    child: ListTile(
                      title: Text(department.name),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
