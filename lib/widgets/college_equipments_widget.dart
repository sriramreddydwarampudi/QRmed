import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';

class CollegeEquipmentsWidget extends StatelessWidget {
  final String collegeName;

  const CollegeEquipmentsWidget({super.key, required this.collegeName});

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = Provider.of<EquipmentProvider>(context);
    final collegeEquipments = equipmentProvider.equipments
        .where((e) => e.collegeId == collegeName)
        .toList();

    if (collegeEquipments.isEmpty) {
      return const Center(child: Text('No equipments found for this college.'));
    }

    return ListView.builder(
      itemCount: collegeEquipments.length,
      itemBuilder: (context, idx) {
        final equipment = collegeEquipments[idx];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(equipment.name),
            subtitle: Text('Status: ${equipment.status} • Department: ${equipment.department}'),
            trailing: IconButton(
              icon: const Icon(Icons.remove_red_eye),
              tooltip: 'View Details',
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
                          if (equipment.assignedEmployeeId != null)
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
          ),
        );
      },
    );
  }
}
