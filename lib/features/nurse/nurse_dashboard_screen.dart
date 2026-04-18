import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../mock/mock_data.dart';
import '../alerts/widgets/alert_card.dart';

class NurseDashboardScreen extends ConsumerWidget {
  const NurseDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final updatedStaff = ref.watch(staffProvider).firstWhere((s) => s.uid == currentUser.uid, orElse: () => currentUser);
    final alerts = ref.watch(alertsProvider).where((a) => a.target == 'All Staff' || a.target == 'Nurses Only').toList();
    final patients = ref.watch(patientsProvider).where((p) => p.assignedStaffId == currentUser.uid).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('RapidCare Nurse'),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: () {}),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => context.go('/login')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Good morning,\n${updatedStaff.name.split(' ')[0]} 👋', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32)),
            const Gap(8),
            Row(
              children: [
                Chip(label: Text(updatedStaff.specialization, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: AppTheme.accent, side: BorderSide.none),
              ],
            ),
            const Gap(24),
            
            GestureDetector(
              onTap: () => ref.read(staffProvider.notifier).toggleAvailability(updatedStaff.uid, !updatedStaff.available),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: updatedStaff.available 
                        ? [AppTheme.stable, AppTheme.stable.withValues(alpha: 0.7)] 
                        : [AppTheme.textSecondary, Colors.grey.shade400],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: (updatedStaff.available ? AppTheme.stable : AppTheme.textSecondary).withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))
                  ]
                ),
                child: Column(
                  children: [
                    Icon(
                      updatedStaff.available ? Icons.check_circle_outline : Icons.do_not_disturb_on, 
                      size: 56, color: Colors.white
                    ).animate(target: updatedStaff.available?1:0).scale(begin: const Offset(0.8,0.8), end: const Offset(1,1)),
                    const Gap(12),
                    Text(
                      updatedStaff.available ? 'You are Available' : 'You are Unavailable',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Gap(4),
                    Text(
                      updatedStaff.available ? 'Tap to go offline' : 'Tap to go online',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    )
                  ],
                ),
              ),
            ),
            const Gap(32),

            Row(
              children: [
                Expanded(child: _buildQuickAction(context, 'Start Triage', Icons.medical_services, AppTheme.primary, () => context.push('/triage'))),
                const Gap(12),
                Expanded(child: _buildQuickAction(context, 'View Beds', Icons.bed, AppTheme.urgent, () => context.push('/beds'))),
              ],
            ),
            const Gap(32),

            Text('My Assigned Alerts', style: Theme.of(context).textTheme.headlineMedium),
            const Gap(16),
            if (alerts.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle, size: 48, color: AppTheme.stable),
                    Gap(12),
                    Text("No active alerts — you're all clear", style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ).animate().fade()
            else
              for (final alert in alerts) 
                AlertCard(alert: alert, onTap: () => context.push('/alerts/${alert.id}')).animate().slideX(),
            
            const Gap(32),
            Text('My Assigned Patients', style: Theme.of(context).textTheme.headlineMedium),
            const Gap(16),
            if (patients.isEmpty)
               const Text('No assigned patients.', style: TextStyle(color: AppTheme.textSecondary))
            else
              for (final p in patients)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: AppTheme.primary.withValues(alpha: 0.1), child: const Icon(Icons.person, color: AppTheme.primary)),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${p.vitalsSummary}\nBed: ${p.assignedBedId ?? 'None'}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    isThreeLine: true,
                    onTap: () => context.push('/patients/${p.id}'),
                  ),
                ).animate().slideY()
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const Gap(8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
