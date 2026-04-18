class AlertModel {
  final String id;
  final String type; // Mass Casualty, Equipment Failure, Staff Emergency, Patient Code Red
  final String severity; // CRITICAL, URGENT, STABLE
  final String target; // All Staff, Doctors Only, Nurses Only
  final String message;
  final DateTime createdAt;
  final String status; // Active, Acknowledged
  final String? assignedTo;

  AlertModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.target,
    required this.message,
    required this.createdAt,
    required this.status,
    this.assignedTo,
  });

  AlertModel copyWith({
    String? id,
    String? type,
    String? severity,
    String? target,
    String? message,
    DateTime? createdAt,
    String? status,
    String? assignedTo,
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
    );
  }
}
