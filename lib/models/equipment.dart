import 'package:cloud_firestore/cloud_firestore.dart';

class Equipment {
  String id;
  String qrcode;
  String name;
  String group;
  String manufacturer;
  String type; // critical, non-critical
  String mode; // mercury, electrical, portable, hydrolic
  String serialNo;
  String department;
  DateTime installationDate;
  String status;
  String service; // active, non-active
  double purchasedCost;
  bool hasWarranty;
  DateTime? warrantyUpto;
  String? assignedEmployeeId;
  String? customerReceived;
  String collegeId;

  Equipment({
    required this.id,
    required this.qrcode,
    required this.name,
    required this.group,
    required this.manufacturer,
    required this.type,
    required this.mode,
    required this.serialNo,
    required this.department,
    required this.installationDate,
    required this.status,
    required this.service,
    required this.purchasedCost,
    required this.hasWarranty,
    this.warrantyUpto,
    this.assignedEmployeeId,
    this.customerReceived,
    required this.collegeId,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] as String,
      qrcode: json['qrcode'] as String,
      name: json['name'] as String,
      group: json['group'] as String,
      manufacturer: json['manufacturer'] as String,
      type: json['type'] as String,
      mode: json['mode'] as String,
      serialNo: json['serialNo'] as String,
      department: json['department'] as String,
      installationDate: (json['installationDate'] as Timestamp).toDate(),
      status: json['status'] as String,
      service: json['service'] as String,
      purchasedCost: (json['purchasedCost'] as num).toDouble(),
      hasWarranty: json['hasWarranty'] as bool,
      warrantyUpto: json['warrantyUpto'] != null
          ? (json['warrantyUpto'] as Timestamp).toDate()
          : null,
      assignedEmployeeId: json['assignedEmployeeId'] as String?,
      customerReceived: json['customerReceived'] as String?,
      collegeId: json['collegeId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'qrcode': qrcode,
      'name': name,
      'group': group,
      'manufacturer': manufacturer,
      'type': type,
      'mode': mode,
      'serialNo': serialNo,
      'department': department,
      'installationDate': Timestamp.fromDate(installationDate),
      'status': status,
      'service': service,
      'purchasedCost': purchasedCost,
      'hasWarranty': hasWarranty,
      'warrantyUpto': warrantyUpto != null ? Timestamp.fromDate(warrantyUpto!) : null,
      'assignedEmployeeId': assignedEmployeeId,
      'customerReceived': customerReceived,
      'collegeId': collegeId,
    };
  }
}