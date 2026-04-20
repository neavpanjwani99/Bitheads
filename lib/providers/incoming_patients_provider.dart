import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

class IncomingPatientModel {
  final String id;
  final String name;
  final String condition;
  final String priority;
  final int etaSeconds;

  IncomingPatientModel({
    required this.id,
    required this.name,
    required this.condition,
    required this.priority,
    required this.etaSeconds,
  });

  IncomingPatientModel copyWith({int? etaSeconds}) {
    return IncomingPatientModel(
      id: id,
      name: name,
      condition: condition,
      priority: priority,
      etaSeconds: etaSeconds ?? this.etaSeconds,
    );
  }
}

class IncomingPatientsNotifier extends Notifier<List<IncomingPatientModel>> {
  @override
  List<IncomingPatientModel> build() {
    // Generate some mock incoming patients
    return [
      IncomingPatientModel(id: 'INC-001', name: 'John Doe', condition: 'Chest pain, severe', priority: 'CRITICAL', etaSeconds: 125),
      IncomingPatientModel(id: 'INC-002', name: 'Sarah Lee', condition: 'Laceration on arm', priority: 'MEDIUM', etaSeconds: 310),
    ];
  }

  void addIncoming(IncomingPatientModel p) {
    state = [...state, p];
  }

  void removeIncoming(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  void decrementETA() {
    state = state.map((p) {
      if (p.etaSeconds > 0) {
        return p.copyWith(etaSeconds: p.etaSeconds - 1);
      }
      return p;
    }).toList();
  }
}

final incomingPatientsProvider = NotifierProvider<IncomingPatientsNotifier, List<IncomingPatientModel>>(IncomingPatientsNotifier.new);

// Helper to start the timer (since build() should be side-effect free, we can do this in the provider definition)
final incomingPatientsTimerProvider = Provider((ref) {
  final notifier = ref.read(incomingPatientsProvider.notifier);
  final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    notifier.decrementETA();
  });
  ref.onDispose(() => timer.cancel());
  return timer;
});
