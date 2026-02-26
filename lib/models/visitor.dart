class Visitor {
  String id; // visitorname@collegename.com
  String name;
  String password;
  String collegeId;
  String? email;
  String? phone;

  Visitor({
    required this.id,
    required this.name,
    required this.password,
    required this.collegeId,
    this.email,
    this.phone,
  });

  factory Visitor.fromJson(Map<String, dynamic> json) {
    return Visitor(
      id: json['id'] as String,
      name: json['name'] as String,
      password: json['password'] as String,
      collegeId: json['collegeId'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'password': password,
      'collegeId': collegeId,
      'email': email,
      'phone': phone,
    };
  }
}
