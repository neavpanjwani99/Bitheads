import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../app/theme.dart';
import '../../mock/mock_data.dart';
import '../../mock/concerns_provider.dart';
import '../../mock/announcements_provider.dart';
import '../../widgets/chatbot_overlay.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medication completed.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Nursing Operations'),
        actions: [IconButton(icon: const Icon(Icons.logout_outlined), onPressed: () => context.go('/login'))],
      ),
      floatingActionButton: const ChatbotOverlay(),
      body: _currentIndex == 0 ? _buildDashboardBody() : const Center(child: Text('Bed Tracker Module Placeholder')),
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
                        Expanded(child: OutlinedButton(onPressed: (){ ref.read(concernsProvider.notifier).updateStatus(c.id, 'Declined'); }, child: const Text('Decline', style: TextStyle(color: AppTheme.textSecondary)))),
                        const Gap(12),
                        Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.stable), onPressed: (){ ref.read(concernsProvider.notifier).updateStatus(c.id, 'Accepted'); }, child: const Text('Accept'))),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _histItem('18 Apr', 'Shift: 08:00-16:00', '12 Patients • 6 Meds', '1 Tasks • 2m response'),
        _histItem('17 Apr', 'Shift: 08:00-16:00', '10 Patients • 4 Meds', '4 Tasks • 1m50s response'),
        _histItem('16 Apr', 'Shift: 08:00-16:00', '14 Patients • 8 Meds', '2 Tasks • 1m10s response'),
        _histItem('15 Apr', 'Shift: 08:00-16:00', '9 Patients • 5 Meds', '3 Tasks • N/A'),
        _histItem('14 Apr', 'Shift: 08:00-16:00', '12 Patients • 6 Meds', '5 Tasks • 45s response'),
      ],
    );
  }

  Widget _buildLoginHistory() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _histItem('Today, 07:45', 'Logout: --', 'Duration: Active', 'Device: Mobile (Android)'),
        _histItem('17 Apr, 07:55', 'Logout: 16:05', 'Duration: 8h 10m', 'Device: Mobile (Android)'),
        _histItem('16 Apr, 07:50', 'Logout: 16:15', 'Duration: 8h 25m', 'Device: Mobile (Android)'),
        _histItem('15 Apr, 07:48', 'Logout: 16:00', 'Duration: 8h 12m', 'Device: Mobile (Android)'),
        _histItem('14 Apr, 07:59', 'Logout: 16:05', 'Duration: 8h 06m', 'Device: Mobile (Android)'),
        _histItem('13 Apr, 07:44', 'Logout: 16:00', 'Duration: 8h 16m', 'Device: Mobile (Android)'),
        _histItem('12 Apr, 07:56', 'Logout: 16:20', 'Duration: 8h 24m', 'Device: Kiosk'),
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
