import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supreme_institution/models/equipment.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';
import 'package:supreme_institution/providers/college_provider.dart';
import 'package:supreme_institution/widgets/management_list_widget.dart';
import 'package:supreme_institution/widgets/modern_details_dialog.dart';

class AdminEquipmentsNotWorkingScreen extends StatefulWidget {
  const AdminEquipmentsNotWorkingScreen({super.key});

  @override
  State<AdminEquipmentsNotWorkingScreen> createState() => _AdminEquipmentsNotWorkingScreenState();
}

class _AdminEquipmentsNotWorkingScreenState extends State<AdminEquipmentsNotWorkingScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch latest equipment data when screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EquipmentProvider>(context, listen: false).fetchEquipments();
    });
  }

  void _showEquipmentDetails(Equipment equipment, BuildContext context) {
    final collegeProvider = Provider.of<CollegeProvider>(context, listen: false);
    String collegeName = equipment.collegeId;
    try {
      final college = collegeProvider.colleges.firstWhere(
        (c) => c.id == equipment.collegeId,
      );
      collegeName = college.name;
    } catch (e) {
      // If college not found, use collegeId as fallback
    }

    showDialog(
      context: context,
      builder: (ctx) => ModernDetailsDialog(
        title: 'Equipment Details',
        details: [
          DetailRow(label: 'ID', value: equipment.id),
          DetailRow(label: 'Name', value: equipment.name),
          DetailRow(label: 'College', value: collegeName),
          DetailRow(label: 'Type', value: equipment.type),
          DetailRow(label: 'Group', value: equipment.group),
          DetailRow(label: 'Mode', value: equipment.mode),
          DetailRow(label: 'Manufacturer', value: equipment.manufacturer),
          DetailRow(label: 'Serial Number', value: equipment.serialNo),
          DetailRow(label: 'Department', value: equipment.department),
          DetailRow(label: 'Status', value: equipment.status),
          DetailRow(label: 'Service Status', value: equipment.service),
          DetailRow(
            label: 'Warranty Upto',
            value: equipment.warrantyUpto != null
                ? DateFormat('yyyy-MM-dd').format(equipment.warrantyUpto!)
                : '-',
          ),
          DetailRow(
            label: 'Purchased Cost',
            value: '₹${equipment.purchasedCost.toString()}',
          ),
          DetailRow(
            label: 'Installation Date',
            value: DateFormat('yyyy-MM-dd').format(equipment.installationDate),
          ),
          DetailRow(
            label: 'Employee Assigned',
            value: equipment.assignedEmployeeId ?? '-',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = Provider.of<EquipmentProvider>(context);
    
    // Use the helper method for consistent filtering
    final notWorkingEquipments = equipmentProvider.equipments
        .where((e) {
          final isNotWorking = e.isNotWorking;
          
          // Debug logging to help diagnose issues
          if (isNotWorking) {
            debugPrint('🔍 [AdminEquipmentsNotWorking] Found non-working: ${e.name} (ID: ${e.id}) - Status: "${e.status.trim()}"');
          }
          
          return isNotWorking;
        })
        .toList();
    
    debugPrint('📊 [AdminEquipmentsNotWorking] Total equipments: ${equipmentProvider.equipments.length}');
    debugPrint('📊 [AdminEquipmentsNotWorking] Not working count: ${notWorkingEquipments.length}');
    
    // Log all status values for debugging
    final allStatuses = equipmentProvider.equipments.map((e) => e.status.trim()).toSet();
    debugPrint('📊 [AdminEquipmentsNotWorking] All unique statuses: $allStatuses');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipments Not Working'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () async {
              await Provider.of<EquipmentProvider>(context, listen: false).fetchEquipments();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data refreshed'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<EquipmentProvider>(context, listen: false).fetchEquipments();
        },
        child: ManagementListWidget(
          items: notWorkingEquipments.map((equipment) {
          return ManagementListItem(
            id: equipment.id,
            title: equipment.name,
            subtitle: '${equipment.serialNo} • ${equipment.department}',
            icon: Icons.devices_other,
            iconColor: const Color(0xFFDC2626),
            badge: equipment.status,
            badgeColor: equipment.status == 'Under Maintenance'
                ? Colors.orange
                : Colors.red,
            actions: [
              ManagementAction(
                label: 'View',
                icon: Icons.remove_red_eye,
                color: const Color(0xFF2563EB),
                onPressed: () => _showEquipmentDetails(equipment, context),
              ),
            ],
          );
        }).toList(),
          emptyMessage: 'No non-working equipments found.',
        ),
      ),
    );
  }
}

