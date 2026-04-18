import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../mock/mock_data.dart';
import '../../models/patient_model.dart';
import '../alerts/widgets/alert_card.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  late Timer _timer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('dd MMM yyyy — HH:mm:ss').format(DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final beds = ref.watch(bedsProvider);
    final alerts = ref.watch(alertsProvider);
    final staffList = ref.watch(staffProvider);
    final inPatients = ref.watch(incomingPatientProvider);

    final totalBeds = beds.length;
    final availableBeds = beds.where((b) => b.status == 'Available').length;
    final activeAlerts = alerts.where((a) => a.status == 'Active').length;
    final staffOnline = staffList.where((s) => s.available).length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.primaryDark, AppTheme.primary]),
              ),
              child: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                title: Row(
                  children: [
                    const Icon(Icons.circle, color: AppTheme.critical, size: 10)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fade(begin: 0.2, end: 1.0, duration: 800.ms),
                    const Gap(8),
                    Text(
                      'Crisis Command\n$_currentTime', 
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.2)
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () => context.go('/login'))
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStatGrid(totalBeds, availableBeds, activeAlerts, staffOnline),
                const Gap(32),
                _buildIncomingQueue(inPatients),
                const Gap(32),
                _buildActiveAlerts(alerts.where((a) => a.status == 'Active').toList(), context),
                const Gap(80), // padding for bottom bar
              ]),
            ),
          )
        ],
      ),
      bottomSheet: _buildHospitalStatusBar(beds),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.critical,
        onPressed: () => context.push('/trigger_alert'),
        icon: const Icon(Icons.warning, color: Colors.white),
        label: const Text('Trigger Alert', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildStatGrid(int tb, int ab, int aa, int so) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16, crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildGradientCard('Total Beds', tb, [Colors.blue.shade700, Colors.blue.shade400], Icons.bed),
        _buildGradientCard('Available', ab, [Colors.green.shade700, Colors.green.shade400], Icons.check_circle),
        _buildGradientCard('Active Alerts', aa, [Colors.red.shade700, Colors.red.shade400], Icons.warning, pulse: aa > 0),
        _buildGradientCard('Staff Online', so, [Colors.teal.shade700, Colors.teal.shade400], Icons.people),
      ].animate(interval: 100.ms).fade(duration: 400.ms).slideY(begin: 0.2, end: 0),
    );
  }

  Widget _buildGradientCard(String title, int value, List<Color> colors, IconData icon, {bool pulse = false}) {
    Widget card = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: colors.last.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const Gap(8),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const Spacer(),
          Text('$value', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
        ],
      ),
    );

    if (pulse) {
      return card.animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1000.ms);
    }
    return card;
  }

  Widget _buildIncomingQueue(List<PatientModel> queueList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Incoming Patients Queue', style: Theme.of(context).textTheme.titleLarge),
        const Gap(12),
        if (queueList.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
            child: const Center(
              child: Column(
                children: [
                   Icon(Icons.directions_car, size: 48, color: AppTheme.textSecondary),
                   Gap(8),
                   Text('No incoming patients', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold))
                ],
              ),
            ),
          )
        else
          ...queueList.asMap().entries.map((e) {
            int pos = e.key + 1;
            PatientModel p = e.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: AppTheme.primary.withValues(alpha: 0.1), child: Text('#$pos')),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Condition: ${p.vitalsSummary}'),
                trailing: const Chip(label: Text('Awaiting Triage'), backgroundColor: AppTheme.divider),
              ),
            ).animate().slideX();
          })
      ],
    );
  }

  Widget _buildActiveAlerts(List alerts, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('⚠️ Active Emergencies', style: Theme.of(context).textTheme.titleLarge),
            TextButton(onPressed: () => context.push('/alerts'), child: const Text('View All')) // Changed from context.go to context.push if we want back stack, but dashboard is usually root, wait, admin -> alerts pushes.
          ],
        ),
        const Gap(8),
        if (alerts.isEmpty) const Text('All clear!', style: TextStyle(color: AppTheme.textSecondary)),
        for (var alert in alerts.take(3))
          AlertCard(alert: alert, onTap: () => context.push('/alerts/${alert.id}')).animate().fade().slideX(),
      ],
    );
  }

  Widget _buildHospitalStatusBar(List beds) {
    int icuT = beds.where((b) => b.type == 'ICU').length;
    int icuO = beds.where((b) => b.type == 'ICU' && b.status != 'Available').length;
    
    int genT = beds.where((b) => b.type == 'General').length;
    int genO = beds.where((b) => b.type == 'General' && b.status != 'Available').length;

    int emrT = beds.where((b) => b.type == 'Emergency').length;
    int emrO = beds.where((b) => b.type == 'Emergency' && b.status != 'Available').length;

    return Container(
      height: 60,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statSegment('ICU', icuO, icuT),
          Container(width: 1, height: 30, color: AppTheme.divider),
          _statSegment('GEN', genO, genT),
          Container(width: 1, height: 30, color: AppTheme.divider),
          _statSegment('EMR', emrO, emrT),
        ],
      ),
    );
  }

  Widget _statSegment(String name, int occupied, int total) {
    double ratio = total == 0 ? 0 : occupied / total;
    Color c = AppTheme.stable;
    if (ratio > 0.7) c = AppTheme.urgent;
    if (ratio > 0.9) c = AppTheme.critical;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
        Text('$occupied/$total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: c)),
      ],
    );
  }
}
