import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supreme_institution/models/equipment.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';
import 'package:supreme_institution/providers/notification_provider.dart';
import '../widgets/management_list_widget.dart';
import '../widgets/modern_details_dialog.dart';

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
        elevation: 0,
      ),
      body: ManagementListWidget(
        items: myEquipments.map((equipment) => ManagementListItem(
          id: equipment.id,
          title: equipment.name,
          subtitle: equipment.department,
          icon: Icons.devices_other,
          iconColor: const Color(0xFF2563EB),
          badge: equipment.status,
          badgeColor: equipment.status == 'Working' ? Colors.green : Colors.red,
          actions: [
            ManagementAction(
              label: 'View',
              icon: Icons.remove_red_eye,
              color: const Color(0xFF2563EB),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => ModernDetailsDialog(
                    title: 'Equipment Details',
                    details: [
                      DetailRow(label: 'Name', value: equipment.name),
                      DetailRow(label: 'ID', value: equipment.id),
                      DetailRow(label: 'Status', value: equipment.status),
                      DetailRow(label: 'Department', value: equipment.department),
                      DetailRow(label: 'Group', value: equipment.group),
                      DetailRow(label: 'Manufacturer', value: equipment.manufacturer),
                      DetailRow(label: 'Type', value: equipment.type),
                      DetailRow(label: 'Mode', value: equipment.mode),
                      DetailRow(label: 'Serial Number', value: equipment.serialNo),
                      DetailRow(label: 'Service', value: equipment.service),
                      DetailRow(label: 'Purchased Cost', value: '₹${equipment.purchasedCost}'),
                      DetailRow(
                        label: 'Installation Date',
                        value: DateFormat.yMd().format(equipment.installationDate),
                      ),
                      if (equipment.hasWarranty && equipment.warrantyUpto != null)
                        DetailRow(
                          label: 'Warranty Upto',
                          value: DateFormat.yMd().format(equipment.warrantyUpto!),
                        ),
                      DetailRow(label: 'College ID', value: equipment.collegeId),
                    ],
                    qrCodeWidget: QrImageView(
                      data: equipment.id,
                      version: QrVersions.auto,
                      size: 150,
                      backgroundColor: Colors.white,
                    ),
                  ),
                );
              },
            ),
            ManagementAction(
              label: 'Toggle',
              icon: equipment.status == 'Working' ? Icons.check_circle : Icons.error_outline,
              color: equipment.status == 'Working' ? Colors.green : Colors.red,
              onPressed: () {
                final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
                final newStatus = equipment.status == 'Working' ? 'Not Working' : 'Working';
                final updatedEquipment = equipment.copyWith(status: newStatus);
                equipmentProvider.updateEquipment(
                  equipment.id, 
                  updatedEquipment,
                  notificationProvider: notificationProvider,
                  updatedByRole: 'employee',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Status changed to $newStatus')),
                );
              },
            ),
            ManagementAction(
              label: 'Unassign',
              icon: Icons.person_remove,
              color: const Color(0xFFDC2626),
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
        )).toList(),
        emptyMessage: 'You have no equipment assigned.',
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
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Select Equipment'),
                        initialValue: selectedEquipment,
                        selectedItemBuilder: (BuildContext context) {
                          return unassignedEquipments.map((equipment) {
                            return Text(
                              '${equipment.name} (ID: ${equipment.id})',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            );
                          }).toList();
                        },
                        items: unassignedEquipments.map((equipment) {
                          return DropdownMenuItem<Equipment>(
                            value: equipment,
                            child: Text(
                              '${equipment.name} (ID: ${equipment.id})',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedEquipment = value;
                          });
                        },
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