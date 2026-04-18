import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:collection';
import '../models/bed_model.dart';
import '../models/alert_model.dart';
import '../models/staff_model.dart';
import '../models/patient_model.dart';
import '../core/dsa/alert_priority_queue.dart';
import '../core/dsa/patient_queue.dart';
import '../core/dsa/staff_graph.dart';
import '../core/dsa/action_stack.dart';
import '../core/dsa/occupancy_trend.dart';
import '../core/dsa/staff_sorter.dart';
import '../core/dsa/bed_search.dart';

// --- DSA INSTANCES ---
final globalAlertQueue = AlertPriorityQueue();
final globalPatientQueue = PatientQueue();
final globalStaffGraph = StaffGraph();
final globalActionStack = ActionStack();
final globalOccupancyTrend = OccupancyTrend(windowSizeMinutes: 10);

// Provide generic entry access securely
final actionStackProvider = Provider((ref) => globalActionStack);
final patientQueueProvider = Provider((ref) => globalPatientQueue);
final staffGraphProvider = Provider((ref) => globalStaffGraph);

// --- BED PROVIDER ---
class BedNotifier extends Notifier<List<BedModel>> {
  @override
  List<BedModel> build() {
    List<BedModel> initialBeds = [
      for (int i = 1; i <= 5; i++) BedModel(id: 'ICU-$i', type: 'ICU', status: i <= 2 ? 'Occupied' : 'Available'),
      for (int i = 1; i <= 10; i++) BedModel(id: 'GEN-${i.toString().padLeft(2, '0')}', type: 'General', status: i < 3 ? 'Reserved' : (i < 8 ? 'Occupied' : 'Available')),
      for (int i = 1; i <= 5; i++) BedModel(id: 'EMR-$i', type: 'Emergency', status: i <= 3 ? 'Occupied' : 'Available'),
    ];
    // Must be sorted for Binary Search constraint
    initialBeds.sort((a, b) => a.id.compareTo(b.id)); 
    return initialBeds;
  }

  void updateBedStatus(String id, String status) {
    BedModel? target = BedSearch.binarySearch(state, id);
    if (target != null) {
      String oldStatus = target.status;
      state = [
        for (final bed in state)
          if (bed.id == id) bed.copyWith(status: status) else bed
      ];
      
      // Update Occpancy Trend roughly
      int occ = state.where((b) => b.status == 'Occupied').length;
      double per = (occ / state.length) * 100;
      globalOccupancyTrend.addDataPoint(per);

      // Track Undo History
      globalActionStack.push(AdminAction(
        description: 'Changed bed $id to $status',
        timestamp: DateTime.now(),
        undoCallback: () => _forceUpdateBedStatus(id, oldStatus)
      ));
    }
  }

  void _forceUpdateBedStatus(String id, String status) {
    state = [
      for (final bed in state)
        if (bed.id == id) bed.copyWith(status: status) else bed
    ];
  }
}
final bedsProvider = NotifierProvider<BedNotifier, List<BedModel>>(BedNotifier.new);


// --- ALERT PROVIDER ---
class AlertNotifier extends Notifier<List<AlertModel>> {
  @override
  List<AlertModel> build() {
    globalAlertQueue.clear();
    globalAlertQueue.insert(AlertModel(
      id: 'A1', type: 'Mass Casualty', severity: 'CRITICAL', target: 'All Staff',
      message: 'Highway pileup incoming.', createdAt: DateTime.now().subtract(const Duration(minutes: 5)), status: 'Active',
    ));
    globalAlertQueue.insert(AlertModel(
      id: 'A2', type: 'Equipment Failure', severity: 'STABLE', target: 'Nurses Only',
      message: 'Ventilator offline.', createdAt: DateTime.now().subtract(const Duration(hours: 1)), status: 'Active',
    ));
    globalAlertQueue.insert(AlertModel(
      id: 'A3', type: 'Patient Code Red', severity: 'URGENT', target: 'Doctors Only',
      message: 'ICU-3 coding.', createdAt: DateTime.now().subtract(const Duration(minutes: 10)), status: 'Acknowledged', assignedTo: 'D1'
    ));

    return globalAlertQueue.toList();
  }

  void addAlert(AlertModel alert) {
    globalAlertQueue.insert(alert);
    state = globalAlertQueue.toList();
  }

  void updateAlertStatus(String id, String status, {String? assignedTo}) {
    List<AlertModel> current = globalAlertQueue.toList();
    AlertModel? updatedAlert;
    
    for (var a in current) {
      if (a.id == id) updatedAlert = a.copyWith(status: status, assignedTo: assignedTo ?? a.assignedTo);
    }

    if (updatedAlert != null) {
      globalAlertQueue.removeById(id);
      globalAlertQueue.insert(updatedAlert);
      state = globalAlertQueue.toList();
    }
  }
}
final alertsProvider = NotifierProvider<AlertNotifier, List<AlertModel>>(AlertNotifier.new);


// --- STAFF PROVIDER ---
class StaffNotifier extends Notifier<List<StaffModel>> {
  // Hash map for lookup
  final HashMap<String, StaffModel> _staffMap = HashMap<String, StaffModel>();

  @override
  List<StaffModel> build() {
    List<StaffModel> initial = [
      StaffModel(uid: 'A1', name: 'Admin Sarah', role: 'Admin', specialization: 'Head', available: true),
      StaffModel(uid: 'D1', name: 'Dr. Smith', role: 'Doctor', specialization: 'Cardiology', available: true),
      StaffModel(uid: 'D2', name: 'Dr. Jones', role: 'Doctor', specialization: 'Neurology', available: false, averageResponseTimeSecs: 300),
      StaffModel(uid: 'D3', name: 'Dr. Lee', role: 'Doctor', specialization: 'Trauma', available: true, averageResponseTimeSecs: 90),
      StaffModel(uid: 'D4', name: 'Dr. House', role: 'Doctor', specialization: 'Diagnostics', available: true),
      StaffModel(uid: 'N1', name: 'Nurse Joy', role: 'Nurse', specialization: 'ICU', available: true),
      StaffModel(uid: 'N2', name: 'Nurse Oly', role: 'Nurse', specialization: 'Emergency', available: true, patientCount: 2),
    ];
    
    for (var s in initial) {
      _staffMap[s.uid] = s;
      globalStaffGraph.addStaffNode(s);
    }
    
    // Test bindings for graph
    globalStaffGraph.assignPatientToStaff('D1', 'P1');
    globalStaffGraph.assignPatientToStaff('N1', 'P2');

    return _syncState();
  }

  List<StaffModel> _syncState() {
    List<StaffModel> list = _staffMap.values.toList();
    StaffSorter.mergeSort(list);
    return list;
  }

  void toggleAvailability(String uid, bool isAvailable) {
    if (_staffMap.containsKey(uid)) {
      _staffMap[uid] = _staffMap[uid]!.copyWith(available: isAvailable);
      state = _syncState();
    }
  }
}
final staffProvider = NotifierProvider<StaffNotifier, List<StaffModel>>(StaffNotifier.new);

class CurrentUserNotifier extends Notifier<StaffModel?> {
  @override
  StaffModel? build() => null;
  void setUser(StaffModel user) => state = user;
}
final currentUserProvider = NotifierProvider<CurrentUserNotifier, StaffModel?>(CurrentUserNotifier.new);


// --- PATIENT PROVIDER ---
class PatientNotifier extends Notifier<List<PatientModel>> {
  @override
  List<PatientModel> build() {
    state = [
      PatientModel(id: 'P1', name: 'John Doe', age: 45, gender: 'M', triageLevel: 'CRITICAL', vitalsSummary: 'BP 90/60, HR 120', assignedBedId: 'ICU-1', assignedStaffId: 'D1'),
      PatientModel(id: 'P2', name: 'Jane Roe', age: 32, gender: 'F', triageLevel: 'URGENT', vitalsSummary: 'BP 110/70, HR 100', assignedBedId: 'EMR-1', assignedStaffId: 'N1'),
    ];
    
    // Add incoming un-triaged to Queue
    globalPatientQueue.enqueue(PatientModel(id: 'PQ1', name: 'Incoming Trauma', age: 25, gender: 'M', triageLevel: 'UNASSIGNED', vitalsSummary: 'Unknown'));
    globalPatientQueue.enqueue(PatientModel(id: 'PQ2', name: 'Unknown ER', age: 50, gender: 'F', triageLevel: 'UNASSIGNED', vitalsSummary: 'Unknown'));
    
    return state;
  }

  void updateTriageLevel(String id, String level) {
    state = [
      for (final patient in state)
        if (patient.id == id) patient.copyWith(triageLevel: level) else patient
    ];
  }
}
final patientsProvider = NotifierProvider<PatientNotifier, List<PatientModel>>(PatientNotifier.new);

// Utility Provider to trigger rebuilt of Queue items
final incomingPatientProvider = Provider<List<PatientModel>>((ref) {
  // Note: we'd realistically attach a stream/ticker if dynamic, 
  // currently we provide list to UI safely without causing constant rebuilds
  return globalPatientQueue.toList();
});
