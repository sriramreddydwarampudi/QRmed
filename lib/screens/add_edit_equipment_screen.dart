import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/data/requirements_data.dart';
import 'package:supreme_institution/data/department_group.dart';
import 'package:supreme_institution/models/college.dart';
import 'package:supreme_institution/models/equipment.dart'; // Add this import
import 'package:supreme_institution/providers/college_provider.dart';
import 'package:uuid/uuid.dart'; // Import the uuid package

class AddEditEquipmentScreen extends StatefulWidget {
  final String collegeName;
  final Equipment? equipment; // Pass existing equipment for editing

  const AddEditEquipmentScreen({
    super.key,
    required this.collegeName,
    this.equipment,
  });

  @override
  State<AddEditEquipmentScreen> createState() => _AddEditEquipmentScreenState();
}

class _AddEditEquipmentScreenState extends State<AddEditEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _departmentController = TextEditingController();
  final _statusController = TextEditingController();
  final _mfgController = TextEditingController();
  final _serialController = TextEditingController();
  final _costController = TextEditingController();

  // Equipment Group with Autocomplete
  final _groupController = TextEditingController();

  String _equipmentType = 'Non-Critical';
  String _equipmentMode = 'Portable';
  String _serviceStatus = 'Active';
  bool _hasWarranty = false;
  DateTime? _installationDate;
  DateTime? _warrantyUptoDate;

  List<String> _equipmentNames = [];
  List<String> _departmentSuggestions = [];
  List<String> _groupSuggestions = [];
  String? _selectedEquipment;
  College? _college;

  @override
  void initState() {
    super.initState();
    final collegeProvider = Provider.of<CollegeProvider>(context, listen: false);
    print('AddEditEquipmentScreen: Accessed CollegeProvider.');
    try {
      _college = collegeProvider.colleges.firstWhere((c) => c.name == widget.collegeName);
      print('AddEditEquipmentScreen: College found: ${_college!.name}, type: ${_college!.type}, seats: ${_college!.seats}');
      _loadEquipmentNames(_college!.type, _college!.seats);
    } catch (e) {
      print('AddEditEquipmentScreen: College not found for name: ${widget.collegeName}. Error: $e');
      _college = null; // Ensure _college is null if not found
    }

    if (widget.equipment != null) {
      print('AddEditEquipmentScreen: Editing existing equipment: ${widget.equipment!.name}');
      _selectedEquipment = widget.equipment!.name;
      _departmentController.text = widget.equipment!.department;
      _statusController.text = widget.equipment!.status;
      _groupController.text = widget.equipment!.group;
      _mfgController.text = widget.equipment!.manufacturer;
      _serialController.text = widget.equipment!.serialNo;
      _costController.text = widget.equipment!.purchasedCost.toString();
      _equipmentType = widget.equipment!.type;
      _equipmentMode = widget.equipment!.mode;
      _serviceStatus = widget.equipment!.service;
      _hasWarranty = widget.equipment!.hasWarranty;
      _installationDate = widget.equipment!.installationDate;
      _warrantyUptoDate = widget.equipment!.warrantyUpto;
    }
  }

  void _loadEquipmentNames(String collegeType, String seats) {
    print('AddEditEquipmentScreen: Attempting to load equipment for collegeType: "$collegeType", seats: "$seats"');
    
    // Normalize college type and seats to match keys in requirements data
    String normalizedCollegeType = '';
    final trimmedCollegeType = collegeType.trim().toUpperCase();
    if (trimmedCollegeType == 'DENTAL' || trimmedCollegeType == 'BDS') {
      normalizedCollegeType = 'BDS';
    } else if (trimmedCollegeType == 'MEDICAL' || trimmedCollegeType == 'MBBS') {
      normalizedCollegeType = 'MBBS';
    }

    final normalizedSeats = seats.trim();

    final Set<String> equipmentSet = {};
    if (requirements.containsKey(normalizedCollegeType)) {
      print('AddEditEquipmentScreen: requirements contains collegeType: "$normalizedCollegeType"');
      if (requirements[normalizedCollegeType]!.containsKey(normalizedSeats)) {
        print('AddEditEquipmentScreen: requirements["$normalizedCollegeType"] contains seats: "$normalizedSeats"');
        final seatData = requirements[normalizedCollegeType]![normalizedSeats]!;
        seatData.forEach((department, deptData) {
          if (deptData.containsKey('equipments')) {
            // Ensure 'equipments' is a Map<String, dynamic> before iterating
            if (deptData['equipments'] is Map<String, dynamic>) {
              (deptData['equipments'] as Map<String, dynamic>).forEach((equipment, count) {
                equipmentSet.add(equipment);
              });
            } else {
              print('AddEditEquipmentScreen: Warning: equipments for department "$department" is not a Map<String, dynamic>. Found type: ${deptData['equipments'].runtimeType}');
            }
          }
        });
      } else {
        print('AddEditEquipmentScreen: requirements["$normalizedCollegeType"] DOES NOT contain seats: "$normalizedSeats". Available seats keys: ${requirements[normalizedCollegeType]!.keys}');
      }
    } else {
      print('AddEditEquipmentScreen: requirements DOES NOT contain collegeType: "$normalizedCollegeType". Available collegeType keys: ${requirements.keys}');
    }
    setState(() {
      _equipmentNames = equipmentSet.toList();
      _equipmentNames.sort(); // Sort for consistent order
      print('AddEditEquipmentScreen: Final loaded equipment names (count: ${equipmentSet.length}): $_equipmentNames');
      if (_equipmentNames.isEmpty) {
        print('AddEditEquipmentScreen: Warning: _equipmentNames list is EMPTY. This might be why the dropdown is not visible or has no items.');
      }
    });
  }

  void _onEquipmentSelected(String selection) {
    _selectedEquipment = selection;
    final Set<String> departments = {};
    final Set<String> groups = {};
    if (_college != null) {
      // Normalize college type and seats to match keys in requirements data
      String normalizedCollegeType = '';
      final trimmedCollegeType = _college!.type.trim().toUpperCase();
      if (trimmedCollegeType == 'DENTAL' || trimmedCollegeType == 'BDS') {
        normalizedCollegeType = 'BDS';
      } else if (trimmedCollegeType == 'MEDICAL' || trimmedCollegeType == 'MBBS') {
        normalizedCollegeType = 'MBBS';
      }

      final normalizedSeats = _college!.seats.trim();
      
      if (requirements.containsKey(normalizedCollegeType) && requirements[normalizedCollegeType]!.containsKey(normalizedSeats)) {
        final seatData = requirements[normalizedCollegeType]![normalizedSeats]!;
        seatData.forEach((department, deptData) {
          if (deptData.containsKey('equipments')) {
            (deptData['equipments'] as Map<String, dynamic>).forEach((equipment, count) {
              if (equipment == selection) {
                departments.add(department);
                if (departmentGroup.containsKey(department)) {
                  groups.add(departmentGroup[department]!);
                }
              }
            });
          }
        });
      }
    }

    setState(() {
      _departmentSuggestions = departments.toList();
      _groupSuggestions = groups.toList();
      if (_departmentSuggestions.length == 1) {
        _departmentController.text = _departmentSuggestions.first;
      } else {
        _departmentController.clear();
      }
      if (_groupSuggestions.length == 1) {
        _groupController.text = _groupSuggestions.first;
      } else {
        _groupController.clear();
      }
    });
  }


  Future<void> _selectDate(BuildContext context, Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      String id = widget.equipment?.id ?? const Uuid().v4(); // Generate ID for new equipment
      String qrcode = widget.equipment?.qrcode ?? id; // For now, qrcode is same as id

      final newEquipment = Equipment(
        id: id,
        qrcode: qrcode,
        name: _selectedEquipment!,
        group: _groupController.text.trim(),
        manufacturer: _mfgController.text.trim(),
        type: _equipmentType,
        mode: _equipmentMode,
        serialNo: _serialController.text.trim(),
        department: _departmentController.text.trim(),
        installationDate: _installationDate ?? DateTime.now(), // Default to now if not set
        status: _statusController.text.trim(),
        service: _serviceStatus,
        purchasedCost: double.tryParse(_costController.text.trim()) ?? 0.0,
        hasWarranty: _hasWarranty,
        warrantyUpto: _hasWarranty ? _warrantyUptoDate : null,
        assignedEmployeeId: null, // This would be set if an employee is assigned
        customerReceived: null, // This would be set if a customer received it
        collegeId: _college!.id, // Assuming _college is not null at this point
      );

      Navigator.of(context).pop(newEquipment);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Equipment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedEquipment,
                decoration: const InputDecoration(labelText: 'Equipment Name*'),
                hint: const Text('Select Equipment'), // Added hint
                items: _equipmentNames.map((String equipmentName) {
                  return DropdownMenuItem<String>(
                    value: equipmentName,
                    child: Text(equipmentName),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedEquipment = newValue;
                    if (newValue != null) {
                      _onEquipmentSelected(newValue);
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an equipment name.';
                  }
                  return null;
                },
              ),
              if (_departmentSuggestions.length > 1)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Department*'),
                  value: _departmentController.text.isEmpty ? null : _departmentController.text,
                  items: _departmentSuggestions.map((String department) {
                    return DropdownMenuItem<String>(
                      value: department,
                      child: Text(department),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _departmentController.text = newValue!;
                    });
                  },
                  validator: (value) => value == null || value.isEmpty ? 'Please select a department' : null,
                )
              else
                TextFormField(
                  controller: _departmentController,
                  decoration: const InputDecoration(labelText: 'Department*'),
                  validator: (value) => value!.isEmpty ? 'Please enter a department' : null,
                ),
              TextFormField(
                controller: _statusController,
                decoration: const InputDecoration(labelText: 'Status*'),
                validator: (value) => value!.isEmpty ? 'Please enter a status' : null,
              ),
              const SizedBox(height: 16),
              if (_groupSuggestions.length > 1)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Equipment Group'),
                  value: _groupController.text.isEmpty ? null : _groupController.text,
                  items: _groupSuggestions.map((String group) {
                    return DropdownMenuItem<String>(
                      value: group,
                      child: Text(group),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _groupController.text = newValue!;
                    });
                  },
                  validator: (value) => value == null || value.isEmpty ? 'Please select a group' : null,
                )
              else
                TextFormField(
                  controller: _groupController,
                  decoration: const InputDecoration(labelText: 'Equipment Group'),
                  readOnly: true,
                ),
              TextFormField(controller: _mfgController, decoration: const InputDecoration(labelText: 'Manufacturer')),
              TextFormField(controller: _serialController, decoration: const InputDecoration(labelText: 'Serial No.')),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(labelText: 'Purchased Cost'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _equipmentType,
                decoration: const InputDecoration(labelText: 'Equipment Type'),
                items: ['Critical', 'Non-Critical'].map((label) => DropdownMenuItem(
                  value: label,
                  child: Text(label),
                )).toList(),
                onChanged: (value) => setState(() => _equipmentType = value!),
              ),
              DropdownButtonFormField<String>(
                value: _equipmentMode,
                decoration: const InputDecoration(labelText: 'Equipment Mode'),
                items: ['Mercury', 'Electrical', 'Portable', 'Hydrolic'].map((label) => DropdownMenuItem(
                  value: label,
                  child: Text(label),
                )).toList(),
                onChanged: (value) => setState(() => _equipmentMode = value!),
              ),
              DropdownButtonFormField<String>(
                value: _serviceStatus,
                decoration: const InputDecoration(labelText: 'Service Status'),
                items: ['Active', 'Non-Active'].map((label) => DropdownMenuItem(
                  value: label,
                  child: Text(label),
                )).toList(),
                onChanged: (value) => setState(() => _serviceStatus = value!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Installation Date: ${_installationDate == null ? 'Not Set' : DateFormat.yMd().format(_installationDate!)}',
                    ),
                  ),
                  TextButton(
                    child: const Text('Select Date'),
                    onPressed: () => _selectDate(context, (date) => setState(() => _installationDate = date)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Warranty', style: Theme.of(context).textTheme.titleMedium),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Yes'),
                      value: true,
                      groupValue: _hasWarranty,
                      onChanged: (value) => setState(() => _hasWarranty = value!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('No'),
                      value: false,
                      groupValue: _hasWarranty,
                      onChanged: (value) => setState(() => _hasWarranty = value!),
                    ),
                  ),
                ],
              ),
              if (_hasWarranty)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Warranty Upto: ${_warrantyUptoDate == null ? 'Not Set' : DateFormat.yMd().format(_warrantyUptoDate!)}',
                      ),
                    ),
                    TextButton(
                      child: const Text('Select Date'),
                      onPressed: () => _selectDate(context, (date) => setState(() => _warrantyUptoDate = date)),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              // Dropdown for assigned employee would go here
              // You would fetch employees for the college and display them
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Assign to Employee (Optional)'),
                items: const [], // Placeholder
                onChanged: (value) {},
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}