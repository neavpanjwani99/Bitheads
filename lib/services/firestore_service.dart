import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/patient_model.dart';
import '../models/bed_model.dart';
import '../models/alert_model.dart';
import '../models/clinical_request_model.dart';
import '../models/staff_model.dart';
import '../models/department_model.dart';
import '../models/inventory_model.dart';
import '../models/work_shift_model.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirestoreService() {
    _runAutoSweep();
  }

  Future<void> _runAutoSweep() async {
    try {
      final users = await _db.collection('users').get();
      final random = Random();
      final bloods = ['A+', 'A-', 'B+', 'B-', 'AB+', 'O+', 'O-'];
      for (var doc in users.docs) {
        final data = doc.data();
        if (data['performanceScore'] == 100 || data['performanceScore'] == null || data['bloodGroup'] == 'O+') {
           await doc.reference.update({
             'performanceScore': data['performanceScore'] == 100 ? 0 : (data['performanceScore'] ?? 0),
             'bloodGroup': bloods[random.nextInt(bloods.length)]
           });
        }
      }

      final depts = await _db.collection('departments').get();
      if (depts.docs.isEmpty) {
        final newDepts = [
          DepartmentModel(id: 'DEPT-ICU', name: 'ICU Care', totalBeds: 20, occupiedBeds: 15, isDrillActive: false, status: 'Critical', headOfDept: 'Dr. Smith'),
          DepartmentModel(id: 'DEPT-ER', name: 'Emergency', totalBeds: 30, occupiedBeds: 25, isDrillActive: false, status: 'Critical', headOfDept: 'Dr. Jones'),
          DepartmentModel(id: 'DEPT-PED', name: 'Pediatric', totalBeds: 15, occupiedBeds: 5, isDrillActive: false, status: 'Normal', headOfDept: 'Dr. Sarah'),
          DepartmentModel(id: 'DEPT-TRM', name: 'Trauma', totalBeds: 10, occupiedBeds: 8, isDrillActive: false, status: 'Critical', headOfDept: 'Dr. Mike'),
        ];
        for (var d in newDepts) {
          await _db.collection('departments').doc(d.id).set(d.toMap());
        }
      }
      // --- SEED SHIFT HISTORY for Nurses (only if empty) ---
      final random2 = Random();
      for (var doc in users.docs) {
        final data = doc.data();
        if (data['role'] != 'Nurse') continue;
        final shiftsSnap = await doc.reference.collection('shifts').limit(1).get();
        if (shiftsSnap.docs.isNotEmpty) continue; // Already has history

        // Seed last 5 days of realistic shift data
        final sampleLogs = [
          ['Med Given: Paracetamol to John', 'Completed ORDER: IV fluids (Patient: Priya)', 'Concern from Dr. Smith — Medication Check — Accepted'],
          ['Med Given: Amoxicillin to Riya', 'Vitals updated for Deepak'],
          ['Completed CONCERN: Vitals Monitor (Patient: Arjun)', 'Med Given: Metformin to Sunita'],
          ['Med Given: Ibuprofen to Kavya'],
          ['Completed ORDER: Blood draw (Patient: Mohit)', 'Med Given: Aspirin to Anita', 'Vitals updated for Ravi'],
        ];
        for (int i = 1; i <= 5; i++) {
          final shiftDate = DateTime.now().subtract(Duration(days: i));
          final dateStr = '${shiftDate.year}-${shiftDate.month.toString().padLeft(2,'0')}-${shiftDate.day.toString().padLeft(2,'0')}';
          final meds = random2.nextInt(15) + 5;
          final tasks = random2.nextInt(5) + 1;
          await doc.reference.collection('shifts').doc(dateStr).set({
            'date': Timestamp.fromDate(shiftDate),
            'shift': '08:00 - 16:00',
            'patientsCount': random2.nextInt(10) + 5,
            'alertsHandled': tasks,
            'notesWritten': random2.nextInt(4),
            'avgResponseTime': '${random2.nextInt(3)}m ${random2.nextInt(60)}s',
            'medicationsGiven': meds,
            'tasksCompleted': tasks,
            'logs': sampleLogs[i - 1],
          });
        }
      }
    } catch (e) {
      print('AutoSweep Error: $e');
    }
  }

  // --- PATIENTS ---
  Stream<List<PatientModel>> getPatients() {
    return _db.collection('patients').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => PatientModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addPatient(PatientModel patient) {
    return _db.collection('patients').add(patient.toMap());
  }

  Future<void> updatePatientFields(String id, Map<String, dynamic> fields) {
    return _db.collection('patients').doc(id).update(fields);
  }

  Future<void> updatePatient(PatientModel patient) {
    return _db.collection('patients').doc(patient.id).update(patient.toMap());
  }

  // --- BEDS ---
  Stream<List<BedModel>> getBeds() {
    return _db.collection('beds').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => BedModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> deleteBed(String bedId) {
    return _db.collection('beds').doc(bedId).delete();
  }

  Future<void> addBed(BedModel bed) {
    return _db.collection('beds').doc(bed.id).set(bed.toMap());
  }

  Future<void> updateBedStatus(String bedId, String status, {String? patientId, String? patientName}) {
    return _db.collection('beds').doc(bedId).update({
      'status': status,
      'patientId': patientId,
      'patientName': patientName,
    });
  }

  // --- ALERTS ---
  Stream<List<AlertModel>> getAlerts() {
    return _db.collection('alerts').orderBy('createdAt', descending: true).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => AlertModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addAlert(AlertModel alert) {
    return _db.collection('alerts').add(alert.toMap());
  }

  Future<void> updateAlert(AlertModel alert) {
    return _db.collection('alerts').doc(alert.id).update(alert.toMap());
  }

  // --- CLINICAL REQUESTS ---
  Stream<List<ClinicalRequestModel>> getClinicalRequests() {
    return _db.collection('clinical_requests').orderBy('createdAt', descending: true).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ClinicalRequestModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addClinicalRequest(ClinicalRequestModel request) {
    return _db.collection('clinical_requests').add(request.toMap());
  }

  Future<void> updateClinicalRequestStatus(String requestId, String status) {
    return _db.collection('clinical_requests').doc(requestId).update({'status': status});
  }

  // --- STAFF ---
  Future<void> toggleAvailability(String uid, bool isAvailable) async {
    await _db.collection('users').doc(uid).update({'available': isAvailable});
  }

  Future<void> dismissTriage(String uid, String patientId) async {
    await _db.collection('users').doc(uid).update({
      'dismissedTriageIds': FieldValue.arrayUnion([patientId])
    });
  }

  Stream<List<String>> getDismissedTriageIds(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return [];
      final data = doc.data() as Map<String, dynamic>;
      return List<String>.from(data['dismissedTriageIds'] ?? []);
    });
  }

  Stream<List<StaffModel>> getStaff() {
    return _db.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => StaffModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> sendNudge(String uid, String? message) {
    return _db.collection('users').doc(uid).update({'activeNudge': message});
  }

  Future<void> updateStaffPerformance(String uid, int score) {
    return _db.collection('users').doc(uid).update({'performanceScore': score});
  }

  Future<void> incrementStaffPerformance(String uid, int delta) {
    return _db.collection('users').doc(uid).update({
      'performanceScore': FieldValue.increment(delta),
      'lastActivityAt': FieldValue.serverTimestamp()
    });
  }

  Future<void> updateActivityHeartbeat(String uid) {
    return _db.collection('users').doc(uid).update({'lastActivityAt': FieldValue.serverTimestamp()});
  }

  // --- DEPARTMENTS & INVENTORY ---
  Stream<List<DepartmentModel>> getDepartments() {
    return _db.collection('departments').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => DepartmentModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> updateDrillStatus(String deptId, bool isActive) {
    return _db.collection('departments').doc(deptId).update({
      'isDrillActive': isActive,
      'status': isActive ? 'Drill' : 'Normal',
    });
  }

  Stream<List<InventoryItemModel>> getInventory() {
    return _db.collection('inventory').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => InventoryItemModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> updateInventoryStock(String itemId, double stock) {
    return _db.collection('inventory').doc(itemId).update({'currentStock': stock});
  }

  // --- WORK SHIFTS ---
  Stream<List<WorkShiftModel>> getStaffShifts(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('shifts')
        .orderBy('date', descending: true)
        .limit(14)
        .snapshots()
        .map((snap) => snap.docs.map((d) => WorkShiftModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addLogToCurrentShift(String uid, String log, {bool isMedication = false, bool isTask = false}) async {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    final shiftRef = _db.collection('users').doc(uid).collection('shifts').doc(dateStr);

    final doc = await shiftRef.get();
    if (!doc.exists) {
      // First log of the day — create the shift document
      await shiftRef.set(WorkShiftModel(
        id: dateStr,
        date: today,
        shift: '08:00 - 16:00',
        logs: [log],
        medicationsGiven: isMedication ? 1 : 0,
        tasksCompleted: isTask ? 1 : 0,
      ).toMap());
    } else {
      // Shift exists — append log and increment counters
      await shiftRef.update({
        'logs': FieldValue.arrayUnion([log]),
        if (isMedication) 'medicationsGiven': FieldValue.increment(1),
        if (isTask) 'tasksCompleted': FieldValue.increment(1),
        if (isTask) 'alertsHandled': FieldValue.increment(1),
      });
    }
  }
}

