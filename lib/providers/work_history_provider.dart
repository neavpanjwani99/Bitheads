import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkHistoryEntry {
  final DateTime date;
  final String shift;
  final int patientsCount;
  final int alertsHandled;
  final int notesWritten;
  final String avgResponseTime;
  
  // Nurse specific
  final int? medicationsGiven;
  final int? tasksCompleted;
  
  // Generic logs (like concern accepted/declined)
  final List<String> logs;

  WorkHistoryEntry({
    required this.date,
    required this.shift,
    this.patientsCount = 0,
    this.alertsHandled = 0,
    this.notesWritten = 0,
    this.avgResponseTime = 'N/A',
    this.medicationsGiven,
    this.tasksCompleted,
    this.logs = const [],
  });
}

class WorkHistoryNotifier extends Notifier<List<WorkHistoryEntry>> {
  @override
  List<WorkHistoryEntry> build() {
    return [
      WorkHistoryEntry(date: DateTime.now().subtract(const Duration(days: 1)), shift: '08:00 - 16:00', patientsCount: 12, alertsHandled: 3, avgResponseTime: '1m 20s', medicationsGiven: 14, logs: ['Concern from Dr. Smith — Medication Check — Accepted — 14:00']),
      WorkHistoryEntry(date: DateTime.now().subtract(const Duration(days: 2)), shift: '08:00 - 16:00', patientsCount: 15, alertsHandled: 5, avgResponseTime: '0m 50s', medicationsGiven: 20),
      WorkHistoryEntry(date: DateTime.now().subtract(const Duration(days: 3)), shift: '08:00 - 16:00', patientsCount: 9, alertsHandled: 1, avgResponseTime: '2m 10s', medicationsGiven: 8),
      WorkHistoryEntry(date: DateTime.now().subtract(const Duration(days: 4)), shift: '08:00 - 16:00', patientsCount: 18, alertsHandled: 4, avgResponseTime: '1m 05s', medicationsGiven: 22),
      WorkHistoryEntry(date: DateTime.now().subtract(const Duration(days: 5)), shift: '08:00 - 16:00', patientsCount: 11, alertsHandled: 2, avgResponseTime: '1m 45s', medicationsGiven: 12),
    ];
  }

  void addLogToCurrentShift(String log) {
    final currentList = state;
    if (currentList.isEmpty) return;
    
    final current = currentList.first;
    if (current.date.day == DateTime.now().day) {
      final updated = WorkHistoryEntry(
        date: current.date,
        shift: current.shift,
        patientsCount: current.patientsCount,
        alertsHandled: current.alertsHandled,
        notesWritten: current.notesWritten,
        avgResponseTime: current.avgResponseTime,
        medicationsGiven: current.medicationsGiven,
        tasksCompleted: current.tasksCompleted,
        logs: [log, ...current.logs],
      );
      state = [updated, ...currentList.skip(1)];
    } else {
      state = [
        WorkHistoryEntry(date: DateTime.now(), shift: 'Active Shift', logs: [log]),
        ...currentList
      ];
    }
  }
}

final workHistoryProvider = NotifierProvider<WorkHistoryNotifier, List<WorkHistoryEntry>>(WorkHistoryNotifier.new);
