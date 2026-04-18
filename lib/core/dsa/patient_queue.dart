import '../../models/patient_model.dart';
import 'dart:collection';

/// Pure DSA Implementation: FIFO Queue for Incoming Patients
class PatientQueue {
  final Queue<PatientModel> _queue = ListQueue<PatientModel>();

  void enqueue(PatientModel patient) {
    _queue.addLast(patient);
  }

  PatientModel? dequeue() {
    if (_queue.isEmpty) return null;
    return _queue.removeFirst();
  }

  PatientModel? peek() {
    if (_queue.isEmpty) return null;
    return _queue.first;
  }
  
  bool get isEmpty => _queue.isEmpty;
  
  int get length => _queue.length;

  int positionOf(String id) {
    int pos = 1;
    for (var p in _queue) {
      if (p.id == id) return pos;
      pos++;
    }
    return -1;
  }
  
  List<PatientModel> toList() => _queue.toList();
}
