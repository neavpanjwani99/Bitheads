import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../app/theme.dart';
import '../../mock/mock_data.dart';
import '../../mock/concerns_provider.dart';
import '../../mock/announcements_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/work_history_provider.dart';
import '../../providers/resources_provider.dart';
import '../../providers/clinical_status_providers.dart';
import '../../widgets/mass_casualty_banner.dart';

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
    final massCasualty = ref.watch(massCasualtyProvider);
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
          Expanded(child: _currentIndex == 0 ? _buildDashboardBody() : const Center(child: Text('Bed Tracker Module Placeholder'))),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) {
          if (idx == 1) {
            context.push('/beds'); // External route for full Bed Tracker 
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
  }

  Widget _buildDashboardBody() {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const Center(child: CircularProgressIndicator());

    final updatedStaff = ref.watch(staffProvider).firstWhere((s) => s.uid == currentUser.uid, orElse: () => currentUser);
    final allConcerns = ref.watch(concernsProvider).where((c) => c.status == 'Pending').toList();
    final announcements = ref.watch(announcementsProvider).where((a) => a.isActive).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
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
              _buildAvailToggle(updatedStaff.available, () => ref.read(staffProvider.notifier).toggleAvailability(updatedStaff.uid, !updatedStaff.available)),
            ],
          ),
          const Gap(16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChip('Ward B'), const Gap(8),
                _buildChip('Pediatric'), const Gap(8),
                _buildChip('ICU Support'),
              ],
            ),
          ),
          const Gap(32),

          if (announcements.isNotEmpty) ...[
            ...announcements.map((a) => _buildAnnouncementBanner(a)),
            const Gap(16),
          ],



          // CONCERNS SECTION
          if (allConcerns.isNotEmpty) ...[
            const Text('Help Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const Gap(16),
            ...allConcerns.map((c) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: c.priority == 'Urgent' ? AppTheme.urgent : AppTheme.divider)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${c.doctorName} • ${c.patientName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (c.priority == 'Urgent')
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppTheme.urgent, borderRadius: BorderRadius.circular(12)), child: const Text('URGENT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const Gap(8),
                    Text(c.type, style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.primaryDark)),
                    Text(c.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    const Gap(16),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: (){ 
                          ref.read(concernsProvider.notifier).updateStatus(c.id, 'Declined', nurseId: currentUser.uid); 
                          ref.read(workHistoryProvider.notifier).addLogToCurrentShift('Concern from ${c.doctorName} — ${c.type} — Declined — ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}');
                        }, child: const Text('Decline', style: TextStyle(color: AppTheme.textSecondary)))),
                        const Gap(12),
                        Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.stable), onPressed: (){ 
                          ref.read(concernsProvider.notifier).updateStatus(c.id, 'Accepted', nurseId: currentUser.uid); 
                          ref.read(workHistoryProvider.notifier).addLogToCurrentShift('Concern from ${c.doctorName} — ${c.type} — Accepted — ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}');
                        }, child: const Text('Accept'))),
                      ],
                    )
                  ],
                ),
              ),
            )),
            const Gap(32),
          ],

          // MEDICATION TRACKER
          const Text('Medication Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const Gap(16),
          ...upcomingMeds.asMap().entries.where((e) => !e.value['given']).map((e) {
            DateTime time = e.value['time'];
            bool overdue = time.isBefore(DateTime.now());
            return Card(
              margin: const EdgeInsets.only(bottom: 8), 
              child: ListTile(
                leading: const Icon(Icons.vaccines_outlined, color: AppTheme.primary),
                title: Text('${e.value['patient']} — ${e.value['med']}', style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(overdue ? 'OVERDUE' : 'Scheduled: ${time.hour}:${time.minute.toString().padLeft(2, '0')}', 
                  style: TextStyle(color: overdue ? AppTheme.critical : AppTheme.textSecondary, fontWeight: overdue ? FontWeight.bold : FontWeight.normal)),
                trailing: IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: AppTheme.stable),
                  onPressed: () => _markMedGiven(e.key),
                ),
              ),
            );
          }),
          if (upcomingMeds.where((m) => !m['given']).isEmpty)
            const Text('No upcoming medications.', style: TextStyle(color: AppTheme.textSecondary)),
          
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


}

