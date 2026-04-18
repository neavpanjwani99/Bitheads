class StaffModel {
  final String uid;
  final String name;
  final String role; // Admin, Doctor, Nurse
  final String specialization;
  final bool available;
  final int averageResponseTimeSecs;
  final int patientCount;

  StaffModel({
    required this.uid,
    required this.name,
    required this.role,
    required this.specialization,
    required this.available,
    this.averageResponseTimeSecs = 120,
    this.patientCount = 0,
  });

  StaffModel copyWith({
    String? uid,
    String? name,
    String? role,
    String? specialization,
    bool? available,
    int? averageResponseTimeSecs,
    int? patientCount,
  }) {
    return StaffModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      role: role ?? this.role,
      specialization: specialization ?? this.specialization,
      available: available ?? this.available,
      averageResponseTimeSecs: averageResponseTimeSecs ?? this.averageResponseTimeSecs,
      patientCount: patientCount ?? this.patientCount,
    );
  }
}
