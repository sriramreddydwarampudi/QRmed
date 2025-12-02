class Employee {
  String id; // employeename@collegename.com
  String name;
  String password;
  String collegeId;
  String? role;
  String? department;
  String? email;
  String? phone;
  List<String> assignedEquipments; // New field

  Employee({
    required this.id,
    required this.name,
    required this.password,
    required this.collegeId,
    this.role,
    this.department,
    this.email,
    this.phone,
    this.assignedEquipments = const [], // Initialize as empty list
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      name: json['name'] as String,
      password: json['password'] as String,
      collegeId: json['collegeId'] as String,
      role: json['role'] as String?,
      department: json['department'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      assignedEquipments: List<String>.from(json['assignedEquipments'] ?? []), // Deserialize
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'password': password,
      'collegeId': collegeId,
      'role': role,
      'department': department,
      'email': email,
      'phone': phone,
      'assignedEquipments': assignedEquipments, // Serialize
    };
  }
}
