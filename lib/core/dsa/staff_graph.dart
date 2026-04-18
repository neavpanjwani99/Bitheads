import '../../models/staff_model.dart';
import '../../models/patient_model.dart';

/// Pure DSA Implementation: Adjacency List representing Staff -> Patient Assignments
class StaffGraph {
  // Map of Staff UID -> List of assigned Patient IDs
  final Map<String, List<String>> _adjacencyList = {};

  // For fast constraint checking: Patient ID -> Assigned Staff UID
  final Map<String, String> _patientToStaffMap = {};

  void addStaffNode(StaffModel staff) {
    if (!_adjacencyList.containsKey(staff.uid)) {
      _adjacencyList[staff.uid] = [];
    }
  }

  void removeStaffNode(String uid) {
    List<String>? patients = _adjacencyList[uid];
    if (patients != null) {
      for (String pId in patients) {
        _patientToStaffMap.remove(pId);
      }
    }
    _adjacencyList.remove(uid);
  }

  /// Add an edge between a staff member and a patient. 
  /// Enforces constraint: One patient cannot have >1 assigned primary staff.
  bool assignPatientToStaff(String staffUid, String patientId) {
    if (!_adjacencyList.containsKey(staffUid)) {
      addStaffNode(StaffModel(uid: staffUid, name: 'temp', role: 'temp', specialization: 'temp', available: true));
    }

    // Constraint Check: Is patient already assigned to someone else?
    if (_patientToStaffMap.containsKey(patientId)) {
      String currentStaff = _patientToStaffMap[patientId]!;
      if (currentStaff == staffUid) {
        return true; // Already assigned here
      }
      return false; // Collision: Assigned to another staff node!
    }

    _adjacencyList[staffUid]!.add(patientId);
    _patientToStaffMap[patientId] = staffUid;
    return true;
  }

  void unassignPatient(String patientId) {
    if (!_patientToStaffMap.containsKey(patientId)) return;
    String staffUid = _patientToStaffMap[patientId]!;
    _adjacencyList[staffUid]?.remove(patientId);
    _patientToStaffMap.remove(patientId);
  }
  
  List<String> getPatientsForStaff(String staffUid) {
    return _adjacencyList[staffUid] ?? [];
  }
  
  String? getStaffForPatient(String patientId) {
    return _patientToStaffMap[patientId];
  }

  Map<String, List<String>> get adjacencyListSnapshot => Map.unmodifiable(_adjacencyList);
}
