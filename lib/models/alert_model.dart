import 'package:cloud_firestore/cloud_firestore.dart';

class AlertModel {
  final String id;
  final String type; // Mass Casualty, Equipment Failure, Staff Emergency, Patient Code Red
  final String severity; // CRITICAL, URGENT, STABLE
  final String target; // All Staff, Doctors Only, Nurses Only
  final String message;
  final DateTime createdAt;
  final String status; // Active, Acknowledged
  final String? assignedTo;
  final String? assignedToName;
  final String? assignedToRole;

  AlertModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.target,
    required this.message,
    required this.createdAt,
    required this.status,
    this.assignedTo,
    this.assignedToName,
    this.assignedToRole,
  });

  factory AlertModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return AlertModel(
      id: docId ?? map['id'] as String? ?? '',
      type: map['type'] as String? ?? 'General',
      severity: map['severity'] as String? ?? 'STABLE',
      target: map['target'] as String? ?? 'All Staff',
      message: map['message'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] as String? ?? 'Active',
      assignedTo: map['assignedTo'] as String?,
      assignedToName: map['assignedToName'] as String?,
      assignedToRole: map['assignedToRole'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'severity': severity,
      'target': target,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'assignedToRole': assignedToRole,
    };
  }

  AlertModel copyWith({
    String? id,
    String? type,
    String? severity,
    String? target,
    String? message,
    DateTime? createdAt,
    String? status,
    String? assignedTo,
    String? assignedToName,
    String? assignedToRole,
  }) {
    return AlertModel(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      target: target ?? this.target,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedToRole: assignedToRole ?? this.assignedToRole,
    );
  }
}
