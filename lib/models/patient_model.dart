class PatientModel {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String triageLevel; // CRITICAL, URGENT, STABLE, UNASSIGNED
  final String vitalsSummary;
  final String? assignedBedId;
  final String? assignedStaffId;
  final DateTime? lastVitalsTime;
  final String vitalStatus;

  PatientModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.triageLevel,
    required this.vitalsSummary,
    this.assignedBedId,
    this.assignedStaffId,
    this.lastVitalsTime,
    this.vitalStatus = 'normal',
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
    DateTime? lastVitalsTime,
    String? vitalStatus,
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
      lastVitalsTime: lastVitalsTime ?? this.lastVitalsTime,
      vitalStatus: vitalStatus ?? this.vitalStatus,
    );
  }

  int get riskScore {
    int score = 0;
    
    if (triageLevel == 'CRITICAL') score += 40;
    if (triageLevel == 'URGENT') score += 25;
    if (triageLevel == 'STABLE') score += 5;
    
    if (age > 70) score += 20;
    else if (age > 50) score += 10;
    else if (age < 5) score += 15;
    
    if (lastVitalsTime != null) {
      int minsSinceCheck = DateTime.now().difference(lastVitalsTime!).inMinutes;
      if (minsSinceCheck > 60) score += 20;
      else if (minsSinceCheck > 30) score += 10;
    } else {
      // Unchecked
      score += 20;
    }
    
    if (vitalStatus == 'critical') score += 20;
    if (vitalStatus == 'warning') score += 10;
    
    return score.clamp(0, 100);
  }
}
