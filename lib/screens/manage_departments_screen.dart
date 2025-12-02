import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/data/requirements_data.dart';
import 'package:supreme_institution/models/college.dart';
import 'package:supreme_institution/models/department.dart';
import 'package:supreme_institution/providers/department_provider.dart';

class ManageDepartmentsScreen extends StatefulWidget {
  final College college;

  const ManageDepartmentsScreen({super.key, required this.college});

  @override
  _ManageDepartmentsScreenState createState() =>
      _ManageDepartmentsScreenState();
}

class _ManageDepartmentsScreenState extends State<ManageDepartmentsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedDepartment;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showEditDialog(Department department, List<String> departmentNames) {
    String? newSelectedDepartment = department.name;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Department',
                  style: TextStyle(color: Colors.blue)),
              content: DropdownButtonFormField<String>(
                value: newSelectedDepartment,
                items: departmentNames.map((String deptName) {
                  return DropdownMenuItem<String>(
                    value: deptName,
                    child:
                        Text(deptName, style: const TextStyle(color: Colors.blue)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    newSelectedDepartment = newValue;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Department Name',
                  labelStyle: TextStyle(color: Colors.blue),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 1.0),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                  onPressed: () {
                    if (newSelectedDepartment != null) {
                      final updatedDepartment = Department(
                        id: department.id,
                        name: newSelectedDepartment!,
                        collegeId: department.collegeId,
                      );
                      Provider.of<DepartmentProvider>(context, listen: false)
                          .updateDepartment(updatedDepartment);
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final departmentProvider = Provider.of<DepartmentProvider>(context);
    final departments =
        departmentProvider.getDepartmentsForCollege(widget.college.id);

    final filteredDepartments = departments.where((department) {
      return department.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final collegeType = widget.college.type;
    final collegeSeats = widget.college.seats;
    final typeKey = collegeType == 'Dental' ? 'BDS' : collegeType;
    final departmentNames =
        requirements[typeKey]?[collegeSeats]?.keys.toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.college.name),
            Text(
              widget.college.type,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
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
                    child: DropdownButtonFormField<String>(
                      value: _selectedDepartment,
                      items: departmentNames.map((String department) {
                        return DropdownMenuItem<String>(
                          value: department,
                          child: Text(department,
                              style: const TextStyle(color: Colors.blue)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDepartment = newValue;
                        });
                      },
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        labelText: 'Department Name',
                        labelStyle: TextStyle(color: Colors.blue),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue, width: 2.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue, width: 1.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a department';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final newDepartment = Department(
                          id: DateTime.now().toString(),
                          name: _selectedDepartment!,
                          collegeId: widget.college.id,
                        );
                        departmentProvider.addDepartment(newDepartment);
                        setState(() {
                          _selectedDepartment = null;
                        });
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Departments',
                  labelStyle: const TextStyle(color: Colors.blue),
                  prefixIcon: const Icon(Icons.search, color: Colors.blue),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, color: Colors.blue),
                          onPressed: () {
                            _searchController.clear();
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.blue, width: 1.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filteredDepartments.length,
                itemBuilder: (context, index) {
                  final department = filteredDepartments[index];
                  return Card(
                    color: Colors.blue,
                    child: ListTile(
                      title: Text(
                        department.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () =>
                                _showEditDialog(department, departmentNames),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: () {
                              departmentProvider
                                  .deleteDepartment(department.id);
                            },
                          ),
                        ],
                      ),
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
