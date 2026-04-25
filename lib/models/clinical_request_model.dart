import 'package:cloud_firestore/cloud_firestore.dart';

class ClinicalRequestModel {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String type; // 'ORDER' or 'CONCERN'
  final String description;
  final String status; // 'PENDING' or 'COMPLETED'
  final String priority; // 'NORMAL' or 'URGENT'
  final DateTime createdAt;

  ClinicalRequestModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.type,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'type': type,
      'description': description,
      'status': status,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ClinicalRequestModel.fromMap(Map<String, dynamic> map, String docId) {
    return ClinicalRequestModel(
      id: docId,
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      type: map['type'] ?? 'ORDER',
      description: map['description'] ?? '',
      status: map['status'] ?? 'PENDING',
      priority: map['priority'] ?? 'NORMAL',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
