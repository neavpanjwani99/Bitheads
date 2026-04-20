import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/dsa/action_stack.dart';

class ActionStackNotifier extends Notifier<ActionStack> {
  @override
  ActionStack build() => ActionStack();

  void push(ActionEntry entry) {
    state.push(entry);
    ref.notifyListeners(); // Force UI update for custom object
  }

  void undo() {
    final entry = state.pop();
    if (entry != null) {
      entry.undoAction();
      ref.notifyListeners();
    }
  }
}

final actionStackProvider = NotifierProvider<ActionStackNotifier, ActionStack>(ActionStackNotifier.new);

/// Tracks the 'Golden Hour' (first 60 mins of trauma) for critical patients.
/// State is a Map of patientId -> admissionDateTime.
class GoldenHourNotifier extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() => {};

  void start(String patientId, DateTime startTime) {
    state = {...state, patientId: startTime};
  }

  void stop(String patientId) {
    final newState = Map<String, DateTime>.from(state);
    newState.remove(patientId);
    state = newState;
  }

  int getRemainingSeconds(String patientId) {
    final startTime = state[patientId];
    if (startTime == null) return 0;
    
    final elapsed = DateTime.now().difference(startTime).inSeconds;
    final remaining = 3600 - elapsed;
    return remaining > 0 ? remaining : 0;
  }
}

final goldenHourProvider = NotifierProvider<GoldenHourNotifier, Map<String, DateTime>>(GoldenHourNotifier.new);

/// Global state for Mass Casualty Mode.
class MassCasualtyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void activate() => state = true;
  void deactivate() => state = false;
  void toggle() => state = !state;
}

final massCasualtyProvider = NotifierProvider<MassCasualtyNotifier, bool>(MassCasualtyNotifier.new);

/// A simple ticker provider to force UI updates for countdowns.
final secondTickerProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (i) => i);
});
