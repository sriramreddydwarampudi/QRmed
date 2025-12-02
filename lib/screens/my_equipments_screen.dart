import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/equipment.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';

class MyEquipmentsScreen extends StatefulWidget {
  final String employeeId;
  final String collegeName;

  const MyEquipmentsScreen({
    super.key,
    required this.employeeId,
    required this.collegeName,
  });

  @override
  State<MyEquipmentsScreen> createState() => _MyEquipmentsScreenState();
}

class _MyEquipmentsScreenState extends State<MyEquipmentsScreen> {
  @override
  Widget build(BuildContext context) {
    final equipmentProvider = Provider.of<EquipmentProvider>(context);
    final allCollegeEquipments = equipmentProvider.equipments.where((e) => e.collegeId == widget.collegeName).toList();
    final myEquipments = allCollegeEquipments.where((e) => e.assignedEmployeeId == widget.employeeId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Assigned Equipments'),
      ),
      body: myEquipments.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('You have no equipment assigned.'),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: myEquipments.length,
              itemBuilder: (context, index) {
                final equipment = myEquipments[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(equipment.name, style: Theme.of(context).textTheme.titleMedium),
                        Text('ID: ${equipment.id}'),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Status:'),
                            Row(
                              children: [
                                Text(equipment.status == 'Working' ? 'Working' : 'Not Working', style: TextStyle(color: equipment.status == 'Working' ? Colors.green : Colors.red)),
                                Switch(
                                  value: equipment.status == 'Working',
                                  onChanged: (bool value) {
                                    final newStatus = value ? 'Working' : 'Not Working';
                                    final updatedEquipment = equipment.copyWith(status: newStatus);
                                    equipmentProvider.updateEquipment(equipment.id, updatedEquipment);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              tooltip: 'View',
                              onPressed: () {
                                // Placeholder for view dialog
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Edit',
                              onPressed: () {
                                // Placeholder for edit dialog
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.person_remove),
                              tooltip: 'Unassign',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Confirm Unassignment'),
                                    content: const Text('Are you sure you want to unassign this equipment from yourself?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Unassign')),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final updatedEquipment = equipment.copyWith(assignedEmployeeId: '');
                                  await equipmentProvider.updateEquipment(equipment.id, updatedEquipment);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Equipment unassigned.')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEquipmentDialog(context, allCollegeEquipments),
        tooltip: 'Add Equipment from College',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEquipmentDialog(BuildContext context, List<Equipment> allCollegeEquipments) {
    final unassignedEquipments = allCollegeEquipments.where((e) => e.assignedEmployeeId == null || e.assignedEmployeeId!.isEmpty).toList();
    Equipment? selectedEquipment;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Assign Equipment to Yourself'),
              content: SizedBox(
                width: double.maxFinite,
                child: unassignedEquipments.isEmpty
                    ? const Text('No unassigned equipment available in your college.')
                    : DropdownButtonFormField<Equipment>(
                        decoration: const InputDecoration(labelText: 'Select Equipment'),
                        initialValue: selectedEquipment,
                        items: unassignedEquipments.map((equipment) {
                          return DropdownMenuItem<Equipment>(
                            value: equipment,
                            child: Text('${equipment.name} (ID: ${equipment.id})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedEquipment = value;
                          });
                        },
                        isExpanded: true,
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedEquipment == null ? null : () async {
                    final equipmentToAssign = selectedEquipment!;
                    final updatedEquipment = equipmentToAssign.copyWith(assignedEmployeeId: widget.employeeId);
                    
                    await Provider.of<EquipmentProvider>(context, listen: false)
                        .updateEquipment(equipmentToAssign.id, updatedEquipment);

                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Equipment assigned successfully.')),
                    );
                  },
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

extension EquipmentCopyWith on Equipment {
  Equipment copyWith({
    String? id,
    String? qrcode,
    String? name,
    String? type,
    String? group,
    String? mode,
    String? manufacturer,
    String? serialNo,
    String? department,
    String? status,
    String? service,
    DateTime? warrantyUpto,
    double? purchasedCost,
    DateTime? installationDate,
    String? assignedEmployeeId,
    bool? hasWarranty,
    String? collegeId,
  }) {
    return Equipment(
      id: id ?? this.id,
      qrcode: qrcode ?? this.qrcode,
      name: name ?? this.name,
      type: type ?? this.type,
      group: group ?? this.group,
      mode: mode ?? this.mode,
      manufacturer: manufacturer ?? this.manufacturer,
      serialNo: serialNo ?? this.serialNo,
      department: department ?? this.department,
      status: status ?? this.status,
      service: service ?? this.service,
      warrantyUpto: warrantyUpto ?? this.warrantyUpto,
      purchasedCost: purchasedCost ?? this.purchasedCost,
      installationDate: installationDate ?? this.installationDate,
      assignedEmployeeId: assignedEmployeeId ?? this.assignedEmployeeId,
      hasWarranty: hasWarranty ?? this.hasWarranty,
      collegeId: collegeId ?? this.collegeId,
    );
  }
}