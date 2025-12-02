import 'package:flutter/material.dart';
import 'package:supreme_institution/models/ticket.dart';

class TicketProvider with ChangeNotifier {
  final List<Ticket> _tickets = [
    // Dummy data for testing
    Ticket(
      id: 't1',
      title: 'Broken Equipment',
      description: 'The X-Ray machine in room 204 is not working.',
      raisedBy: 'employee1',
      raisedTo: 'c1',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Ticket(
      id: 't2',
      title: 'Login Issues',
      description: 'I am unable to log in to the student portal.',
      raisedBy: 'customer1',
      raisedTo: 'c1',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      status: TicketStatus.inProgress,
    ),
    Ticket(
      id: 't3',
      title: 'Request for new software',
      description: 'We need a new patient management software.',
      raisedBy: 'c1',
      raisedTo: 'admin',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      status: TicketStatus.closed,
    ),
  ];

  List<Ticket> get tickets => _tickets;

  List<Ticket> getTicketsForUser(String userId) {
    return _tickets.where((ticket) => ticket.raisedBy == userId).toList();
  }

  List<Ticket> getTicketsForCollege(String collegeId) {
    return _tickets.where((ticket) => ticket.raisedTo == collegeId).toList();
  }

  List<Ticket> getTicketsForAdmin() {
    return _tickets.where((ticket) => ticket.raisedTo == 'admin').toList();
  }

  void addTicket(Ticket ticket) {
    _tickets.add(ticket);
    notifyListeners();
  }

  void updateTicket(String id, Ticket newTicket) {
    final ticketIndex = _tickets.indexWhere((ticket) => ticket.id == id);
    if (ticketIndex >= 0) {
      _tickets[ticketIndex] = newTicket;
      notifyListeners();
    }
  }

  void deleteTicket(String id) {
    _tickets.removeWhere((ticket) => ticket.id == id);
    notifyListeners();
  }
}
