import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/theme.dart';
import '../../models/patient_model.dart';
import '../../models/bed_model.dart';
import '../../models/alert_model.dart';
import '../../models/staff_model.dart';
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
import '../../providers/work_history_provider.dart';

class NurseDashboardScreen extends ConsumerStatefulWidget {
  const NurseDashboardScreen({super.key});

  @override
  ConsumerState<NurseDashboardScreen> createState() => _NurseDashboardScreenState();
}

class _NurseDashboardScreenState extends ConsumerState<NurseDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _logTabController;
  int _currentIndex = 0;
  
  // Mock Medication List
  final List<Map<String, dynamic>> upcomingMeds = [
    {'patient': 'Ravi M.', 'med': 'Paracetamol 500mg', 'time': DateTime.now().add(const Duration(minutes: -5)), 'given': false},
    {'patient': 'Meera S.', 'med': 'Insulin', 'time': DateTime.now().add(const Duration(minutes: 45)), 'given': false},
  ];

  @override
  void initState() {
    super.initState();
    _logTabController = TabController(length: 2, vsync: this);
  }

  void _markMedGiven(int index) {
    setState(() {
      upcomingMeds[index]['given'] = true;
    });
    ref.read(workHistoryProvider.notifier).addLogToCurrentShift('Administered Med: ${upcomingMeds[index]['med']} to ${upcomingMeds[index]['patient']}');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medication completed.')));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authNotifierProvider);
    if (currentUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final patientsAsync = ref.watch(realPatientsProvider);
    final alertsAsync = ref.watch(realAlertsProvider);
    final bedsAsync = ref.watch(realBedsProvider);
    
    final massCasualty = ref.watch(massCasualtyProvider);
    
    return patientsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (allPatients) {
        final activePatients = allPatients.where((p) {
          final isDue = p.nextVitalsTime == null || 
              DateTime.now().isAfter(p.nextVitalsTime!);
          
          return (p.attendanceStatus == 'Incoming' || 
                  p.attendanceStatus == 'Triaging' || 
                  p.attendanceStatus == 'Pending') && isDue;
        }).toList();
        activePatients.sort((a,b) => b.riskScore.compareTo(a.riskScore));
        final completedPatients = allPatients.where((p) => p.attendanceStatus == 'Attended').toList();
        
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Nursing Operations'),
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
          body: Column(
            children: [
              if (massCasualty) const MassCasualtyBanner(),
              Expanded(child: _currentIndex == 0 ? _buildDashboardBody(currentUser, activePatients, alertsAsync) : _buildBedTracker(bedsAsync)),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (idx) {
              if (idx == 1) {
                context.push('/beds'); 
              } else {
                setState(() => _currentIndex = idx);
              }
            },
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: AppTheme.textSecondary,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.bed_outlined), label: 'Beds'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNursePatientCard(PatientModel p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Triage: ${p.triageLevel} • Risk: ${p.riskScore}'),
        trailing: ElevatedButton(
          onPressed: () => _showVitalsSheet(p),
          child: const Text('Vitals'),
        ),
      ),
    );
  }

  void _showVitalsSheet(PatientModel p) {
    int hr = p.vitalsTrend.isNotEmpty ? p.vitalsTrend.last : 75;
    int bp = 120;
    double temp = 98.6;
    
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.surface, builder: (c) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Update Vitals for ${p.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Gap(16),
            TextField(keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Heart Rate (bpm)'), onChanged: (v)=>hr=int.tryParse(v)??hr),
            const Gap(12),
            TextField(keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Systolic BP (mmHg)'), onChanged: (v)=>bp=int.tryParse(v)??bp),
            const Gap(12),
            TextField(keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Temperature (°F)'), onChanged: (v)=>temp=double.tryParse(v)??temp),
            const Gap(24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async {
              final List<int> newTrend = [...p.vitalsTrend, hr];
              if (newTrend.length > 5) newTrend.removeAt(0);
              
              int cooldownMins = 60; // Default stable
              if (p.triageLevel == 'CRITICAL') cooldownMins = 15;
              if (p.triageLevel == 'URGENT') cooldownMins = 30;

              final updated = {
                'vitalsTrend': newTrend,
                'vitalsSummary': 'Temp: ${temp.toStringAsFixed(1)}°F, BP: $bp/80, HR: $hr',
                'lastVitalsTime': Timestamp.fromDate(DateTime.now()),
                'lastNurseActionTime': Timestamp.fromDate(DateTime.now()),
                'nextVitalsTime': Timestamp.fromDate(DateTime.now().add(Duration(minutes: cooldownMins))),
              };
              
              await ref.read(firestoreServiceProvider).updatePatientFields(p.id, updated);
              if (context.mounted) {
                Navigator.pop(c);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vitals updated live!')));
              }
            }, child: const Text('Save Vitals'))),
            const Gap(32),
          ],
        ),
      );
    });
  }

  Widget _buildBedTracker(AsyncValue<List<BedModel>> bedsAsync) {
    return bedsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (beds) {
        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: beds.length,
          itemBuilder: (context, index) {
            final b = beds[index];
            final color = b.status == 'Available' ? AppTheme.stable : (b.status == 'Occupied' ? AppTheme.critical : AppTheme.urgent);
            return Container(
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.bed, color: color, size: 24),
                   const Gap(4),
                   Text(b.id, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
                   Text(b.status, style: TextStyle(color: color, fontSize: 8)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDashboardBody(StaffModel currentUser, List<PatientModel> activePatients, AsyncValue<List<AlertModel>> alertsAsync) {
    final staffAsync = ref.watch(realStaffProvider);
    final updatedStaff = staffAsync.asData?.value.firstWhere((s) => s.uid == currentUser.uid, orElse: () => currentUser) ?? currentUser;
    final announcements = ref.watch(announcementsProvider).where((a) => a.isActive).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: AppTheme.primaryLight, radius: 24, child: Text(updatedStaff.name.replaceAll('Nurse ', '').substring(0,1), style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold))),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(updatedStaff.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    Text('${updatedStaff.hospitalId} • Ward B, Fl 2', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              _buildAvailToggle(updatedStaff.available, () => ref.read(firestoreServiceProvider).toggleAvailability(updatedStaff.uid, !updatedStaff.available)),
            ],
          ),
          const Gap(32),

          if (announcements.isNotEmpty) ...[
            ...announcements.map((a) => _buildAnnouncementBanner(a)),
            const Gap(16),
          ],

          const Text('Active Monitoring', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const Gap(16),
          if (activePatients.isEmpty)
            const Text('No patients currently in your queue.', style: TextStyle(color: AppTheme.textSecondary))
          else
            for (final p in activePatients) _buildNursePatientCard(p),

          const Gap(32),
          const Text('Clinical Tasks & Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const Gap(16),
          ref.watch(realClinicalRequestsProvider).when(
            data: (allReqs) {
              final reqs = allReqs.where((r) => r.status == 'PENDING').toList();
              if (reqs.isEmpty) return const Text('No pending tasks from doctors.', style: TextStyle(color: AppTheme.textSecondary));
              return Column(
                children: reqs.map((r) => _buildClinicalTaskCard(r)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),

          const Gap(32),
          const Text('Active Dispatch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const Gap(16),
          alertsAsync.when(
            data: (allAlerts) {
              final alerts = allAlerts.where((a) {
                final isHardcoded = a.id.startsWith('ALERT-');
                return (a.target == 'All Staff' || a.target == 'Nurses Only') && a.status != 'Resolved' && !isHardcoded;
              }).toList();
              if (alerts.isEmpty) return const Text('All clear.', style: TextStyle(color: AppTheme.textSecondary));
              return Column(
                children: alerts.map((alert) => AlertCard(alert: alert, onTap: () => context.push('/alerts/${alert.id}'))).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),

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
                      _buildWorkHistory(),
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

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(16)),
      child: Text(label, style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _buildWorkHistory() {
    final history = ref.watch(workHistoryProvider);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final h = history[index];
        final title = index == 0 ? 'Today Shift' : '${h.date.day} Apr';
        final stats = '${h.patientsCount} Patients • ${h.medicationsGiven} Meds';
        
        final List<Widget> children = [
          _histItem(title, 'Shift: ${h.shift}', stats, '${h.logs.length} Tasks • ${h.avgResponseTime} response'),
        ];
        
        if (index == 0 && h.logs.isNotEmpty) {
          children.add(
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: h.logs.map((log) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.history, size: 12, color: AppTheme.primary),
                      const Gap(6),
                      Expanded(child: Text(log, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                )).toList(),
              ),
            )
          );
        }
        
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
      },
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

  Widget _buildClinicalTaskCard(ClinicalRequestModel r) {
    final color = r.type == 'ORDER' ? AppTheme.urgent : AppTheme.critical;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(r.type, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Text(
                DateFormat('HH:mm').format(r.createdAt),
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const Gap(12),
          Text(r.description, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
          const Gap(8),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary),
              const Gap(4),
              Text('Patient: ${r.patientName}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const Spacer(),
              Text('By ${r.doctorName}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontStyle: FontStyle.italic)),
            ],
          ),
          const Gap(16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await ref.read(firestoreServiceProvider).updateClinicalRequestStatus(r.id, 'COMPLETED');
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task marked as completed.')));
                }
              },
              child: const Text('Mark as Completed'),
            ),
          ),
        ],
      ),
    );
  }
}

