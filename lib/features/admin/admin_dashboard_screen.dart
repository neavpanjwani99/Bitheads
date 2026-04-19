import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
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
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => _updateTime());
  }

  void _updateTime() {
    if (!mounted) return;
    setState(() => _currentTime = DateFormat('dd MMM yyyy — HH:mm:ss').format(DateTime.now()));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool massCasualty = ref.watch(massCasualtyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          _buildHeader(massCasualty),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMassCasualtyToggle(massCasualty),
                  const Gap(16),
                  _buildStatCards(),
                  const Gap(32),
                  _buildChartsGrid(),
                  const Gap(32),
                  _buildAddPatientQueueSection(),
                  const Gap(32),
                  const Text('Admin Extra Features', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Gap(16),
                  _buildAdminExtras(),
                  const Gap(100),
                ],
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.critical,
        onPressed: () => context.push('/trigger_alert'),
        icon: const Icon(Icons.warning, color: Colors.white),
        label: const Text('Trigger Alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader(bool massCasualty) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: const Color(0xFF0D3B7A),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0A1628), Color(0xFF0D3B7A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('RapidCare Command Center', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Icon(Icons.circle, color: AppTheme.critical, size: 10).animate(onPlay: (c)=>c.repeat(reverse: true)).fade(duration: 800.ms),
                          const Gap(6),
                          const Text('LIVE', style: TextStyle(color: AppTheme.critical, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                  const Gap(4),
                  Text(_currentTime, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const Gap(16),
                  const Text('City General Hospital | HOSP-MUM-001', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () => context.go('/login'))],
      bottom: massCasualty ? PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: Container(
          color: AppTheme.critical, width: double.infinity, height: 40, alignment: Alignment.center,
          child: const Text('🚨 MASS CASUALTY MODE ACTIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ) : null,
    );
  }

  Widget _buildMassCasualtyToggle(bool active) {
    return InkWell(
      onTap: () => ref.read(massCasualtyProvider.notifier).toggle(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: active ? Colors.red.shade900 : AppTheme.critical, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text(active ? 'DEACTIVATE MASS CASUALTY MODE' : 'ACTIVATE MASS CASUALTY MODE', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatCards() {
    final beds = ref.watch(bedsProvider);
    final alerts = ref.watch(alertsProvider);
    final staff = ref.watch(staffProvider);

    int totB = beds.length;
    int avB = beds.where((b)=>b.status=='Available').length;
    int acA = alerts.where((a)=>a.status=='Active').length;
    int onS = staff.where((s)=>s.available).length;

    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.3,
      children: [
        _statCard('Total Beds', totB, [Colors.blue.shade700, Colors.blue.shade400]),
        _statCard('Available', avB, [Colors.green.shade700, Colors.green.shade400]),
        _statCard('Active Alerts', acA, [Colors.red.shade700, Colors.red.shade400]),
        _statCard('Staff Online', onS, [Colors.teal.shade700, Colors.teal.shade400]),
      ],
    );
  }
  
  Widget _statCard(String t, int v, List<Color> c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: c), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text('$v', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildChartsGrid() {
    return Column(
      children: [
        _buildChartContainer('Bed Occupancy (Bar)', _buildBarChart(), height: 250),
        const Gap(16),
        Row(
          children: [
            Expanded(child: _buildChartContainer('Alert Distribution', _buildPieChart(), height: 220)),
            const Gap(16),
            Expanded(child: _buildChartContainer('Staff Availability', _buildDonutChart(), height: 220)),
          ],
        ),
        const Gap(16),
        _buildChartContainer('Alert Trend (Line)', _buildLineChart(), height: 250),
      ],
    );
  }

  Widget _buildChartContainer(String title, Widget chart, {double height = 200}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
          const Gap(16),
          Expanded(child: chart),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final beds = ref.watch(bedsProvider);
    double icuT = beds.where((b)=>b.type=='ICU').length.toDouble();
    double icuO = beds.where((b)=>b.type=='ICU' && b.status!='Available').length.toDouble();
    double genT = beds.where((b)=>b.type=='General').length.toDouble();
    double genO = beds.where((b)=>b.type=='General' && b.status!='Available').length.toDouble();
    double emrT = beds.where((b)=>b.type=='Emergency').length.toDouble();
    double emrO = beds.where((b)=>b.type=='Emergency' && b.status!='Available').length.toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 15,
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(), rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v,m)=>Text(['ICU','GEN','EMR'][v.toInt()], style: const TextStyle(fontSize: 10)))),
        ),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: icuT, color: Colors.blue, width: 20), BarChartRodData(toY: icuO, color: Colors.red, width: 20)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: genT, color: Colors.blue, width: 20), BarChartRodData(toY: genO, color: Colors.red, width: 20)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: emrT, color: Colors.blue, width: 20), BarChartRodData(toY: emrO, color: Colors.red, width: 20)]),
        ]
      )
    );
  }

  Widget _buildPieChart() {
    final alerts = ref.watch(alertsProvider);
    double c = alerts.where((a)=>a.severity=='CRITICAL').length.toDouble();
    double u = alerts.where((a)=>a.severity=='URGENT').length.toDouble();
    double s = alerts.where((a)=>a.severity=='STABLE').length.toDouble();
    
    // Prevent zero state error
    if (c==0 && u==0 && s==0) s = 1;

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(color: AppTheme.critical, value: c, radius: 40, showTitle: false),
          PieChartSectionData(color: AppTheme.urgent, value: u, radius: 40, showTitle: false),
          PieChartSectionData(color: AppTheme.stable, value: s, radius: 40, showTitle: false),
        ]
      )
    );
  }

  Widget _buildDonutChart() {
    final staff = ref.watch(staffProvider);
    double dAv = staff.where((s)=>s.role=='Doctor' && s.available).length.toDouble();
    double dUn = staff.where((s)=>s.role=='Doctor' && !s.available).length.toDouble();
    
    if (dAv==0 && dUn==0) dAv=1;

    return PieChart(
      PieChartData(
        sectionsSpace: 0, centerSpaceRadius: 30,
        sections: [
          PieChartSectionData(color: AppTheme.stable, value: dAv, radius: 15, showTitle: false),
          PieChartSectionData(color: AppTheme.textSecondary, value: dUn, radius: 15, showTitle: false),
        ]
      )
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(topTitles: AxisTitles(), rightTitles: AxisTitles(), bottomTitles: AxisTitles()),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: const [FlSpot(0, 2), FlSpot(1, 4), FlSpot(2, 3), FlSpot(3, 8), FlSpot(4, 5)],
            isCurved: true, color: Colors.blue, barWidth: 3, belowBarData: BarAreaData(show: true, color: Colors.blue.withValues(alpha: 0.1))
          ),
          LineChartBarData(
            spots: const [FlSpot(0, 1), FlSpot(1, 2), FlSpot(2, 1), FlSpot(3, 5), FlSpot(4, 2)],
            isCurved: true, color: Colors.red, barWidth: 4, belowBarData: BarAreaData(show: true, color: Colors.red.withValues(alpha: 0.1))
          ),
        ]
      )
    );
  }

  Widget _buildAddPatientQueueSection() {
    final inPatients = ref.watch(incomingPatientProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Incoming Patient Queue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.critical),
              onPressed: _showAddPatientSheet, 
              icon: const Icon(Icons.add, color: Colors.white, size: 16), 
              label: const Text('Add Patient', style: TextStyle(color: Colors.white))
            ),
          ],
        ),
        const Gap(16),
        if (inPatients.isEmpty)
          const Text('No incoming patients', style: TextStyle(color: AppTheme.textSecondary))
        else
          ...inPatients.map((p) => Card(
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: AppTheme.accent, child: Icon(Icons.airport_shuttle, color: Colors.white)),
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(p.vitalsSummary),
              trailing: const Text('ETA: 4:32', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.critical)),
            )
          ))
      ],
    );
  }

  void _showAddPatientSheet() {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 16, right: 16, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Incoming Patient', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Gap(16),
            const TextField(decoration: InputDecoration(labelText: 'Patient Name', border: OutlineInputBorder())),
            const Gap(8),
            const TextField(decoration: InputDecoration(labelText: 'Minutes Away (ETA)', border: OutlineInputBorder())),
            const Gap(8),
            Container(
              padding: const EdgeInsets.all(8), color: AppTheme.divider,
              child: const Text('Condition: 🚗 Accident | ❤️ Cardiac | 🫁 Resp'),
            ),
            const Gap(16),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: ()=>Navigator.pop(c), child: const Text('Save to Queue'))),
            const Gap(24),
          ],
        ),
      );
    });
  }

  Widget _buildAdminExtras() {
    return Column(
      children: [
        _extraCard('Department Control Panel', Icons.admin_panel_settings),
        _extraCard('Staff Performance & Shifts', Icons.table_chart),
        _extraCard('Resource Inventory Low: [🩸, ⚡]',Icons.inventory, urgent: true),
        _extraCard('Hospital Announcements', Icons.campaign),
      ],
    );
  }

  Widget _extraCard(String title, IconData icon, {bool urgent = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: urgent ? AppTheme.critical : AppTheme.divider)),
      child: ListTile(
        leading: Icon(icon, color: urgent ? AppTheme.critical : AppTheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
