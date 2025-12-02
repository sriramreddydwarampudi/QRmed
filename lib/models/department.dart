class Department {
  final String id;
  final String name;
  final String collegeId;

  Department({
    required this.id,
    required this.name,
    required this.collegeId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'collegeId': collegeId,
    };
  }

  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      collegeId: map['collegeId'] ?? '',
    );
  }
}
