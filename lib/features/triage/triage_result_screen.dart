import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../app/theme.dart';
import '../../mock/mock_data.dart';
import '../../models/patient_model.dart';
import 'dart:math';

class TriageResultScreen extends ConsumerWidget {
  final String triageLevel;
  final String? name;
  final int? age;
  final String? gender;
  const TriageResultScreen({super.key, required this.triageLevel, this.name, this.age, this.gender});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color levelColor = triageLevel == 'CRITICAL' ? AppTheme.critical : (triageLevel == 'URGENT' ? AppTheme.urgent : AppTheme.stable);
    String desc = triageLevel == 'CRITICAL' ? 'Immediate life-saving intervention required.' : (triageLevel == 'URGENT' ? 'Urgent care needed, but not immediately life-threatening.' : 'Patient is stable, can wait for care.');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Triage Complete')),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
              child: Column(
                children: [
                  Icon(Icons.assessment_outlined, size: 80, color: levelColor),
                  const Gap(24),
                  const Text('Classified As:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                  Text(triageLevel, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: levelColor)),
                  const Gap(16),
                  Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textPrimary)),
                ],
              ),
            ),
            const Gap(40),
            
            SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                onPressed: () {
                  final curr = ref.read(currentUserProvider);
                  // Generate an ID
                  String id = 'P-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                  
                  ref.read(patientsProvider.notifier).addPatient(PatientModel(
                    id: id, 
                    name: name?.isNotEmpty == true ? name! : 'Anonymous Trauma #${Random().nextInt(99)}', 
                    age: age ?? 35, 
                    gender: gender?.isNotEmpty == true ? gender! : 'Unknown',
                    triageLevel: triageLevel, vitalsSummary: 'Assessed from Triage Engine',
                    assignedStaffId: curr?.uid, lastVitalsTime: DateTime.now(),
                    attendanceStatus: 'Pending',
                  ));
                  
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient saved and assigned.')));
                  context.go('/doctor');
                },
                child: const Text('Save to Patient Record')
              ),
            ),
            const Gap(16),
            SizedBox(
              height: 56,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.divider), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () => context.go('/doctor'),
                child: const Text('Discard', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              )
            ),
          ],
        ),
      ),
    );
  }
}
