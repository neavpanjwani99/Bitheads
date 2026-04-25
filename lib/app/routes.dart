import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/chatbot_overlay.dart';
import '../features/auth/login_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/beds/bed_tracker_screen.dart';
import '../features/alerts/alert_list_screen.dart';
import '../features/alerts/alert_detail_screen.dart';
import '../features/alerts/alert_trigger_screen.dart';
import '../features/staff/staff_list_screen.dart';
import '../features/triage/triage_form_screen.dart';
import '../features/triage/triage_result_screen.dart';
import '../features/patients/patient_detail_screen.dart';
import '../features/doctor/doctor_dashboard_screen.dart';
import '../features/nurse/nurse_dashboard_screen.dart';

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return AppShell(child: child);
      },
      routes: [
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/doctor',
      builder: (context, state) => const DoctorDashboardScreen(),
    ),
    GoRoute(
      path: '/nurse',
      builder: (context, state) => const NurseDashboardScreen(),
    ),
    GoRoute(
      path: '/beds',
      builder: (context, state) => const BedTrackerScreen(),
    ),
    GoRoute(
      path: '/alerts',
      builder: (context, state) => const AlertListScreen(),
    ),
    GoRoute(
      path: '/alerts/:id',
      builder: (context, state) {
        final alertId = state.pathParameters['id']!;
        return AlertDetailScreen(alertId: alertId);
      },
    ),
    GoRoute(
      path: '/trigger_alert',
      builder: (context, state) => const AlertTriggerScreen(),
    ),
    GoRoute(
      path: '/staff',
      builder: (context, state) => const StaffListScreen(),
    ),
    GoRoute(
      path: '/triage',
      builder: (context, state) => const TriageFormScreen(),
    ),
    GoRoute(
      path: '/triage_result/:level',
      builder: (context, state) {
        final level = state.pathParameters['level']!;
        final name = state.uri.queryParameters['name'];
        final age = int.tryParse(state.uri.queryParameters['age'] ?? '');
        final gender = state.uri.queryParameters['gender'];
        final id = state.uri.queryParameters['id'];
        
        return TriageResultScreen(triageLevel: level, name: name, age: age, gender: gender, patientId: id);
      },
    ),
    GoRoute(
      path: '/patients/:id',
      builder: (context, state) {
        final patientId = state.pathParameters['id']!;
        return PatientDetailScreen(patientId: patientId);
      },
    ),
      ]
    ),
  ],
);

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child, // the actual screen
        Positioned(
          bottom: 80, // above bottom nav or general clearance
          right: 16,
          child: const ChatbotOverlay(),
        )
      ]
    );
  }
}
