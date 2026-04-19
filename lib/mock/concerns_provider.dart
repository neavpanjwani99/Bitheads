import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConcernModel {
  final String id;
  final String doctorId;
  final String doctorName;
  final String patientId;
  final String patientName;
  final String type; // Medication Check, Vitals Monitor, etc.
  final String description;
  final String priority; // Normal, Urgent
  final DateTime timeReceived;
  String status; // Pending, Accepted, Declined

  ConcernModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.patientId,
    required this.patientName,
    required this.type,
    required this.description,
    required this.priority,
    required this.timeReceived,
    this.status = 'Pending',
  });
}

class ConcernsNotifier extends Notifier<List<ConcernModel>> {
  @override
  List<ConcernModel> build() => [];

  void addConcern(ConcernModel concern) {
    state = [concern, ...state];
  }

  void updateStatus(String id, String newStatus) {
    state = [
      for (final c in state)
        if (c.id == id)
          ConcernModel(
            id: c.id, doctorId: c.doctorId, doctorName: c.doctorName,
            patientId: c.patientId, patientName: c.patientName, type: c.type,
            description: c.description, priority: c.priority, timeReceived: c.timeReceived,
            status: newStatus
          )
        else c,
    ];
  }
}

final concernsProvider = NotifierProvider<ConcernsNotifier, List<ConcernModel>>(ConcernsNotifier.new);
