import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  print('--- Starting Database Setup ---');
  final db = FirebaseFirestore.instance;

  // 1. Setup BEDS
  print('Setting up Beds...');
  final beds = [
    {'type': 'ICU', 'status': 'Occupied'},
    {'type': 'ICU', 'status': 'Available'},
    {'type': 'General', 'status': 'Occupied'},
    {'type': 'General', 'status': 'Available'},
    {'type': 'Emergency', 'status': 'Occupied'},
  ];
  for (var i = 0; i < beds.length; i++) {
    await db.collection('beds').doc('BED-${100 + i}').set(beds[i]);
  }

  // 2. Setup PATIENTS
  print('Setting up Patients...');
  final patients = [
    {
      'name': 'Ravi Kumar',
      'age': 45,
      'gender': 'Male',
      'triageLevel': 'CRITICAL',
      'vitalsSummary': 'BP: 90/60, HR: 110',
      'assignedBedId': 'BED-100',
      'attendanceStatus': 'Attended',
      'vitalStatus': 'critical',
      'createdAt': Timestamp.now(),
    },
    {
      'name': 'Sita Sharma',
      'age': 32,
      'gender': 'Female',
      'triageLevel': 'STABLE',
      'vitalsSummary': 'Normal',
      'assignedBedId': 'BED-102',
      'attendanceStatus': 'Attended',
      'vitalStatus': 'normal',
      'createdAt': Timestamp.now(),
    }
  ];
  for (var p in patients) {
    await db.collection('patients').add(p);
  }

  // 3. Setup ALERTS
  print('Skipping static alerts (requested by user)...');

  print('--- Database Setup Complete! ---');
  print('You can now close this and run your main app.');
}
