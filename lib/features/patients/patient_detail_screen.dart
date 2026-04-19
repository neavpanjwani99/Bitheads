import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';
import '../../mock/mock_data.dart';
import '../../models/patient_model.dart';
import '../../mock/concerns_provider.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  ConsumerState<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen> {
  void _openNoteSheet(PatientModel patient) {
    String noteText = '';
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.background, builder: (c) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Write Clinical Note', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const Gap(16),
            TextField(
              maxLines: 4, decoration: const InputDecoration(hintText: 'Enter observations, updates or handoff notes...'),
              onChanged: (v) => noteText = v,
            ),
            const Gap(16),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (noteText.isNotEmpty) {
                    final newNote = 'Note — ${DateFormat('HH:mm').format(DateTime.now())}: $noteText';
                    final updated = patient.copyWith(notes: [...patient.notes, newNote]);
                    ref.read(patientsProvider.notifier).updatePatient(updated);
                    Navigator.pop(c);
                  }
                }, 
                child: const Text('Save Note')
              )
            ),
            const Gap(24),
          ],
        ),
      );
    });
  }

  void _triggerConcern(PatientModel patient) {
    String pty = 'Normal';
    String typ = 'Medication Check';
    String desc = '';
    
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.surface, builder: (c) {
      return StatefulBuilder(builder: (ctx, setState) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Raise Concern for ${patient.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const Gap(16),
              const Text('Request Type', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13)),
              const Gap(8),
              Wrap(spacing: 8, children: ['Medication Check', 'Vitals Monitor', 'Patient Assistance', 'Equipment Needed', 'Other'].map((t) {
                bool s = typ == t;
                return ChoiceChip(label: Text(t, style: TextStyle(color: s ? Colors.white : AppTheme.textSecondary)), selectedColor: AppTheme.primary, selected: s, onSelected: (_)=>setState(()=>typ=t));
              }).toList()),
              const Gap(12),
              TextField(maxLines: 3, decoration: const InputDecoration(labelText: 'Description'), onChanged: (v)=>desc=v),
              const Gap(12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Priority:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      Radio<String>(value: 'Normal', groupValue: pty, onChanged: (v)=>setState(()=>pty=v!)), const Text('Normal'),
                      Radio<String>(value: 'Urgent', groupValue: pty, onChanged: (v)=>setState(()=>pty=v!)), const Text('Urgent'),
                    ],
                  )
                ],
              ),
              const Gap(24),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: (){
                if(desc.isNotEmpty) {
                  final curr = ref.read(currentUserProvider);
                  ref.read(concernsProvider.notifier).addConcern(ConcernModel(
                    id: 'C${DateTime.now().millisecondsSinceEpoch}',
                    doctorId: curr!.uid, doctorName: curr.name,
                    patientId: patient.id, patientName: patient.name,
                    type: typ, description: desc, priority: pty,
                    timeReceived: DateTime.now()
                  ));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Concern dispatched to Nursing.')));
                }
              }, child: const Text('Submit Concern'))),
              const Gap(32),
            ]
          )
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final patients = ref.watch(patientsProvider);
    final patient = patients.firstWhere((p) => p.id == widget.patientId, orElse: () => patients.first);
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Patient Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Head card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(backgroundColor: AppTheme.primaryLight, radius: 32, child: Text(patient.name.substring(0,1), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryDark))),
                    const Gap(12),
                    Text(patient.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    Text('${patient.age} yrs • ${patient.gender} • ID: ${patient.id}', style: const TextStyle(color: AppTheme.textSecondary)),
                    const Gap(16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBadge(patient.triageLevel, patient.triageLevel == 'CRITICAL' ? AppTheme.critical : (patient.triageLevel == 'URGENT' ? AppTheme.urgent : AppTheme.stable)),
                        const Gap(8),
                        _buildBadge('Risk Score: ${patient.riskScore}', AppTheme.textSecondary),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const Gap(24),
            
            // Actions
            Row(
              children: [
                Expanded(child: _actionBtn('Write Note', Icons.edit_note_outlined, () => _openNoteSheet(patient))),
                const Gap(12),
                Expanded(child: _actionBtn('Raise Concern', Icons.help_outline, () => _triggerConcern(patient))),
              ],
            ),
            const Gap(16),

            if (patient.attendanceStatus == 'Pending') ...[
              Row(
                children: [
                   Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: AppTheme.divider)),
                      onPressed: () {
                         final updated = patient.copyWith(attendanceStatus: 'Not_Attended');
                         ref.read(patientsProvider.notifier).updatePatient(updated);
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as Not Attended.')));
                      },
                      child: const Text('Not Attended', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                    )
                  ),
                  const Gap(16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.stable, padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () {
                         final updated = patient.copyWith(attendanceStatus: 'Attended');
                         ref.read(patientsProvider.notifier).updatePatient(updated);
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient Encounter Complete.')));
                      },
                      child: const Text('Mark Attended'),
                    )
                  ),
                ],
              ),
              const Gap(32),
            ],

            const Text('Clinical Assessment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const Gap(16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Vitals Summary', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    const Gap(8),
                    Text(patient.vitalsSummary, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  ],
                ),
              ),
            ),
            const Gap(32),

            const Text('Clinical Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const Gap(16),
            if (patient.notes.isEmpty)
              const Text('No notes appended.', style: TextStyle(color: AppTheme.textSecondary))
            else
              ...patient.notes.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
                  child: Text(n, style: const TextStyle(color: AppTheme.textPrimary)),
                ),
              )),
              
            const Gap(100),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String title, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
      child: Text(title, style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _actionBtn(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
        child: Column(
          children: [
             Icon(icon, color: AppTheme.primary),
             const Gap(8),
             Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }
}
