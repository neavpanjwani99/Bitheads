import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app/theme.dart';
import '../../mock/mock_data.dart';
import '../../models/patient_model.dart';
import '../../models/clinical_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../mock/concerns_provider.dart';
import '../../services/gemini_service.dart';
import '../../providers/clinical_status_providers.dart';
import '../../providers/firestore_providers.dart';
import '../../services/firestore_service.dart';
import 'widgets/ai_clinical_analysis_screen.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  ConsumerState<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen> {
  void _showAIAnalysis(BuildContext context, PatientModel patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AIClinicalAnalysisScreen(patient: patient),
    );
  }

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
                onPressed: () async {
                  if (noteText.isNotEmpty) {
                    final newNote = 'Note — ${DateFormat('HH:mm').format(DateTime.now())}: $noteText';
                    final updated = patient.copyWith(notes: [...patient.notes, newNote]);
                    await ref.read(firestoreServiceProvider).updatePatient(updated);
                    if (c.mounted) Navigator.pop(c);
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

  void _openOrderSheet(PatientModel patient) {
    String orderText = '';
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.background, builder: (c) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Clinical Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const Gap(8),
            const Text('Prescribe medications, labs, or imaging.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const Gap(16),
            TextField(
              maxLines: 3, decoration: const InputDecoration(hintText: 'e.g. Paracetamol 500mg IV STAT, Chest X-ray...'),
              onChanged: (v) => orderText = v,
            ),
            const Gap(16),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.urgent),
                onPressed: () async {
                    final user = ref.read(authNotifierProvider);
                    final newRequest = ClinicalRequestModel(
                      id: '',
                      patientId: patient.id,
                      patientName: patient.name,
                      doctorId: user?.uid ?? '',
                      doctorName: user?.name ?? 'Doctor',
                      type: 'ORDER',
                      description: orderText,
                      status: 'PENDING',
                      priority: 'NORMAL',
                      createdAt: DateTime.now(),
                    );
                    
                    await ref.read(firestoreServiceProvider).addClinicalRequest(newRequest);
                    
                    final updated = patient.copyWith(
                      orders: [...patient.orders, 'Order: $orderText (${DateFormat('HH:mm').format(DateTime.now())})'],
                      events: [...patient.events, {'type': 'ORDER', 'time': DateTime.now(), 'msg': 'Ordered: $orderText'}]
                    );
                    await ref.read(firestoreServiceProvider).updatePatientFields(patient.id, updated.toMap());
                    if (c.mounted) Navigator.pop(c);
                }, 
                child: const Text('Issue Order')
              )
            ),
            const Gap(24),
          ],
        ),
      );
    });
  }

  void _generateHandover(PatientModel patient) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (c) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const Gap(16),
            const Text('AI is analyzing patient context...', style: TextStyle(fontWeight: FontWeight.w500)),
            const Text('This may take a moment if servers are busy', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      )
    );

    final contextData = '''
Patient: ${patient.name} (${patient.age}y ${patient.gender})
Current Triage: ${patient.triageLevel}
Vitals History: ${patient.vitalsTrend.join(' -> ')}
Nursing Notes: ${patient.notes.join('\n- ')}
Medical Orders: ${patient.orders.join('\n- ')}
Recent Activity: ${patient.events.isNotEmpty ? patient.events.last['description'] : 'Stabilization in progress'}
''';

    try {
      final prompt = 'Generate a professional SBAR (Situation, Background, Assessment, Recommendation) handover summary for this patient:\n$contextData';
      final summary = await GeminiService.chat(userMessage: prompt, hospitalContext: 'Staff Handover Mode');

      if (!mounted) return;
      navigator.pop(); // Close loading dialog specifically

      _showHandoverResult(summary);
    } catch (e) {
       if (!mounted) return;
       navigator.pop();
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Handover generation failed: $e')));
    }
  }

  void _showHandoverResult(String summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      builder: (c) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assignment_ind_outlined, color: AppTheme.primary),
                Gap(12),
                const Text('AI Handover Summary (SBAR)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Gap(16),
            Flexible(
              child: SingleChildScrollView(
                child: Text(summary, style: const TextStyle(height: 1.5, color: AppTheme.textPrimary)),
              ),
            ),
            const Gap(16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () => Navigator.pop(c), child: const Text('Acknowledge')),
            ),
            const Gap(24),
          ],
        ),
      ),
    );
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
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () async {
                if(desc.isNotEmpty) {
                  final user = ref.read(authNotifierProvider);
                  final newRequest = ClinicalRequestModel(
                    id: '',
                    patientId: patient.id,
                    patientName: patient.name,
                    doctorId: user?.uid ?? '',
                    doctorName: user?.name ?? 'Doctor',
                    type: 'CONCERN',
                    description: desc,
                    status: 'PENDING',
                    priority: pty.toUpperCase(),
                    createdAt: DateTime.now(),
                  );
                  
                  await ref.read(firestoreServiceProvider).addClinicalRequest(newRequest);
                  
                  if (c.mounted) {
                    Navigator.pop(c);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Concern dispatched to Nursing.')));
                  }
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
    return ref.watch(realPatientsProvider).when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (patients) {
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Opacity(opacity: 0, child: Icon(Icons.timer)), // Spacer
                        CircleAvatar(backgroundColor: AppTheme.primaryLight, radius: 32, child: Text(patient.name.substring(0,1), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryDark))),
                        if (patient.triageLevel == 'CRITICAL')
                          _buildGoldenHourTimer(patient.id)
                        else
                          const Opacity(opacity: 0, child: Icon(Icons.timer)),
                      ],
                    ),
                    const Gap(12),
                    Text(patient.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    Text('${patient.age} yrs • ${patient.gender} • ID: ${patient.id}', style: const TextStyle(color: AppTheme.textSecondary)),
                    const Gap(16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBadge(patient.triageLevel, patient.triageLevel == 'CRITICAL' ? AppTheme.critical : (patient.triageLevel == 'URGENT' ? AppTheme.urgent : AppTheme.stable)),
                        const Gap(8),
                        _buildBadge(
                          'Risk Score: ${patient.riskScore}', 
                          patient.riskScore > 70 ? AppTheme.critical : (patient.riskScore > 30 ? AppTheme.urgent : AppTheme.stable)
                        ),
                      ],
                    ),
                    const Gap(16),
                    _buildPatientConcernStatus(patient.id),
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
                Expanded(child: _actionBtn('Create Order', Icons.receipt_long_outlined, () => _openOrderSheet(patient))),
              ],
            ),
            const Gap(12),
            Row(
              children: [
                Expanded(child: _actionBtn('Handover AI', Icons.shortcut_outlined, () => _generateHandover(patient))),
                const Gap(12),
                Expanded(child: _actionBtn('Raise Concern', Icons.help_outline, () => _triggerConcern(patient))),
              ],
            ),
            const Gap(16),

            const Gap(16),

            const Gap(16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  foregroundColor: AppTheme.primaryDark,
                  side: const BorderSide(color: AppTheme.primary),
                  elevation: 0,
                ),
                onPressed: () => _showAIAnalysis(context, patient),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('AI Clinical Synthesizer', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const Gap(32),

            const Text('Clinical Assessment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const Gap(16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Vitals Summary', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        Text('Status: ${patient.vitalStatus.toUpperCase()}', style: TextStyle(color: patient.vitalStatus == 'critical' ? AppTheme.critical : AppTheme.stable, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const Gap(8),
                    Text(patient.vitalsSummary, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                    const Gap(16),
                    const Text('Vitals Trend (Last 5)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    const Gap(8),
                    SizedBox(height: 60, child: _buildVitalsTrend(patient.vitalsTrend)),
                  ],
                ),
              ),
            ),
            const Gap(32),

            const Text('Active Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const Gap(16),
            if (patient.orders.isEmpty)
              const Text('No active orders.', style: TextStyle(color: AppTheme.textSecondary))
            else
              ...patient.orders.map((o) => _buildListItem(o, Icons.check_circle_outline, AppTheme.urgent)),
            const Gap(32),

            const Text('Patient Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const Gap(16),
            _buildTimeline(patient),
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
              
            if (patient.attendanceStatus == 'Pending') ...[
              const Gap(32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.stable,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    await ref.read(firestoreServiceProvider).updatePatientFields(patient.id, {
                      'attendanceStatus': 'Attended',
                      'nextVitalsTime': null, // Clear scheduling
                    });
                    
                    // FREE THE BED
                    if (patient.assignedBedId != null) {
                      await ref.read(firestoreServiceProvider).updateBedStatus(
                        patient.assignedBedId!, 
                        'Available',
                        patientId: null,
                        patientName: null,
                      );
                    }

                    if (context.mounted) {
                      context.pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient care completed and archived. Bed is now available.')));
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline),
                      Gap(12),
                      Text('Mark Care as Completed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
            const Gap(100),
          ],
        ),
      ),
    );
  },
);
}

  Widget _buildTimeline(PatientModel p) {
    // Combine notes, triage (start), and events
    final List<Map<String, dynamic>> items = [
      {'type': 'TRIAGE', 'time': p.lastVitalsTime ?? DateTime.now().subtract(const Duration(hours: 4)), 'msg': 'Patient admitted via triage.'},
      ...p.events,
    ];
    
    // Fix Timestamp conversion for events from Firestore
    for (var item in items) {
      if (item['time'] is Timestamp) {
        item['time'] = (item['time'] as Timestamp).toDate();
      }
    }

    items.sort((a,b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));

    if (items.isEmpty) return const Text('Timeline empty.', style: TextStyle(color: AppTheme.textSecondary));

    return Column(
      children: items.map((e) => _buildTimelineItem(e)).toList(),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle, border: Border.all(color: AppTheme.surface, width: 2)),
              ),
              Container(width: 2, height: 40, color: AppTheme.divider),
            ],
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('HH:mm').format(e['time']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primary)),
                Text(e['msg'], style: const TextStyle(fontSize: 14)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildVitalsTrend(List<int> trend) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: trend.reduce((a, b) => a < b ? a : b).toDouble() - 5,
        maxY: trend.reduce((a, b) => a > b ? a : b).toDouble() + 5,
        lineBarsData: [
          LineChartBarData(
            spots: trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
            isCurved: true,
            color: AppTheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: AppTheme.primary.withValues(alpha: 0.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldenHourTimer(String patientId) {
    ref.watch(secondTickerProvider); // Rebuild every second
    final remaining = ref.read(goldenHourProvider.notifier).getRemainingSeconds(patientId);
    
    // If it's a critical patient and timer hasn't started, start it
    if (remaining == 0 && !ref.read(goldenHourProvider).containsKey(patientId)) {
      Future.microtask(() => ref.read(goldenHourProvider.notifier).start(patientId, DateTime.now()));
    }

    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    
    Color c = remaining > 1800 ? AppTheme.stable : (remaining > 600 ? AppTheme.urgent : AppTheme.critical);

    return Column(
      children: [
        Icon(Icons.timer_outlined, color: c, size: 20),
        Text(timeStr, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
        const Text('GOLDEN HOUR', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPatientConcernStatus(String patientId) {
    final clinicalReqsAsync = ref.watch(realClinicalRequestsProvider);
    return clinicalReqsAsync.when(
      data: (allReqs) {
        final reqs = allReqs.where((r) => r.patientId == patientId && r.status == 'PENDING').toList();
        if (reqs.isEmpty) return const SizedBox.shrink();

        final r = reqs.first;
        Color statusColor = r.type == 'ORDER' ? AppTheme.urgent : AppTheme.critical;

        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: statusColor, size: 18),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active Request: ${r.type}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: statusColor)),
                    Text(
                      'Waiting for Nursing to complete: "${r.description}"',
                      style: TextStyle(fontSize: 12, color: statusColor.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildListItem(String text, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const Gap(12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
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
