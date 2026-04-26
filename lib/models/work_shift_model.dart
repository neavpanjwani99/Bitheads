import 'package:cloud_firestore/cloud_firestore.dart';

class WorkShiftModel {
  final String id;
  final DateTime date;
  final String shift;
  final int patientsCount;
  final int alertsHandled;
  final int notesWritten;
  final String avgResponseTime;
  final int medicationsGiven;
  final int tasksCompleted;
  final List<String> logs;

  WorkShiftModel({
    required this.id,
    required this.date,
    required this.shift,
    this.patientsCount = 0,
    this.alertsHandled = 0,
    this.notesWritten = 0,
    this.avgResponseTime = 'N/A',
    this.medicationsGiven = 0,
    this.tasksCompleted = 0,
    this.logs = const [],
  });

  factory WorkShiftModel.fromMap(Map<String, dynamic> map, String id) {
    return WorkShiftModel(
      id: id,
      date: map['date'] != null ? (map['date'] as Timestamp).toDate() : DateTime.now(),
      shift: map['shift'] as String? ?? 'Active Shift',
      patientsCount: map['patientsCount'] as int? ?? 0,
      alertsHandled: map['alertsHandled'] as int? ?? 0,
      notesWritten: map['notesWritten'] as int? ?? 0,
      avgResponseTime: map['avgResponseTime'] as String? ?? 'N/A',
      medicationsGiven: map['medicationsGiven'] as int? ?? 0,
      tasksCompleted: map['tasksCompleted'] as int? ?? 0,
      logs: List<String>.from(map['logs'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'shift': shift,
      'patientsCount': patientsCount,
      'alertsHandled': alertsHandled,
      'notesWritten': notesWritten,
      'avgResponseTime': avgResponseTime,
      'medicationsGiven': medicationsGiven,
      'tasksCompleted': tasksCompleted,
      'logs': logs,
    };
  }
}
