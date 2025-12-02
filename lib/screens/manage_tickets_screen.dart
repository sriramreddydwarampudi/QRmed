import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/ticket.dart';
import 'package:supreme_institution/providers/ticket_provider.dart';
import 'package:supreme_institution/screens/add_edit_ticket_screen.dart';

enum TicketView {
  raisedByMe,
  assignedToMe,
}

class ManageTicketsScreen extends StatefulWidget {
  final String userId;
  final String userRole; // 'admin', 'college', 'employee', 'customer'
  final String collegeId;

  const ManageTicketsScreen({
    super.key,
    required this.userId,
    required this.userRole,
    required this.collegeId,
  });

  @override
  _ManageTicketsScreenState createState() => _ManageTicketsScreenState();
}

class _ManageTicketsScreenState extends State<ManageTicketsScreen> {
  TicketView _ticketView = TicketView.assignedToMe;

  @override
  Widget build(BuildContext context) {
    final ticketProvider = Provider.of<TicketProvider>(context);
    List<Ticket> tickets;

    if (widget.userRole == 'admin') {
      tickets = ticketProvider.getTicketsForAdmin();
    } else if (widget.userRole == 'college') {
      if (_ticketView == TicketView.assignedToMe) {
        tickets = ticketProvider.getTicketsForCollege(widget.collegeId);
      } else {
        tickets = ticketProvider.getTicketsForUser(widget.collegeId);
      }
    } else {
      tickets = ticketProvider.getTicketsForUser(widget.userId);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tickets'),
        actions: [
          if (widget.userRole == 'college')
            ToggleButtons(
              isSelected: [_ticketView == TicketView.assignedToMe, _ticketView == TicketView.raisedByMe],
              onPressed: (index) {
                setState(() {
                  _ticketView = index == 0 ? TicketView.assignedToMe : TicketView.raisedByMe;
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('Assigned to Me'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('Raised by Me'),
                ),
              ],
            ),
        ],
      ),
      body: tickets.isEmpty
          ? const Center(child: Text('No tickets found.'))
          : ListView.builder(
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(ticket.title ?? 'No Title'),
                    subtitle: Text(
                      'Status: ${ticket.status.toString().split('.').last ?? 'Unknown'}\n' 
                      'Raised by: ${ticket.raisedBy ?? 'Unknown'}\n' 
                      'Date: ${ticket.timestamp.toLocal().toString().split(' ')[0]}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final updatedTicket = await Navigator.of(context).push<Ticket>(
                              MaterialPageRoute(
                                builder: (context) => AddEditTicketScreen(ticket: ticket),
                              ),
                            );
                            if (updatedTicket != null) {
                              ticketProvider.updateTicket(ticket.id, updatedTicket);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            ticketProvider.deleteTicket(ticket.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTicket = await Navigator.of(context).push<Ticket>(
            MaterialPageRoute(
              builder: (context) => const AddEditTicketScreen(),
            ),
          );
          if (newTicket != null) {
            final ticket = Ticket(
              id: DateTime.now().toString(),
              title: newTicket.title,
              description: newTicket.description,
              status: newTicket.status,
              raisedBy: widget.userId,
              raisedTo: widget.userRole == 'college' ? 'admin' : widget.collegeId,
              timestamp: DateTime.now(),
            );
            ticketProvider.addTicket(ticket);
          }
        },
        tooltip: 'Add Ticket',
        child: const Icon(Icons.add),
      ),
    );
  }
}
