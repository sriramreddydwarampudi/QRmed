import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';
import 'package:supreme_institution/models/ticket.dart';
import 'package:supreme_institution/providers/ticket_provider.dart';
import 'package:supreme_institution/screens/add_edit_ticket_screen.dart';
import 'package:supreme_institution/screens/my_equipments_screen.dart';
import 'package:supreme_institution/widgets/dashboard_tile.dart';

class EmployeeHomeTab extends StatefulWidget {
  final String collegeName; // This seems to be collegeId based on previous context
  final String employeeId; // Renamed from employeeName

  const EmployeeHomeTab({
    super.key,
    required this.collegeName,
    required this.employeeId, // Renamed from employeeName
  });

  @override
  State<EmployeeHomeTab> createState() => _EmployeeHomeTabState();
}

class _EmployeeHomeTabState extends State<EmployeeHomeTab> {
  @override
  Widget build(BuildContext context) {
    final equipmentProvider = Provider.of<EquipmentProvider>(context);

    // Filtering data based on collegeId
    final collegeEquipments = equipmentProvider.equipments.where((e) => e.collegeId == widget.collegeName);
    final myEquipments = collegeEquipments.where((e) => e.assignedEmployeeId == widget.employeeId); // Use employeeId

    final notWorkingCount = myEquipments.where((e) => e.status != 'Working').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome, ${widget.employeeId}', style: Theme.of(context).textTheme.headlineSmall), // Use employeeId for welcome message
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              DashboardTile(
                count: collegeEquipments.length.toString(),
                title: 'Total College Equipments',
                icon: Icons.school,
                color: Colors.blue,
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => MyEquipmentsScreen(employeeId: widget.employeeId, collegeName: widget.collegeName),
                  ));
                },
                child: DashboardTile(
                  count: myEquipments.length.toString(),
                  title: 'My Equipments',
                  icon: Icons.person_pin_circle,
                  color: Colors.green,
                ),
              ),
              DashboardTile(
                count: notWorkingCount.toString(),
                title: 'My Equipments Not Working',
                icon: Icons.build,
                color: Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Raise Support Ticket', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final newTicket = await Navigator.of(context).push<Ticket>(
                MaterialPageRoute(
                  builder: (context) => const AddEditTicketScreen(),
                ),
              );
              if (newTicket != null) {
                final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
                final ticket = Ticket(
                  id: DateTime.now().toString(),
                  title: newTicket.title,
                  description: newTicket.description,
                  status: newTicket.status,
                  raisedBy: widget.employeeId, // Use employeeId for raisedBy
                  raisedTo: widget.collegeName,
                  timestamp: DateTime.now(),
                );
                ticketProvider.addTicket(ticket);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ticket raised successfully.')),
                );
              }
            },
            icon: const Icon(Icons.confirmation_number),
            label: const Text('Raise a Ticket'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}