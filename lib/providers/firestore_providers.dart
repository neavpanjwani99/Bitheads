import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/patient_model.dart';
import '../models/bed_model.dart';
import '../models/alert_model.dart';
import '../models/staff_model.dart';
import '../models/clinical_request_model.dart';
import '../models/department_model.dart';
import '../models/inventory_model.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Real-time Patients Stream
final realPatientsProvider = StreamProvider<List<PatientModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getPatients();
});

// Real-time Beds Stream
final realBedsProvider = StreamProvider<List<BedModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getBeds();
});

// Real-time Alerts Stream
final realAlertsProvider = StreamProvider<List<AlertModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getAlerts();
});

// Real-time Staff Stream
final realStaffProvider = StreamProvider<List<StaffModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getStaff();
});

// Real-time Incoming Patients (ETA based or status based)
final realIncomingPatientsProvider = StreamProvider<List<PatientModel>>((ref) {
  return FirebaseFirestore.instance.collection('patients')
    .where('attendanceStatus', isEqualTo: 'Incoming')
    .snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => PatientModel.fromMap(doc.data(), doc.id)).toList());
});

final realClinicalRequestsProvider = StreamProvider<List<ClinicalRequestModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getClinicalRequests();
});

final dismissedTriageIdsProvider = StreamProvider.family<List<String>, String>((ref, userId) {
  return ref.watch(firestoreServiceProvider).getDismissedTriageIds(userId);
});

final realDepartmentsProvider = StreamProvider<List<DepartmentModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getDepartments();
});

final realInventoryProvider = StreamProvider<List<InventoryItemModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getInventory();
});
