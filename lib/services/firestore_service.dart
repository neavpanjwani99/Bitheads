import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/patient_model.dart';
import '../models/bed_model.dart';
import '../models/alert_model.dart';
import '../models/clinical_request_model.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
}
