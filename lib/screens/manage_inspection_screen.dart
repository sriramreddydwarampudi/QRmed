import 'package:supreme_institution/models/department.dart';
import 'package:supreme_institution/providers/department_provider.dart';
import 'package:supreme_institution/screens/manage_requirements_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/college.dart';
import 'package:supreme_institution/models/inspection_result.dart';
import 'package:supreme_institution/providers/college_provider.dart';
import 'package:supreme_institution/providers/inspection_provider.dart';

class ManageInspectionScreen extends StatefulWidget {
  const ManageInspectionScreen({Key? key}) : super(key: key);

  @override
  _ManageInspectionScreenState createState() => _ManageInspectionScreenState();
}

class _ManageInspectionScreenState extends State<ManageInspectionScreen> {
  College? _selectedCollege;
  Department? _selectedDepartment;
  InspectionResult? _inspectionResult;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Fetch colleges when the screen loads
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      Provider.of<CollegeProvider>(context, listen: false).fetchColleges();
    });
  }

  Future<void> _runInspection() async {
    if (_selectedCollege == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final inspectionProvider = Provider.of<InspectionProvider>(context, listen: false);
    final result = await inspectionProvider.performInspectionForCollege(
      college: _selectedCollege!,
      department: _selectedDepartment,
    );

    setState(() {
      _inspectionResult = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final collegeProvider = Provider.of<CollegeProvider>(context);
    final departmentProvider = Provider.of<DepartmentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Inspection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<College>(
              value: _selectedCollege,
              decoration: const InputDecoration(labelText: 'Select College'),
              items: collegeProvider.colleges.map((college) {
                return DropdownMenuItem<College>(
                  value: college,
                  child: Text(college.name),
                );
              }).toList(),
              onChanged: (college) {
                setState(() {
                  _selectedCollege = college;
                  _selectedDepartment = null;
                  _inspectionResult = null;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Department>(
              value: _selectedDepartment,
              decoration: const InputDecoration(labelText: 'Select Department'),
              items: departmentProvider.getDepartmentsForCollege(_selectedCollege!.id).map((department) {
                return DropdownMenuItem<Department>(
                  value: department,
                  child: Text(department.name),
                );
              }).toList(),
              onChanged: (department) {
                setState(() {
                  _selectedDepartment = department;
                  _inspectionResult = null;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _selectedCollege != null && !_isLoading ? _runInspection : null,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Perform Inspection'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageRequirementsScreen(),
                      ),
                    );
                  },
                  child: const Text('Manage Requirements'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_inspectionResult != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inspection Results for ${_selectedCollege!.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Overall Status: ${_inspectionResult!.passed ? 'PASS' : 'FAIL'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _inspectionResult!.passed ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildItemList(
                        title: 'Missing Equipment',
                        items: _inspectionResult!.missingEquipment,
                      ),
                      const SizedBox(height: 16),
                      _buildItemList(
                        title: 'Missing Staff',
                        items: _inspectionResult!.missingStaff,
                      ),
                      const SizedBox(height: 16),
                      _buildItemList(
                        title: 'Excess Equipment',
                        items: _inspectionResult!.excessEquipment,
                      ),
                      const SizedBox(height: 16),
                      _buildItemList(
                        title: 'Excess Staff',
                        items: _inspectionResult!.excessStaff,
                      ),
                      const SizedBox(height: 16),
                      _buildItemList(
                        title: 'Notes',
                        items: _inspectionResult!.notes,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList({required String title, required List<String> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Text('None')
        else
          ...items.map((item) => Text('• $item')).toList(),
      ],
    );
  }
}