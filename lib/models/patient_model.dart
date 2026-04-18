class PatientModel {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String triageLevel; // CRITICAL, URGENT, STABLE, UNASSIGNED
  final String vitalsSummary;
  final String? assignedBedId;
  final String? assignedStaffId;

  PatientModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.triageLevel,
    required this.vitalsSummary,
    this.assignedBedId,
    this.assignedStaffId,
  });

  PatientModel copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? triageLevel,
    String? vitalsSummary,
    String? assignedBedId,
    String? assignedStaffId,
  }) {
    return PatientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      triageLevel: triageLevel ?? this.triageLevel,
      vitalsSummary: vitalsSummary ?? this.vitalsSummary,
      assignedBedId: assignedBedId ?? this.assignedBedId,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
    );
  }
}
