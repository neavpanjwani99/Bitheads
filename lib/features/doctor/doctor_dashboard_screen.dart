import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../app/theme.dart';
import '../../models/patient_model.dart';
import '../../models/staff_model.dart';
import '../../models/alert_model.dart';
import '../../mock/concerns_provider.dart';
import '../../mock/announcements_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/firestore_providers.dart';
import '../../services/firestore_service.dart';
import '../../models/clinical_request_model.dart';
import '../alerts/widgets/alert_card.dart';
import '../../providers/clinical_status_providers.dart';
import '../../widgets/mass_casualty_banner.dart';
import '../../mock/announcements_provider.dart';
import '../../providers/session_provider.dart';

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _logTabController;

  @override
  void initState() {
    super.initState();
    _logTabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authNotifierProvider);
    if (currentUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final staffAsync = ref.watch(realStaffProvider);
    final updatedStaff = staffAsync.asData?.value.firstWhere((s) => s.uid == currentUser.uid, orElse: () => currentUser) ?? currentUser;

    final deptsAsync = ref.watch(realDepartmentsProvider);
    final isDrillActive = deptsAsync.asData?.value.any((d) => d.name == updatedStaff.specialization && d.isDrillActive) ?? false;

    final patientsAsync = ref.watch(realPatientsProvider);
    final alertsAsync = ref.watch(realAlertsProvider);
    final announcements = ref.watch(announcementsProvider).where((a) => a.isActive).toList();
    final massCasualty = ref.watch(massCasualtyProvider);
    ref.watch(secondTickerProvider); 

    return patientsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (allPatients) {
        final myPatients = allPatients.where((p) => p.assignedStaffId == currentUser.uid).toList();
        final activePatients = myPatients.where((p) => 
          p.attendanceStatus == 'Incoming' || 
          p.attendanceStatus == 'Triaging' || 
          p.attendanceStatus == 'Pending'
        ).toList();
        activePatients.sort((a,b) => b.riskScore.compareTo(a.riskScore));
        final completedPatients = myPatients.where((p) => p.attendanceStatus == 'Attended').toList();

        return alertsAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
          data: (allAlerts) {
            final alerts = allAlerts.where((a) {
              final isHardcoded = a.id.startsWith('ALERT-');
              return (a.target == 'All Staff' || a.target == 'Doctors Only') && a.status != 'Resolved' && !isHardcoded;
            }).toList();
            
            return Scaffold(
              backgroundColor: AppTheme.background,
              appBar: AppBar(
                title: const Text('Physician Portal'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout_outlined), 
                    onPressed: () {
                      ref.read(sessionProvider.notifier).endSession();
                      context.go('/login');
                    }
                  )
                ],
              ),
              body: Stack(
                children: [
                  Column(
                    children: [
                      if (massCasualty) const MassCasualtyBanner(),
                      if (updatedStaff.activeNudge != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          color: Colors.orange,
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.white),
                              const Gap(12),
                              Expanded(child: Text('NUDGE: ${updatedStaff.activeNudge}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                onPressed: () => ref.read(firestoreServiceProvider).sendNudge(updatedStaff.uid, null),
                              )
                            ],
                          ),
                        ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(backgroundColor: AppTheme.primaryLight, radius: 24, child: Text(updatedStaff.name.substring(0,1), style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold))),
                                  const Gap(16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(updatedStaff.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                                        Text('${updatedStaff.hospitalId} • ${updatedStaff.specialization}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  _buildAvailToggle(updatedStaff.available, () => ref.read(firestoreServiceProvider).toggleAvailability(updatedStaff.uid, !updatedStaff.available)),
                                ],
                              ),
                          const Gap(32),
                          _buildGlobalConcernBanner(currentUser.uid),
                          if (announcements.isNotEmpty) ...[
                            ...announcements.map((a) => _buildAnnouncementBanner(a)),
                            const Gap(16),
                          ],
                          Row(
                            children: [
                              Expanded(child: _actionBtn('Start Triage', Icons.medical_services_outlined, () => _showTriageSelection(context))),
                              const Gap(12),
                              Expanded(child: _actionBtn('Raise Concern', Icons.help_outline, () => _showConcernSheet(context, activePatients))),
                            ],
                          ),
                          const Gap(32),
                          const Text('Assigned Patients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                          const Gap(16),
                          if (activePatients.isEmpty)
                             const Text('No assigned patients currently pending.', style: TextStyle(color: AppTheme.textSecondary))
                          else
                            for (final p in activePatients) _buildPatientCard(p, context),
                          const Gap(32),
                          const Text('Active Dispatch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                          const Gap(16),
                          if (alerts.isEmpty)
                            const Text('All clear.', style: TextStyle(color: AppTheme.textSecondary))
                          else
                            for (final alert in alerts)
                              AlertCard(alert: alert, onTap: () => context.push('/alerts/${alert.id}')),
                          const Gap(32),
                          const Text('Operations Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                          const Gap(16),
                          Card(
                            child: Column(
                              children: [
                                TabBar(
                                  controller: _logTabController,
                                  labelColor: AppTheme.primary,
                                  unselectedLabelColor: AppTheme.textSecondary,
                                  indicatorColor: AppTheme.primary,
                                  tabs: const [Tab(text: 'Work Shift'), Tab(text: 'System Logins')],
                                ),
                                SizedBox(
                                  height: 250,
                                  child: TabBarView(
                                    controller: _logTabController,
                                    children: [
                                      _buildWorkHistory(completedPatients),
                                      _buildLoginHistory(),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              if (isDrillActive)
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 10)),
                    child: Center(
                      child: Opacity(
                        opacity: 0.1,
                        child: Transform.rotate(
                          angle: -0.5,
                          child: const Text('DRILL MODE', style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildAvailToggle(bool isAvail, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isAvail ? AppTheme.stableLight : AppTheme.divider, borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            Icon(isAvail ? Icons.check_circle_outline : Icons.do_not_disturb_outlined, size: 16, color: isAvail ? AppTheme.stable : AppTheme.textSecondary),
            const Gap(6),
            Text(isAvail ? 'On Duty' : 'Busy', style: TextStyle(color: isAvail ? AppTheme.stable : AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
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

  void _showConcernSheet(BuildContext context, List<PatientModel> patients) {
    String? selPat;
    String pty = 'Normal';
    String typ = 'Medication Check';
    String desc = '';
    
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.surface, builder: (c) {
      return StatefulBuilder(builder: (ctx, setState) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Raise Concern to Nursing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const Gap(16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Related Patient'),
                  value: selPat,
                  items: patients.map((p)=>DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                  onChanged: (v)=>setState(()=>selPat=v)
                ),
                const Gap(12),
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
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async {
                  if(selPat != null && desc.isNotEmpty) {
                    final curr = ref.read(authNotifierProvider);
                    final pat = patients.firstWhere((p)=>p.id==selPat);
                    
                    final newRequest = ClinicalRequestModel(
                      id: '',
                      patientId: pat.id,
                      patientName: pat.name,
                      doctorId: curr?.uid ?? '',
                      doctorName: curr?.name ?? 'Doctor',
                      type: 'CONCERN',
                      description: desc,
                      status: 'PENDING',
                      priority: pty.toUpperCase(),
                      createdAt: DateTime.now(),
                      assignedNurseId: pat.assignedNurseId,
                    );
                    
                    await ref.read(firestoreServiceProvider).addClinicalRequest(newRequest);
                    
                    if (c.mounted) {
                      Navigator.pop(c);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Concern dispatched to Nursing.')));
                    }
                  }
                }, child: const Text('Submit Concern'))),
                const Gap(32),
              ],
            ),
          ),
        );
      });
    });
  }

  Widget _buildPatientCard(PatientModel p, BuildContext context) {
    Color riskColor = p.riskScore > 70 ? AppTheme.critical : (p.riskScore > 30 ? AppTheme.urgent : AppTheme.stable);

    // Golden Hour logic
    int remaining = 0;
    if (p.triageLevel == 'CRITICAL') {
      remaining = ref.read(goldenHourProvider.notifier).getRemainingSeconds(p.id);
      if (remaining == 0 && !ref.read(goldenHourProvider).containsKey(p.id)) {
        Future.microtask(() => ref.read(goldenHourProvider.notifier).start(p.id, DateTime.now()));
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: riskColor.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: riskColor.withValues(alpha: 0.1), width: 1)),
      child: InkWell(
        onTap: () => context.push('/patients/${p.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
                        Text('${p.age}, ${p.gender}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: riskColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('Score: ${p.riskScore}', style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
              const Gap(16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    // Status Badge - If not triaged, show 'INCOMING' or similar
                    if (p.triagedBy == null)
                      _statusBadge('PENDING TRIAGE', AppTheme.textSecondary)
                    else
                      _statusBadge(p.triageLevel, p.triageLevel == 'CRITICAL' ? AppTheme.critical : (p.triageLevel == 'URGENT' ? AppTheme.urgent : AppTheme.stable)),
                    
                    // Timer - ONLY after triage AND only if CRITICAL
                    if (p.triagedBy != null && p.triageLevel == 'CRITICAL' && remaining > 0) ...[
                      const Gap(12),
                      const Icon(Icons.timer_outlined, size: 16, color: AppTheme.urgent),
                      const Gap(4),
                      Text(
                        '${(remaining ~/ 60).toString().padLeft(2,'0')}:${(remaining % 60).toString().padLeft(2,'0')}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.urgent),
                      ),
                    ],
                    const Spacer(),
                    const Icon(Icons.meeting_room_outlined, size: 16, color: AppTheme.textSecondary),
                    const Gap(6),
                    Text(p.assignedBedId ?? 'UNASSIGNED', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
    );
  }

  Widget _buildWorkHistory(List<PatientModel> completedPatients) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (completedPatients.isNotEmpty)
          ...completedPatients.map((p) => _histItem(
            'Today', 
            'Patient: ${p.name}', 
            p.attendanceStatus == 'Attended' ? 'Consult Completed' : 'Not Attended', 
            'Status: ${p.attendanceStatus}'
          )),
        if (completedPatients.isEmpty)
          const Text('No patients attended today.', style: TextStyle(color: AppTheme.textSecondary)),
        const Gap(16),
        _histItem('18 Apr', 'Shift: 08:00-16:00', '12 Patients seen', '3 Alerts handled • 1m response'),
        _histItem('17 Apr', 'Shift: 08:00-16:00', '14 Patients seen', '2 Alerts handled • 1m20s response'),
      ],
    );
  }

  Widget _buildLoginHistory() {
    final sessions = ref.watch(sessionProvider);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final isToday = session.loginTime.day == DateTime.now().day;
        final dateStr = isToday ? 'Today, ' : '${session.loginTime.day} Apr, ';
        final loginTimeStr = '${session.loginTime.hour.toString().padLeft(2,'0')}:${session.loginTime.minute.toString().padLeft(2,'0')}';
        final logoutTimeStr = session.logoutTime == null ? '--' : '${session.logoutTime!.hour.toString().padLeft(2,'0')}:${session.logoutTime!.minute.toString().padLeft(2,'0')}';
        
        return _histItem(
          '$dateStr$loginTimeStr', 
          'Logout: $logoutTimeStr', 
          'Duration: ${session.duration}', 
          'Device: ${session.device}'
        );
      },
    );
  }

  Widget _histItem(String t1, String t2, String t3, String t4) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.divider))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t1, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            Text(t2, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(t3, style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
            Text(t4, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ]),
        ],
      ),
    );
  }

  Widget _buildAnnouncementBanner(AnnouncementModel a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: a.isPriority ? AppTheme.criticalLight : AppTheme.urgentLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: a.isPriority ? AppTheme.critical : AppTheme.urgent)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.campaign_outlined, color: a.isPriority ? AppTheme.critical : AppTheme.urgent),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: TextStyle(fontWeight: FontWeight.w600, color: a.isPriority ? AppTheme.critical : AppTheme.urgent)),
                Text(a.message, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
              ],
            )
          )
        ],
      ),
    );
  }


  Widget _buildGlobalConcernBanner(String doctorId) {
    final requestsAsync = ref.watch(realClinicalRequestsProvider);
    return requestsAsync.when(
      data: (allReqs) {
        final pendingConcerns = allReqs.where((r) => 
          r.doctorId == doctorId && 
          r.type == 'CONCERN' && 
          r.status == 'PENDING'
        ).toList();

        if (pendingConcerns.isEmpty) return const SizedBox.shrink();

        return Column(
          children: pendingConcerns.map((c) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.critical.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.critical.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.critical, size: 24),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Active Request: CONCERN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.critical)),
                      Text(
                        'Waiting for Nursing to complete: "${c.description}" (Patient: ${c.patientName})',
                        style: TextStyle(fontSize: 12, color: AppTheme.critical.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showTriageSelection(BuildContext context) {
    final incomingAsync = ref.watch(realIncomingPatientsProvider);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
                  ),
                  const Gap(24),
                  const Text('Select Patient for Triage', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const Gap(8),
                  const Text('Select an admitted patient to start clinical assessment.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  const Gap(24),
                  Expanded(
                    child: incomingAsync.when(
                      data: (incoming) {
                        if (incoming.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_search_outlined, size: 64, color: AppTheme.divider),
                                const Gap(16),
                                const Text('No patients in Incoming Queue', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                                const Gap(24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(c);
                                      context.push('/triage');
                                    },
                                    child: const Text('Start Emergency Triage'),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          controller: scrollController,
                          itemCount: incoming.length + 1,
                          separatorBuilder: (_, __) => const Gap(12),
                          itemBuilder: (context, index) {
                            if (index == incoming.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0, bottom: 24),
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16), side: const BorderSide(color: AppTheme.primary)),
                                  onPressed: () {
                                    Navigator.pop(c);
                                    context.push('/triage');
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Triage New Patient'),
                                ),
                              );
                            }
                            final p = incoming[index];
                            return Container(
                              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.5),
                                  child: Text(p.name.substring(0,1), style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Gap(4),
                                    Text('${p.age} yrs • ${p.gender}', style: const TextStyle(fontSize: 13)),
                                    const Gap(2),
                                    Text(p.vitalsSummary, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right, color: AppTheme.divider),
                                onTap: () async {
                                  await ref.read(firestoreServiceProvider).updatePatientFields(p.id, {
                                    'attendanceStatus': 'Triaging',
                                    'triagedBy': ref.read(authNotifierProvider)?.name ?? 'Doctor',
                                    'triagedByRole': 'Doctor',
                                  });
                                  if (context.mounted) {
                                    Navigator.pop(c);
                                    context.push('/triage?id=${p.id}&name=${Uri.encodeComponent(p.name)}&age=${p.age}&gender=${Uri.encodeComponent(p.gender)}');
                                  }
                                },
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }
}

