import 'package:cloud_firestore/cloud_firestore.dart';

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
  final List<String> notes;
  final String attendanceStatus; // 'Pending', 'Attended', 'Not_Attended'
  final List<String> orders;
  final List<int> vitalsTrend;
  final List<Map<String, dynamic>> events;
  final String? triagedBy;
  final String? triagedByRole;
  final DateTime? lastNurseActionTime;
  final DateTime? nextVitalsTime;
  final String? phone;
  final String? assignedNurseId; // New: Accountability
  final String? assignedNurseName;
  final DateTime? careStartedAt; // From Triage end to Discharge

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
    this.notes = const [],
    this.attendanceStatus = 'Pending',
    this.orders = const [],
    this.vitalsTrend = const [72, 75, 71, 78, 74],
    this.events = const [],
    this.triagedBy,
    this.triagedByRole,
    this.lastNurseActionTime,
    this.nextVitalsTime,
    this.phone,
    this.assignedNurseId,
    this.assignedNurseName,
    this.careStartedAt,
  });

  factory PatientModel.fromMap(Map<String, dynamic> map, String id) {
    return PatientModel(
      id: id,
      name: map['name'] as String? ?? 'Unknown',
      age: map['age'] as int? ?? 0,
      gender: map['gender'] as String? ?? 'M',
      triageLevel: map['triageLevel'] as String? ?? 'STABLE',
      vitalsSummary: map['vitalsSummary'] as String? ?? '',
      assignedBedId: map['assignedBedId'] as String?,
      assignedStaffId: map['assignedStaffId'] as String?,
      lastVitalsTime: map['lastVitalsTime'] != null ? (map['lastVitalsTime'] as Timestamp).toDate() : null,
      vitalStatus: map['vitalStatus'] as String? ?? 'normal',
      notes: List<String>.from(map['notes'] ?? []),
      attendanceStatus: map['attendanceStatus'] as String? ?? 'Pending',
      orders: List<String>.from(map['orders'] ?? []),
      vitalsTrend: List<int>.from(map['vitalsTrend'] ?? [72, 75, 71, 78, 74]),
      events: List<Map<String, dynamic>>.from(map['events'] ?? []),
      triagedBy: map['triagedBy'] as String?,
      triagedByRole: map['triagedByRole'] as String?,
      lastNurseActionTime: map['lastNurseActionTime'] != null ? (map['lastNurseActionTime'] as Timestamp).toDate() : null,
      nextVitalsTime: map['nextVitalsTime'] != null ? (map['nextVitalsTime'] as Timestamp).toDate() : null,
      phone: map['phone'] as String?,
      assignedNurseId: map['assignedNurseId'] as String?,
      assignedNurseName: map['assignedNurseName'] as String?,
      careStartedAt: map['careStartedAt'] != null ? (map['careStartedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'triageLevel': triageLevel,
      'vitalsSummary': vitalsSummary,
      'assignedBedId': assignedBedId,
      'assignedStaffId': assignedStaffId,
      'lastVitalsTime': lastVitalsTime != null ? Timestamp.fromDate(lastVitalsTime!) : null,
      'vitalStatus': vitalStatus,
      'notes': notes,
      'attendanceStatus': attendanceStatus,
      'orders': orders,
      'vitalsTrend': vitalsTrend,
      'events': events,
      'triagedBy': triagedBy,
      'triagedByRole': triagedByRole,
      'lastNurseActionTime': lastNurseActionTime != null ? Timestamp.fromDate(lastNurseActionTime!) : null,
      'nextVitalsTime': nextVitalsTime != null ? Timestamp.fromDate(nextVitalsTime!) : null,
      'phone': phone,
      'assignedNurseId': assignedNurseId,
      'assignedNurseName': assignedNurseName,
      'careStartedAt': careStartedAt != null ? Timestamp.fromDate(careStartedAt!) : null,
    };
  }

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
    List<String>? notes,
    String? attendanceStatus,
    List<String>? orders,
    List<int>? vitalsTrend,
    List<Map<String, dynamic>>? events,
    String? triagedBy,
    String? triagedByRole,
    DateTime? lastNurseActionTime,
    DateTime? nextVitalsTime,
    String? phone,
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
      notes: notes ?? this.notes,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      orders: orders ?? this.orders,
      vitalsTrend: vitalsTrend ?? this.vitalsTrend,
      events: events ?? this.events,
      triagedBy: triagedBy ?? this.triagedBy,
      triagedByRole: triagedByRole ?? this.triagedByRole,
      lastNurseActionTime: lastNurseActionTime ?? this.lastNurseActionTime,
      nextVitalsTime: nextVitalsTime ?? this.nextVitalsTime,
      phone: phone ?? this.phone,
      assignedNurseId: assignedNurseId ?? this.assignedNurseId,
      assignedNurseName: assignedNurseName ?? this.assignedNurseName,
      careStartedAt: careStartedAt ?? this.careStartedAt,
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
      score += 20;
    }
    
    if (vitalStatus == 'critical') score += 20;
    if (vitalStatus == 'warning') score += 10;
    
    return score.clamp(0, 100);
  }
}
