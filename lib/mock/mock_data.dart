import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alert_model.dart';
import '../models/staff_model.dart';
import '../models/patient_model.dart';
import '../models/bed_model.dart';

import '../core/dsa/patient_queue.dart';
import '../core/dsa/alert_priority_queue.dart';

// Current active user
class CurrentUserNotifier extends Notifier<StaffModel?> {
  @override
  StaffModel? build() => null;
  void setUser(StaffModel user) => state = user;
}
final currentUserProvider = NotifierProvider<CurrentUserNotifier, StaffModel?>(CurrentUserNotifier.new);

// PATIENTS
class PatientsNotifier extends Notifier<List<PatientModel>> {
  @override
  List<PatientModel> build() => [
    PatientModel(id: 'P-001', name: 'Ravi M.', age: 45, gender: 'M', triageLevel: 'CRITICAL', vitalsSummary: 'BP: 80/50, HR: 135', assignedBedId: 'ICU-1', lastVitalsTime: DateTime.now().subtract(const Duration(minutes: 14)), vitalStatus: 'critical'),
    PatientModel(id: 'P-002', name: 'Meera S.', age: 62, gender: 'F', triageLevel: 'URGENT', vitalsSummary: 'BP: 150/90, HR: 102', assignedBedId: 'EMR-2', lastVitalsTime: DateTime.now().subtract(const Duration(minutes: 32)), vitalStatus: 'warning'),
    PatientModel(id: 'P-003', name: 'Aarav J.', age: 28, gender: 'M', triageLevel: 'STABLE', vitalsSummary: 'BP: 120/80, HR: 72', assignedBedId: 'GEN-4', lastVitalsTime: DateTime.now().subtract(const Duration(minutes: 120)), vitalStatus: 'normal'),
  ];
  
  void addPatient(PatientModel p) {
    state = [...state, p];
  }

  void updatePatient(PatientModel updated) {
    state = [for (final p in state) p.id == updated.id ? updated : p];
  }

  void removePatient(String id) {
    state = state.where((p) => p.id != id).toList();
  }
}
final patientsProvider = NotifierProvider<PatientsNotifier, List<PatientModel>>(PatientsNotifier.new);

// INCOMING PATIENTS
final globalPatientQueue = PatientQueue<PatientModel>();
class IncomingPatientNotifier extends Notifier<List<PatientModel>> {
  @override
  List<PatientModel> build() {
    // Initial data if needed, or leave empty if using global data
    return globalPatientQueue.toList();
  }

  void addIncoming(PatientModel p) {
    globalPatientQueue.enqueue(p);
    state = globalPatientQueue.toList();
  }

  void startTriageAndRemove() {
    if (!globalPatientQueue.isEmpty) {
      globalPatientQueue.dequeue();
      state = globalPatientQueue.toList();
    }
  }
}
final incomingPatientProvider = NotifierProvider<IncomingPatientNotifier, List<PatientModel>>(IncomingPatientNotifier.new);

// BEDS
class BedsNotifier extends Notifier<List<BedModel>> {
  @override
  List<BedModel> build() {
    List<BedModel> initialBeds = [];
    for(int i=1; i<=10; i++) initialBeds.add(BedModel(id: 'ICU-$i', type: 'ICU', status: i<=3 ? 'Occupied' : 'Available'));
    for(int i=1; i<=20; i++) initialBeds.add(BedModel(id: 'GEN-$i', type: 'General', status: i<=12 ? 'Occupied' : (i==13 ? 'Reserved' : 'Available')));
    for(int i=1; i<=15; i++) initialBeds.add(BedModel(id: 'EMR-$i', type: 'Emergency', status: i<=5 ? 'Occupied' : 'Available'));
    return initialBeds;
  }
  
  void updateBedStatus(String bedId, String newStatus) {
    state = [for (final b in state) b.id == bedId ? BedModel(id: b.id, type: b.type, status: newStatus) : b];
  }
}
final bedsProvider = NotifierProvider<BedsNotifier, List<BedModel>>(BedsNotifier.new);

// ALERTS
final globalAlertQueue = AlertPriorityQueue();
class AlertNotifier extends Notifier<List<AlertModel>> {
  @override
  List<AlertModel> build() {
    return globalAlertQueue.toList();
  }

  void addAlert(AlertModel alert) {
    globalAlertQueue.insert(alert);
    state = globalAlertQueue.toList();
  }
  
  void updateStatus(String id, String newStatus) {
    final current = globalAlertQueue.toList();
    final updated = current.map((a) => a.id == id ? AlertModel(id: a.id, type:a.type, severity:a.severity, target:a.target, message:a.message, createdAt:a.createdAt, status:newStatus) : a).toList();
    globalAlertQueue.clear();
    for (var u in updated) globalAlertQueue.insert(u);
    state = globalAlertQueue.toList();
  }
}
final alertsProvider = NotifierProvider<AlertNotifier, List<AlertModel>>(AlertNotifier.new);

// STAFF PROVIDER
class StaffNotifier extends Notifier<List<StaffModel>> {
  @override
  List<StaffModel> build() => [
    StaffModel(uid: 'S01', email: 'admin@cityhospital.com', name: 'Priya Desai', role: 'Admin', specialization: 'Operations'),
    StaffModel(uid: 'S02', email: 'arjun@cityhospital.com', name: 'Dr. Arjun Mehta', role: 'Doctor', specialization: 'Emergency Med', averageResponseTimeSecs: 90, patientCount: 4),
    StaffModel(uid: 'S03', email: 'priya@cityhospital.com', name: 'Nurse Priya Sharma', role: 'Nurse', specialization: 'Trauma ICU', averageResponseTimeSecs: 45, patientCount: 2),
    StaffModel(uid: 'S04', email: 'vikram@cityhospital.com', name: 'Dr. Vikram Singh', role: 'Doctor', specialization: 'Cardiology', available: false),
    StaffModel(uid: 'S05', email: 'neha@cityhospital.com', name: 'Nurse Neha Patel', role: 'Nurse', specialization: 'General Ward'),
  ];

  void toggleAvailability(String uid, bool isAv) {
    state = [for (final s in state) s.uid == uid ? s.copyWith(available: isAv) : s];
  }
}
final staffProvider = NotifierProvider<StaffNotifier, List<StaffModel>>(StaffNotifier.new);
