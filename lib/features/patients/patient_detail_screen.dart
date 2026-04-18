import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../app/theme.dart';
import '../../mock/mock_data.dart';
import '../../widgets/severity_badge.dart';

class PatientDetailScreen extends ConsumerWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patients = ref.watch(patientsProvider);
    final patient = patients.firstWhere((p) => p.id == patientId, orElse: () => patients.first);
    
    final staff = ref.watch(staffProvider).firstWhere((s) => s.uid == patient.assignedStaffId, orElse: () => ref.watch(staffProvider).first);

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patient.name, style: Theme.of(context).textTheme.headlineMedium),
                        Text('${patient.age} y/o • ${patient.gender}', style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                      ],
                    ),
                    SeverityBadge(severity: patient.triageLevel, fontSize: 16),
                  ],
                ),
              ),
            ),
            const Gap(16),
            const Text('Vitals Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Gap(8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(patient.vitalsSummary, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const Gap(16),
            const Text('Assigned Resources', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Gap(8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.bed, color: AppTheme.primary),
                title: Text('Bed: ${patient.assignedBedId ?? 'Assigning...'}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => context.push('/beds'),
              ),
            ),
            if (patient.assignedStaffId != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person, color: AppTheme.accent),
                  title: Text(staff.name),
                  subtitle: Text(staff.role),
                ),
              )
          ],
        ),
      ),
    );
  }
}
