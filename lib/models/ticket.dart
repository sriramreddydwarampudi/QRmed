enum TicketStatus {
  open,
  inProgress,
  closed,
}

class Ticket {
  final String id;
  final String title;
  final String description;
  final TicketStatus status;
  final String raisedBy; // Can be employeeId, customerId, or collegeId
  final String raisedTo; // Can be collegeId or 'admin'
  final DateTime timestamp;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    this.status = TicketStatus.open,
    required this.raisedBy,
    required this.raisedTo,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.toString(),
      'raisedBy': raisedBy,
      'raisedTo': raisedTo,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      status: TicketStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => TicketStatus.open,
      ),
      raisedBy: map['raisedBy'],
      raisedTo: map['raisedTo'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
