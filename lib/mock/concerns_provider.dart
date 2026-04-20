import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConcernModel {
  final String id;
  final String doctorId;
  final String doctorName;
  final String patientId;
  final String patientName;
  final String type; 
  final String description;
  final String priority; 
  final DateTime timeReceived;
  final String status; // Pending, Accepted, Declined, Completed
  final DateTime? respondedAt;
  final String? respondedByNurseId;

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
    this.respondedAt,
    this.respondedByNurseId,
  });

  ConcernModel copyWith({
    String? status,
    DateTime? respondedAt,
    String? respondedByNurseId,
  }) {
    return ConcernModel(
      id: id,
      doctorId: doctorId,
      doctorName: doctorName,
      patientId: patientId,
      patientName: patientName,
      type: type,
      description: description,
      priority: priority,
      timeReceived: timeReceived,
      status: status ?? this.status,
      respondedAt: respondedAt ?? this.respondedAt,
      respondedByNurseId: respondedByNurseId ?? this.respondedByNurseId,
    );
  }
}

class ConcernsNotifier extends Notifier<List<ConcernModel>> {
  @override
  List<ConcernModel> build() => [];

  void addConcern(ConcernModel concern) {
    state = [concern, ...state];
  }

  void updateStatus(String id, String newStatus, {String? nurseId}) {
    state = [
      for (final c in state)
        if (c.id == id)
          c.copyWith(
            status: newStatus,
            respondedAt: DateTime.now(),
            respondedByNurseId: nurseId,
          )
        else c,
    ];
  }

  void markCompleted(String id) {
    updateStatus(id, 'Completed');
  }
}

final concernsProvider = NotifierProvider<ConcernsNotifier, List<ConcernModel>>(ConcernsNotifier.new);
