import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';
import '../widgets/management_list_widget.dart';

class CollegeEquipmentsWidget extends StatelessWidget {
  final String collegeName;

  const CollegeEquipmentsWidget({super.key, required this.collegeName});

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = Provider.of<EquipmentProvider>(context);
    final collegeEquipments = equipmentProvider.equipments
        .where((e) => e.collegeId == collegeName)
        .toList();
    
    debugPrint('🔍 [CollegeEquipmentsWidget] College ID: $collegeName');
    debugPrint('🔍 [CollegeEquipmentsWidget] Total Equipments in Provider: ${equipmentProvider.equipments.length}');
    debugPrint('🔍 [CollegeEquipmentsWidget] Filtered College Equipments: ${collegeEquipments.length}');
    if (collegeEquipments.isNotEmpty) {
      debugPrint('🔍 [CollegeEquipmentsWidget] First Equipment: ${collegeEquipments.first.name}');
    }

    return ManagementListWidget(
      items: collegeEquipments.map((equipment) {
        final isNotWorking = equipment.status != 'Working';
        return ManagementListItem(
          id: equipment.id,
          title: equipment.name,
          subtitle: '${equipment.serialNo} • ${equipment.department}',
          icon: Icons.devices_other,
          iconColor: isNotWorking ? Colors.red : const Color(0xFF2563EB),
          badge: equipment.status,
          badgeColor: equipment.status == 'Working' ? Colors.green : (equipment.status == 'Under Maintenance' ? Colors.orange : Colors.red),
        actions: [
          ManagementAction(
            label: 'View',
            icon: Icons.remove_red_eye,
            color: const Color(0xFF2563EB),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(equipment.name),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('ID: ${equipment.id}'),
                        Text('QR Code: ${equipment.qrcode}'),
                        Text('Group: ${equipment.group}'),
                        Text('Manufacturer: ${equipment.manufacturer}'),
                        Text('Type: ${equipment.type}'),
                        Text('Mode: ${equipment.mode}'),
                        Text('Serial No: ${equipment.serialNo}'),
                        Text('Department: ${equipment.department}'),
                        Text('Status: ${equipment.status}'),
                        Text('Service: ${equipment.service}'),
                        Text('Purchased Cost: ${equipment.purchasedCost}'),
                        Text('Has Warranty: ${equipment.hasWarranty}'),
                        if (equipment.warrantyUpto != null)
                          Text('Warranty Upto: ${equipment.warrantyUpto}'),
                        if (equipment.assignedEmployeeId != null && equipment.assignedEmployeeId!.isNotEmpty)
                          Text('Assigned To: ${equipment.assignedEmployeeId}'),
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
        ],
        );
      }).toList(),
      emptyMessage: 'No equipments found for this college.',
    );
  }
}
