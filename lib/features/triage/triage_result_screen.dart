import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../app/theme.dart';
import '../../models/patient_model.dart';
import '../../models/staff_model.dart';
import 'dart:math';

import '../../providers/auth_provider.dart';
import '../../providers/firestore_providers.dart';
import '../../services/firestore_service.dart';

class TriageResultScreen extends ConsumerStatefulWidget {
  final String triageLevel;
  final String? name;
  final int? age;
  final String? gender;
  final String? patientId;
  const TriageResultScreen({super.key, required this.triageLevel, this.name, this.age, this.gender, this.patientId});

  @override
  ConsumerState<TriageResultScreen> createState() => _TriageResultScreenState();
}

class _TriageResultScreenState extends ConsumerState<TriageResultScreen> {
  String? selectedBedId;
  String? selectedNurseId;

  @override
  Widget build(BuildContext context) {
    Color levelColor = widget.triageLevel == 'CRITICAL' ? AppTheme.critical : (widget.triageLevel == 'URGENT' ? AppTheme.urgent : AppTheme.stable);
    String desc = widget.triageLevel == 'CRITICAL' ? 'Immediate life-saving intervention required.' : (widget.triageLevel == 'URGENT' ? 'Urgent care needed, but not immediately life-threatening.' : 'Patient is stable, can wait for care.');

    final bedsAsync = ref.watch(realBedsProvider);
    final staffAsync = ref.watch(realStaffProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Triage Complete')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
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
                  Text(widget.triageLevel, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: levelColor)),
                  const Gap(16),
                  Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textPrimary)),
                ],
              ),
            ),
            const Gap(32),
            
            // Bed Selection Section - ONLY for NEW Emergency Triage
            if (widget.patientId == null) ...[
              const Text('Assign Bed (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Gap(12),
              bedsAsync.when(
                data: (beds) {
                  final availableBeds = beds.where((b) => b.status == 'Available').toList();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Select an available bed'),
                        value: selectedBedId,
                        items: availableBeds.map((b) => DropdownMenuItem(
                          value: b.id,
                          child: Text('${b.id} - ${b.type}'),
                        )).toList(),
                        onChanged: (v) => setState(() => selectedBedId = v),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (e, _) => Text('Error loading beds: $e'),
              ),
              const Gap(24),

              // ── Assign Nurse ──────────────────────────────────────────
              const Text('Assign Nurse (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Gap(12),
              staffAsync.when(
                data: (staff) {
                  final nurses = staff.where((s) => s.role == 'Nurse').toList();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Select a nurse'),
                        value: selectedNurseId,
                        items: nurses.map((n) => DropdownMenuItem(
                          value: n.uid,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppTheme.primaryLight,
                                child: Text(n.name.substring(0, 1), style: const TextStyle(fontSize: 12, color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
                              ),
                              const Gap(10),
                              Text(n.name),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: n.available ? AppTheme.stable.withValues(alpha: 0.1) : AppTheme.critical.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(n.available ? 'Available' : 'Busy', style: TextStyle(fontSize: 10, color: n.available ? AppTheme.stable : AppTheme.critical, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        )).toList(),
                        onChanged: (v) => setState(() => selectedNurseId = v),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (e, _) => Text('Error loading staff: $e'),
              ),
            ],

            const Gap(40),
            
            SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                onPressed: () async {
                  final user = ref.read(authNotifierProvider);
                  
                  if (widget.patientId != null && widget.patientId!.isNotEmpty) {
                    // UPDATE EXISTING
                    int cooldownMins = 60;
                    if (widget.triageLevel == 'CRITICAL') cooldownMins = 15;
                    if (widget.triageLevel == 'URGENT') cooldownMins = 30;

                    await ref.read(firestoreServiceProvider).updatePatientFields(widget.patientId!, {
                      'triageLevel': widget.triageLevel,
                      'attendanceStatus': 'Pending',
                      'vitalsSummary': 'Triage Updated: ${widget.triageLevel}',
                      'lastVitalsTime': Timestamp.fromDate(DateTime.now()),
                      'nextVitalsTime': Timestamp.fromDate(DateTime.now().add(Duration(minutes: cooldownMins))),
                      'triagedBy': user?.name ?? 'Staff',
                      'triagedByRole': user?.role ?? 'Role',
                      if (selectedBedId != null) 'assignedBedId': selectedBedId,
                      if (selectedNurseId != null) 'assignedNurseId': selectedNurseId,
                    });
                  } else {
                    // ADD NEW
                    int cooldownMins = 60;
                    if (widget.triageLevel == 'CRITICAL') cooldownMins = 15;
                    if (widget.triageLevel == 'URGENT') cooldownMins = 30;

                    final newPatient = PatientModel(
                      id: '', 
                      name: widget.name?.isNotEmpty == true ? widget.name! : 'Anonymous Trauma #${Random().nextInt(99)}', 
                      age: widget.age ?? 35, 
                      gender: widget.gender?.isNotEmpty == true ? widget.gender! : 'Unknown',
                      triageLevel: widget.triageLevel, 
                      vitalsSummary: 'Assessed from Triage Engine',
                      assignedStaffId: user?.uid, 
                      assignedNurseId: selectedNurseId,
                      lastVitalsTime: DateTime.now(),
                      nextVitalsTime: DateTime.now().add(Duration(minutes: cooldownMins)),
                      attendanceStatus: 'Pending',
                      triagedBy: user?.name ?? 'Staff',
                      triagedByRole: user?.role ?? 'Role',
                      assignedBedId: selectedBedId,
                    );
                    await ref.read(firestoreServiceProvider).addPatient(newPatient);

                    // Log to the assigned nurse's shift
                    if (selectedNurseId != null) {
                      await ref.read(firestoreServiceProvider).addLogToCurrentShift(
                        selectedNurseId!,
                        'New Patient Assigned: ${newPatient.name} (${widget.triageLevel})',
                      );
                    }
                  }

                  // Update Bed Status if selected
                  if (selectedBedId != null) {
                    await ref.read(firestoreServiceProvider).updateBedStatus(
                      selectedBedId!, 
                      'Occupied',
                      patientId: widget.patientId ?? 'EMR-${DateTime.now().millisecondsSinceEpoch}',
                      patientName: widget.name ?? 'Emergency Patient',
                    );
                  }
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient saved and assigned.')));
                    
                    if (user?.role == 'Admin') {
                      context.go('/admin');
                    } else if (user?.role == 'Nurse') {
                      context.go('/nurse');
                    } else {
                      context.go('/doctor');
                    }
                  }
                },
                child: const Text('Save to Patient Record')
              ),
            ),
            const Gap(16),
            SizedBox(
              height: 56,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.divider), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  final user = ref.read(authNotifierProvider);
                  if (user?.role == 'Admin') {
                    context.go('/admin');
                  } else if (user?.role == 'Nurse') {
                    context.go('/nurse');
                  } else {
                    context.go('/doctor');
                  }
                },
                child: const Text('Discard', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              )
            ),
          ],
        ),
      ),
    );
  }
}
