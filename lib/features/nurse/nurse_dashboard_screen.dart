import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../app/theme.dart';
import '../../mock/mock_data.dart';
import '../../models/patient_model.dart';
import '../alerts/widgets/alert_card.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class NurseDashboardScreen extends ConsumerStatefulWidget {
  const NurseDashboardScreen({super.key});

  @override
  ConsumerState<NurseDashboardScreen> createState() => _NurseDashboardScreenState();
}

class _NurseDashboardScreenState extends ConsumerState<NurseDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Mock Medication List
  final List<Map<String, dynamic>> upcomingMeds = [
    {'patient': 'Ravi M.', 'med': 'Paracetamol 500mg', 'time': DateTime.now().add(const Duration(minutes: -5)), 'given': false}, // Overdue
    {'patient': 'Meera S.', 'med': 'Insulin', 'time': DateTime.now().add(const Duration(minutes: 45)), 'given': false},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initNotifications();
  }
  
  Future<void> _initNotifications() async {
    try {
      tz.initializeTimeZones();
      // await flutterLocalNotificationsPlugin.initialize(initializationSettings: initializationSettings);
    } catch (e) {
      // Ignore web initialization crash for demo
    }
  }

  void _markMedGiven(int index) {
    // flutterLocalNotificationsPlugin.cancel(id: index);
    setState(() {
      upcomingMeds[index]['given'] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medication Marked Given')));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final updatedStaff = ref.watch(staffProvider).firstWhere((s) => s.uid == currentUser.uid, orElse: () => currentUser);
    final alerts = ref.watch(alertsProvider).where((a) => a.target == 'All Staff' || a.target == 'Nurses Only').toList();
    final patients = ref.watch(patientsProvider).where((p) => p.assignedStaffId == currentUser.uid).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Nurse Operations', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: AppTheme.textPrimary), onPressed: () => context.go('/login')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HEADER
            Text('Good morning,\n${updatedStaff.name.replaceAll('Nurse ', '')} 👋', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28, color: const Color(0xFF1C1C2E))),
            const Gap(8),
            Text('Senior Nurse — Ward B, Floor 2', style: const TextStyle(color: Color(0xFF5F6368), fontSize: 16)),
            const Gap(12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip('🏥 Ward B'), const Gap(8),
                  _buildChip('👶 Pediatric'), const Gap(8),
                  _buildChip('🔴 ICU Support'),
                ],
              ),
            ),
            const Gap(16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
              child: Row(
                children: [
                  const Icon(Icons.watch_later_outlined, size: 16, color: AppTheme.primary),
                  const Gap(8),
                  const Text('Shift: 08:00 — 20:00', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const Text('Attending: Ravi M., +2', style: TextStyle(color: Color(0xFF5F6368))),
                ],
              ),
            ),
            const Gap(24),
            
            // CODE BLUE
            SizedBox(
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.critical, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  ref.read(alertsProvider.notifier).addCodeBlue(updatedStaff);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CODE BLUE SENT ✓'), backgroundColor: AppTheme.critical, duration: Duration(seconds: 3)));
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning, color: Colors.white, size: 28), Gap(12),
                    Text('🚨 CODE BLUE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                  ],
                ),
              ),
            ),
            const Gap(24),
            
            // AVAILABILITY TOGGLE
            GestureDetector(
              onTap: () => ref.read(staffProvider.notifier).toggleAvailability(updatedStaff.uid, !updatedStaff.available),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(color: updatedStaff.available ? AppTheme.stable : Colors.grey.shade400, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Icon(updatedStaff.available ? Icons.check_circle : Icons.do_not_disturb, size: 40, color: Colors.white),
                    const Gap(8),
                    Text(updatedStaff.available ? 'Available for Assignment' : 'Offline / Busy', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const Gap(32),

            // MEDICATION TRACKER
            const Text('Medication Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1C1C2E))),
            const Gap(16),
            ...upcomingMeds.asMap().entries.where((e) => !e.value['given']).map((e) {
              DateTime time = e.value['time'];
              bool overdue = time.isBefore(DateTime.now());
              return Card(
                color: Colors.white, margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.medication, color: AppTheme.primary),
                  title: Text('${e.value['patient']} — ${e.value['med']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(overdue ? 'OVERDUE' : 'Scheduled: ${time.hour}:${time.minute.toString().padLeft(2, '0')}', 
                    style: TextStyle(color: overdue ? AppTheme.critical : Colors.black54, fontWeight: overdue ? FontWeight.bold : FontWeight.normal)),
                  trailing: IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: AppTheme.stable),
                    onPressed: () => _markMedGiven(e.key),
                  ),
                ),
              );
            }),
            if (upcomingMeds.where((m) => !m['given']).isEmpty)
              const Text('No upcoming medications.', style: TextStyle(color: Color(0xFF5F6368))),
            
            const Gap(32),
            const Text('Operations Log', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1C1C2E))),
            const Gap(16),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: const Color(0xFF5F6368),
                    indicatorColor: AppTheme.primary,
                    tabs: const [Tab(text: 'Patients'), Tab(text: 'Shifts'), Tab(text: 'Tasks')],
                  ),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPatientHistory(),
                        _buildShiftHistory(),
                        _buildTaskHistory(),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const Gap(120),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'handoffBtn',
            backgroundColor: AppTheme.urgent,
            onPressed: () => _startHandoff(context),
            icon: const Icon(Icons.note_alt, color: Colors.white),
            label: const Text('Start Handoff', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const Gap(16),
          FloatingActionButton.extended(
            heroTag: 'bedsBtn',
            backgroundColor: AppTheme.primary,
            onPressed: () => _showBedStatusSheet(context),
            icon: const Icon(Icons.bed, color: Colors.white),
            label: const Text('Manage Beds', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
      child: Text(label, style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildPatientHistory() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _historyItem('John Doe', 'Discharged', 'Stable • 4 days care'),
        _historyItem('Ananya P.', 'Transferred', 'Critical • ICU move'),
        _historyItem('Raj M.', 'Discharged', 'Stable • 2 hours ER'),
      ],
    );
  }
  
  Widget _buildShiftHistory() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _historyItem('17 Apr 2026', '⭐ 4.8 Rating', '12 Patients • 2m 1s avg response'),
        _historyItem('16 Apr 2026', '⭐ 4.9 Rating', '10 Patients • 1m 50s avg response'),
      ],
    );
  }

  Widget _buildTaskHistory() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _historyItem('Administered Medication', '14:32', 'Bed ICU-3', isTask: true),
        _historyItem('Vitals Recorded', '13:15', 'Ravi M.', isTask: true),
        _historyItem('Alert accepted - URGENT', '12:45', '', isTask: true),
      ],
    );
  }

  Widget _historyItem(String title, String status, String sub, {bool isTask = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                if (isTask) const Icon(Icons.check_circle, size: 14, color: AppTheme.stable),
                if (isTask) const Gap(6),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            Text(sub, style: const TextStyle(color: Color(0xFF5F6368), fontSize: 12)),
          ]),
          Text(status, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: status.contains('Discharge') ? AppTheme.stable : AppTheme.textSecondary)),
        ],
      ),
    );
  }

  void _showBedStatusSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) {
          return Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              controller: controller,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Update Bed Status', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Gap(8),
                  const Text('Current: ICU-3', style: TextStyle(color: Color(0xFF5F6368))),
                  const Gap(24),
                  
                  _buildBedOption('Available', 'Ready for patient', Icons.check_circle, const Color(0xFFE8F5E9), AppTheme.stable),
                  const Gap(12),
                  _buildBedOption('Occupied', 'Patient assigned', Icons.do_not_disturb_on, const Color(0xFFFFEBEE), AppTheme.critical),
                  const Gap(12),
                  _buildBedOption('Reserved', 'Pending assignment', Icons.warning_amber_rounded, const Color(0xFFFFF3E0), AppTheme.urgent),
                  
                  const Gap(24),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Add Note',
                      hintText: 'Reason for status change...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 2,
                  ),
                  const Gap(24),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(onPressed: ()=>Navigator.pop(context), child: const Text('Update Scope'))
                  )
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildBedOption(String title, String sub, IconData icon, Color bgColor, Color iconColor) {
    return InkWell(
      onTap: (){},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const Gap(16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: iconColor)),
                Text(sub, style: TextStyle(fontSize: 13, color: iconColor.withValues(alpha: 0.8))),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _startHandoff(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Handoff Notes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Gap(16),
              TextField(maxLines: 4, decoration: const InputDecoration(hintText: 'Notes for next nurse...', border: OutlineInputBorder())),
              const Gap(16),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(onPressed: (){
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Handoff submitted at 19:32')));
                }, child: const Text('Submit Handoff'))
              ),
              const Gap(24),
            ],
          ),
        );
      }
    );
  }
}
