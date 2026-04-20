import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionEntry {
  final DateTime loginTime;
  final DateTime? logoutTime;
  final String role;
  final String device;

  SessionEntry({
    required this.loginTime,
    this.logoutTime,
    required this.role,
    this.device = 'Mobile',
  });

  String get duration {
    if (logoutTime == null) return 'Active';
    final diff = logoutTime!.difference(loginTime);
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }

  SessionEntry copyWith({DateTime? logoutTime}) {
    return SessionEntry(
      loginTime: loginTime,
      logoutTime: logoutTime ?? this.logoutTime,
      role: role,
      device: device,
    );
  }
}

class SessionNotifier extends Notifier<List<SessionEntry>> {
  @override
  List<SessionEntry> build() {
    return [
      // Mock previous sessions
      SessionEntry(loginTime: DateTime.now().subtract(const Duration(days: 1, hours: 8)), logoutTime: DateTime.now().subtract(const Duration(days: 1)), role: 'Doctor'),
      SessionEntry(loginTime: DateTime.now().subtract(const Duration(days: 2, hours: 8, minutes: 15)), logoutTime: DateTime.now().subtract(const Duration(days: 2)), role: 'Nurse'),
      SessionEntry(loginTime: DateTime.now().subtract(const Duration(days: 3, hours: 7, minutes: 50)), logoutTime: DateTime.now().subtract(const Duration(days: 3)), role: 'Doctor'),
      SessionEntry(loginTime: DateTime.now().subtract(const Duration(days: 4, hours: 8, minutes: 10)), logoutTime: DateTime.now().subtract(const Duration(days: 4)), role: 'Doctor'),
      SessionEntry(loginTime: DateTime.now().subtract(const Duration(days: 5, hours: 8)), logoutTime: DateTime.now().subtract(const Duration(days: 5)), role: 'Doctor'),
    ];
  }

  void startSession(String role) {
    state = [
      SessionEntry(loginTime: DateTime.now(), role: role),
      ...state
    ];
  }

  void endSession() {
    final currentList = state;
    if (currentList.isEmpty) return;
    
    final current = currentList.first;
    if (current.logoutTime == null) {
      final updated = current.copyWith(logoutTime: DateTime.now());
      state = [
        updated,
        ...currentList.skip(1),
      ];
    }
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, List<SessionEntry>>(SessionNotifier.new);
