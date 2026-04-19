import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../app/theme.dart';
import '../../mock/mock_data.dart';
import '../../models/patient_model.dart';
import '../alerts/widgets/alert_card.dart';

class DoctorDashboardScreen extends ConsumerWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final updatedStaff = ref.watch(staffProvider).firstWhere((s) => s.uid == currentUser.uid, orElse: () => currentUser);
    final alerts = ref.watch(alertsProvider).where((a) => a.target == 'All Staff' || a.target == 'Doctors Only').toList();
    
    // Sort patients by risk score (descending) as requested by the prompt
    List<PatientModel> patients = ref.watch(patientsProvider).where((p) => p.assignedStaffId == currentUser.uid).toList();
    patients.sort((a,b) => b.riskScore.compareTo(a.riskScore));

    int pendingTriage = ref.watch(incomingPatientProvider).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF), // Eye strain fix baseline
      appBar: AppBar(
        title: const Text('Doctor Portal', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.history, color: AppTheme.textPrimary), onPressed: () {}),
          IconButton(icon: const Icon(Icons.logout, color: AppTheme.textPrimary), onPressed: () => context.go('/login')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HEADER
            Text('Good morning,\n${updatedStaff.name} 👋', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28, color: const Color(0xFF1C1C2E))),
            const Gap(8),
            Text('Senior Consultant — ${updatedStaff.specialization}', style: const TextStyle(color: Color(0xFF5F6368), fontSize: 16)),
            const Gap(4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppTheme.primary),
                const Gap(4),
                Text('Department: Emergency | OPD Room 4', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark.withValues(alpha: 0.8))),
              ],
            ),
            const Gap(16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat('Active Patients', patients.length, AppTheme.stable),
                  _buildMiniStat('Pending Triage', pendingTriage, AppTheme.urgent),
                ],
              ),
            ),
            const Gap(24),
            
            // CODE BLUE BUTTON
            SizedBox(
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.critical,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // Instant no-dialog creation
                  ref.read(alertsProvider.notifier).addCodeBlue(updatedStaff);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CODE BLUE SENT ✓'), backgroundColor: AppTheme.critical, duration: Duration(seconds: 3)));
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning, color: Colors.white, size: 28),
                    Gap(12),
                    Text('🚨 CODE BLUE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                  ],
                ),
              ),
            ),
            const Gap(24),

            // AVAILABILITY TOGGLE
            GestureDetector(
              onTap: () => ref.read(staffProvider.notifier).toggleAvailability(updatedStaff.uid, !updatedStaff.available),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: updatedStaff.available ? AppTheme.stable : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(updatedStaff.available ? Icons.check_circle : Icons.do_not_disturb, size: 40, color: Colors.white),
                    const Gap(8),
                    Text(updatedStaff.available ? 'You are Available' : 'You are Unavailable', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(updatedStaff.available ? 'Receiving alerts' : 'Offline', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
            const Gap(32),

            // QUICK ACTIONS
            Row(
              children: [
                Expanded(child: _buildActionBtn(context, 'Start Triage', Icons.medical_services, () => context.push('/triage'))),
                const Gap(12),
                Expanded(child: _buildActionBtn(context, 'Write Note', Icons.edit_note, (){})),
              ],
            ),
            const Gap(32),

            // PATIENT LIST
            const Text('My Patients', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1C1C2E))),
            const Gap(16),
            if (patients.isEmpty)
               const Text('No assigned patients.', style: TextStyle(color: Color(0xFF5F6368)))
            else
              for (final p in patients)
                _buildPatientCard(p, context),

            const Gap(32),
            const Text('Active Alerts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1C1C2E))),
            const Gap(16),
            if (alerts.isEmpty)
              const Text('All clear!', style: TextStyle(color: Color(0xFF5F6368)))
            else
              for (final alert in alerts)
                AlertCard(alert: alert, onTap: () => context.push('/alerts/${alert.id}')),
                
            const Gap(80), // Fab spacing
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, int value, Color c) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF5F6368), fontWeight: FontWeight.bold)),
        const Gap(4),
        Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: c)),
      ],
    );
  }

  Widget _buildActionBtn(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryDark),
            const Gap(8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(PatientModel p, BuildContext context) {
    Color riskColor = p.riskScore > 70 ? AppTheme.critical : (p.riskScore > 30 ? AppTheme.urgent : AppTheme.stable);
    
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE5E5EA))),
      child: InkWell(
        onTap: () => context.push('/patients/${p.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${p.name}, ${p.age}${p.gender}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: riskColor, borderRadius: BorderRadius.circular(8)),
                    child: Text('Risk: ${p.riskScore}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  )
                ],
              ),
              const Gap(8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(border: Border.all(color: AppTheme.divider), borderRadius: BorderRadius.circular(4)),
                    child: Text(p.triageLevel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: p.triageLevel == 'CRITICAL' ? AppTheme.critical : AppTheme.textSecondary)),
                  ),
                  const Gap(8),
                  Text('Bed: ${p.assignedBedId ?? 'Assigning...'}', style: const TextStyle(color: Color(0xFF5F6368), fontWeight: FontWeight.bold)),
                ],
              ),
              const Gap(12),
              Row(
                children: [
                  const Icon(Icons.monitor_heart, size: 14, color: Color(0xFF5F6368)),
                  const Gap(4),
                  Text('Status: ${p.vitalStatus.toUpperCase()}', style: const TextStyle(color: Color(0xFF5F6368), fontSize: 12)),
                  const Spacer(),
                  const Text('Last vitals: 14 mins ago', style: TextStyle(color: Color(0xFF5F6368), fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
