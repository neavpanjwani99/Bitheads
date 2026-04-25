class BedModel {
  final String id;
  final String type; // ICU, General, Emergency
  final String status; // Available, Occupied, Maintenance
  final String? patientId;
  final String? patientName;

  BedModel({
    required this.id,
    required this.type,
    required this.status,
    this.patientId,
    this.patientName,
  });

  factory BedModel.fromMap(Map<String, dynamic> map, String id) {
    return BedModel(
      id: id,
      type: map['type'] as String? ?? 'General',
      status: map['status'] as String? ?? 'Available',
      patientId: map['patientId'] as String?,
      patientName: map['patientName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'status': status,
      'patientId': patientId,
      'patientName': patientName,
    };
  }

  BedModel copyWith({
    String? id,
    String? type,
    String? status,
    String? patientId,
    String? patientName,
  }) {
    return BedModel(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
    );
  }
}
