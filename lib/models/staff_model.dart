import 'dart:math';

class StaffModel {
  final String uid;
  final String hospitalId; // auto-generated
  final String email;
  final String name;
  final String role;
  final String specialization;
  final bool available;
  final int averageResponseTimeSecs;
  final int patientCount;

  StaffModel({
    required this.uid,
    String? hospitalId,
    required this.email,
    required this.name,
    required this.role,
    required this.specialization,
    this.available = true,
    this.averageResponseTimeSecs = 120,
    this.patientCount = 0,
  }) : hospitalId = hospitalId ?? generateHospitalId(role);

  factory StaffModel.fromMap(Map<String, dynamic> map, String uid) {
    return StaffModel(
      uid: uid,
      hospitalId: map['hospitalId'] as String?,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown',
      role: map['role'] as String? ?? 'Nurse',
      specialization: map['specialization'] as String? ?? 'General',
      available: map['available'] as bool? ?? true,
      averageResponseTimeSecs: map['averageResponseTimeSecs'] as int? ?? 120,
      patientCount: map['patientCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hospitalId': hospitalId,
      'email': email,
      'name': name,
      'role': role,
      'specialization': specialization,
      'available': available,
      'averageResponseTimeSecs': averageResponseTimeSecs,
      'patientCount': patientCount,
    };
  }

  static String generateHospitalId(String role) {
    final random = Random();
    final number = 1000 + random.nextInt(8999);
    final roleCode = role == 'Admin' ? 'ADM'
                   : role == 'Doctor' ? 'DOC'
                   : 'NRS';
    return 'HOSP-$roleCode-$number';
  }

  StaffModel copyWith({
    bool? available,
    int? averageResponseTimeSecs,
    int? patientCount,
  }) {
    return StaffModel(
      uid: uid,
      hospitalId: hospitalId, // Persist generated ID
      email: email,
      name: name,
      role: role,
      specialization: specialization,
      available: available ?? this.available,
      averageResponseTimeSecs: averageResponseTimeSecs ?? this.averageResponseTimeSecs,
      patientCount: patientCount ?? this.patientCount,
    );
  }
}
