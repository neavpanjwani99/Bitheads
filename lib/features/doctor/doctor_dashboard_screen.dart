import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../app/theme.dart';
import '../../mock/mock_data.dart';
import '../../mock/concerns_provider.dart';
import '../../mock/announcements_provider.dart';
import '../../models/patient_model.dart';
import '../../widgets/chatbot_overlay.dart';
import '../alerts/widgets/alert_card.dart';

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
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final updatedStaff = ref.watch(staffProvider).firstWhere((s) => s.uid == currentUser.uid, orElse: () => currentUser);
    final alerts = ref.watch(alertsProvider).where((a) => a.target == 'All Staff' || a.target == 'Doctors Only').toList();
    final announcements = ref.watch(announcementsProvider).where((a) => a.isActive).toList();
    
    List<PatientModel> allMyPatients = ref.watch(patientsProvider).where((p) => p.assignedStaffId == currentUser.uid).toList();
    List<PatientModel> activePatients = allMyPatients.where((p) => p.attendanceStatus == 'Pending').toList();
    activePatients.sort((a,b) => b.riskScore.compareTo(a.riskScore));
    
    // For work history logic
    List<PatientModel> completedPatients = allMyPatients.where((p) => p.attendanceStatus != 'Pending').toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Physician Portal'),
        actions: [IconButton(icon: const Icon(Icons.logout_outlined), onPressed: () => context.go('/login'))],
      ),
      floatingActionButton: const ChatbotOverlay(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
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
                _buildAvailToggle(updatedStaff.available, () => ref.read(staffProvider.notifier).toggleAvailability(updatedStaff.uid, !updatedStaff.available)),
              ],
            ),
            const Gap(32),

            if (announcements.isNotEmpty) ...[
              ...announcements.map((a) => _buildAnnouncementBanner(a)),
              const Gap(16),
            ],

            Row(
              children: [
                Expanded(child: _actionBtn('Start Triage', Icons.medical_services_outlined, () => context.push('/triage'))),
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
            const Gap(100),
          ],
        ),
      ),
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
                  items: patients.map((p)=>DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                  onChanged: (v)=>selPat=v
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
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: (){
                  if(selPat != null && desc.isNotEmpty) {
                    final curr = ref.read(currentUserProvider);
                    final pat = patients.firstWhere((p)=>p.id==selPat);
                    ref.read(concernsProvider.notifier).addConcern(ConcernModel(
                      id: 'C${DateTime.now().millisecondsSinceEpoch}',
                      doctorId: curr!.uid, doctorName: curr.name,
                      patientId: pat.id, patientName: pat.name,
                      type: typ, description: desc, priority: pty,
                      timeReceived: DateTime.now()
                    ));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Concern dispatched to Nursing.')));
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/patients/${p.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${p.name}, ${p.age}${p.gender}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  Text('Score: ${p.riskScore}', style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const Gap(8),
              Row(
                children: [
                  Text(p.triageLevel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.triageLevel == 'CRITICAL' ? AppTheme.critical : AppTheme.textSecondary)),
                  const Text(' • ', style: TextStyle(color: AppTheme.textSecondary)),
                  Text('${p.assignedBedId}', style: const TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _histItem('Today, 07:55', 'Logout: --', 'Duration: Active', 'Device: Mobile (iOS)'),
        _histItem('17 Apr, 07:45', 'Logout: 16:10', 'Duration: 8h 25m', 'Device: Mobile (iOS)'),
        _histItem('16 Apr, 07:50', 'Logout: 16:00', 'Duration: 8h 10m', 'Device: Mobile (iOS)'),
        _histItem('15 Apr, 07:58', 'Logout: 16:15', 'Duration: 8h 17m', 'Device: Mobile (iOS)'),
        _histItem('14 Apr, 07:52', 'Logout: 16:05', 'Duration: 8h 13m', 'Device: Mobile (iOS)'),
        _histItem('13 Apr, 07:44', 'Logout: 16:00', 'Duration: 8h 16m', 'Device: Mobile (iOS)'),
        _histItem('12 Apr, 07:56', 'Logout: 16:20', 'Duration: 8h 24m', 'Device: Mobile (Android)'),
      ],
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
}
