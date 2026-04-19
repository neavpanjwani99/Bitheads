import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app/theme.dart';
import '../../mock/mock_data.dart';
import '../../mock/concerns_provider.dart';
import '../../mock/announcements_provider.dart';
import '../../models/patient_model.dart';
import '../../widgets/chatbot_overlay.dart';
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
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildHeader(massCasualty),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!massCasualty)
                    _buildMassCasualtyToggle(false)
                  else
                    _buildMassCasualtyToggle(true),
                  
                  const Gap(24),
                  _buildGraphsGrid(),
                  const Gap(32),

                  _buildPatientQueueSection(),
                  const Gap(32),

                  const Text('Administrative Controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const Gap(16),
                  _buildAdminExtras(),
                  const Gap(100),
                ],
              ),
            ),
          )
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            backgroundColor: AppTheme.urgent,
            onPressed: () => context.push('/trigger_alert'),
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
            label: const Text('Broadcast Alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          const Gap(16),
          const ChatbotOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader(bool massCasualty) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AppTheme.primaryDark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppTheme.primaryDark,
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
                      const Text('RapidCare Command Center', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          const Icon(Icons.circle, color: AppTheme.critical, size: 10),
                          const Gap(6),
                          const Text('LIVE', style: TextStyle(color: AppTheme.critical, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                  const Gap(4),
                  Text(_currentTime, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const Gap(16),
                  const Text('City General Hospital | HOSP-ADM-001', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [IconButton(icon: const Icon(Icons.logout_outlined, color: Colors.white), onPressed: () => context.go('/login'))],
      bottom: massCasualty ? PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: Container(
          color: AppTheme.critical, width: double.infinity, height: 40, alignment: Alignment.center,
          child: const Text('MASS CASUALTY MODE ACTIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ) : null,
    );
  }

  Widget _buildMassCasualtyToggle(bool active) {
    return InkWell(
      onTap: () => ref.read(massCasualtyProvider.notifier).toggle(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF991B1B) : AppTheme.critical, 
          borderRadius: BorderRadius.circular(12)
        ),
        alignment: Alignment.center,
        child: Text(active ? 'DEACTIVATE MASS CASUALTY MODE' : 'ACTIVATE MASS CASUALTY MODE', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildGraphsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.85,
      children: [
        _buildGraphCard('Bed Occupancy', _buildBedChart()),
        _buildGraphCard('Alert Distribution', _buildAlertChart()),
        _buildGraphCard('Staff Availability', _buildStaffChart()),
        _buildGraphCard('Patient Triage', _buildTriageChart()),
      ],
    );
  }

  Widget _buildGraphCard(String title, Widget chart) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const Gap(24),
            Expanded(child: chart),
          ],
        ),
      ),
    );
  }

  Widget _buildBedChart() {
    final beds = ref.watch(bedsProvider);
    double icuT = beds.where((b)=>b.type=='ICU').length.toDouble();
    double icuO = beds.where((b)=>b.type=='ICU' && b.status!='Available').length.toDouble();
    double genT = beds.where((b)=>b.type=='General').length.toDouble();
    double genO = beds.where((b)=>b.type=='General' && b.status!='Available').length.toDouble();
    double emrT = beds.where((b)=>b.type=='Emergency').length.toDouble();
    double emrO = beds.where((b)=>b.type=='Emergency' && b.status!='Available').length.toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: 20,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(), rightTitles: const AxisTitles(), leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v,m)=>Text(['ICU','GEN','EMR'][v.toInt()], style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)))
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: icuT, color: AppTheme.primaryLight, width: 12), BarChartRodData(toY: icuO, color: AppTheme.primary, width: 12)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: genT, color: AppTheme.primaryLight, width: 12), BarChartRodData(toY: genO, color: AppTheme.primary, width: 12)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: emrT, color: AppTheme.primaryLight, width: 12), BarChartRodData(toY: emrO, color: AppTheme.primary, width: 12)]),
        ]
      ),
      swapAnimationDuration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildAlertChart() {
    final alerts = ref.watch(alertsProvider);
    double c = alerts.where((a)=>a.severity=='CRITICAL').length.toDouble();
    double u = alerts.where((a)=>a.severity=='URGENT').length.toDouble();
    double s = alerts.where((a)=>a.severity=='STABLE').length.toDouble();
    double r = alerts.where((a)=>a.status=='Resolved').length.toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: 10,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(), rightTitles: const AxisTitles(), leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v,m)=>Text(['CRI','URG','STB','RES'][v.toInt()], style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)))
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: c, color: AppTheme.critical, width: 16)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: u, color: AppTheme.urgent, width: 16)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: s, color: AppTheme.stable, width: 16)]),
          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: r, color: AppTheme.textSecondary, width: 16)]),
        ]
      ),
      swapAnimationDuration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildStaffChart() {
    final staff = ref.watch(staffProvider);
    double dAv = staff.where((s)=>s.role=='Doctor' && s.available).length.toDouble();
    double dUn = staff.where((s)=>s.role=='Doctor' && !s.available).length.toDouble();
    double nAv = staff.where((s)=>s.role=='Nurse' && s.available).length.toDouble();
    double nUn = staff.where((s)=>s.role=='Nurse' && !s.available).length.toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: 10,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(), rightTitles: const AxisTitles(), leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v,m)=>Text(['DOC','NRS'][v.toInt()], style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)))
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: dAv, color: AppTheme.accent, width: 12), BarChartRodData(toY: dUn, color: AppTheme.divider, width: 12)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: nAv, color: AppTheme.accent, width: 12), BarChartRodData(toY: nUn, color: AppTheme.divider, width: 12)]),
        ]
      ),
      swapAnimationDuration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildTriageChart() {
    final p = ref.watch(patientsProvider);
    double c = p.where((i)=>i.triageLevel=='CRITICAL').length.toDouble();
    double u = p.where((i)=>i.triageLevel=='URGENT').length.toDouble();
    double s = p.where((i)=>i.triageLevel=='STABLE').length.toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: 10,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(), rightTitles: const AxisTitles(), leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v,m)=>Text(['CRI','URG','STB'][v.toInt()], style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)))
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: c, color: AppTheme.critical, width: 16)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: u, color: AppTheme.urgent, width: 16)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: s, color: AppTheme.stable, width: 16)]),
        ]
      ),
      swapAnimationDuration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildPatientQueueSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Manual Admittance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ElevatedButton.icon(
              onPressed: _showAddPatientSheet, 
              icon: const Icon(Icons.add, size: 16), 
              label: const Text('New Admit')
            ),
          ],
        ),
      ],
    );
  }

  void _showAddPatientSheet() {
    String pName='New Patient', pAge='30', pCond='', pPri='STABLE', pGen='Female';
    String? pDoc, pBed;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.background, builder: (c) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 24, right: 24, top: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Admit Patient', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const Gap(16),
                  TextField(decoration: const InputDecoration(labelText: 'Patient Name*'), onChanged: (v)=>pName=v),
                  const Gap(12),
                  Row(
                    children: [
                      Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Age*'), keyboardType: TextInputType.number, onChanged: (v)=>pAge=v)),
                      const Gap(12),
                      Expanded(child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Gender*'),
                        value: 'Female', items: ['Male','Female','Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (v){ pGen = v!; }
                      )),
                    ],
                  ),
                  const Gap(12),
                  const TextField(decoration: InputDecoration(labelText: 'Contact Number*'), keyboardType: TextInputType.phone),
                  const Gap(12),
                  TextField(decoration: const InputDecoration(labelText: 'Reporting Condition* (Free text)'), maxLines: 2, onChanged: (v)=>pCond=v),
                  const Gap(12),
                  const Text('Priority*'),
                  const Gap(8),
                  Wrap(spacing: 8, children: ['Critical', 'High', 'Medium', 'Low'].map((pri) {
                    bool sel = pPri == pri.toUpperCase();
                    return ChoiceChip(label: Text(pri, style: TextStyle(color: sel ? AppTheme.surface : AppTheme.textSecondary)), selectedColor: AppTheme.primary, selected: sel, onSelected: (_)=>setState(()=>pPri=pri.toUpperCase()));
                  }).toList()),
                  const Gap(12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Assign Doctor'),
                    items: ref.read(staffProvider).where((s)=>s.role=='Doctor').map((d) => DropdownMenuItem(value: d.uid, child: Text(d.name))).toList(),
                    onChanged: (v)=>pDoc=v
                  ),
                  const Gap(12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Assign Bed'),
                    items: ref.read(bedsProvider).where((b)=>b.status=='Available').map((b) => DropdownMenuItem(value: b.id, child: Text(b.id))).toList(),
                    onChanged: (v)=>pBed=v
                  ),
                  const Gap(24),
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: (){
                    if(pName.isNotEmpty && pCond.isNotEmpty){
                      ref.read(patientsProvider.notifier).addPatient(PatientModel(
                        id: 'P-${DateTime.now().millisecondsSinceEpoch}',
                        name: pName, age: int.parse(pAge), gender: pGen,
                        triageLevel: pPri == 'HIGH' ? 'URGENT' : (pPri=='LOW'?'STABLE':pPri),
                        vitalsSummary: pCond,
                        assignedStaffId: pDoc, assignedBedId: pBed,
                        lastVitalsTime: DateTime.now()
                      ));
                      Navigator.pop(c);
                    }
                  }, child: const Text('Complete Admittance'))),
                  const Gap(32),
                ],
              ),
            ),
          );
        }
      );
    });
  }

  Widget _buildAdminExtras() {
    return Column(
      children: [
        _extraCard('Department Control Panel', Icons.admin_panel_settings_outlined, _showDepartmentControlPanel),
        _extraCard('Staff Performance & Shifts', Icons.table_chart_outlined, _showStaffPerformance),
        _extraCard('Resource Inventory Explorer',Icons.inventory_2_outlined, _showResourceInventory),
        _extraCard('Hospital Announcements', Icons.campaign_outlined, _showAnnouncementsPanel),
      ],
    );
  }

  Widget _extraCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSecondary),
        onTap: onTap,
      ),
    );
  }

  void _showDepartmentControlPanel() {
    bool icuLock = false; bool genLock = false; bool emrLock = false;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.background, builder: (c) {
      return StatefulBuilder(builder: (ctx, setState) {
        return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 24, right: 24, top: 24), child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Department Control Center', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Gap(16),
            _deptCard('ICU', '9/10 beds occupied', 0.9, 12, 1, icuLock, (v)=>setState(()=>icuLock=v)),
            _deptCard('General', '13/20 beds occupied', 0.65, 30, 0, genLock, (v)=>setState(()=>genLock=v)),
            _deptCard('Emergency', '5/15 beds occupied', 0.33, 24, 3, emrLock, (v)=>setState(()=>emrLock=v)),
            const Gap(32),
        ])); 
      });
    });
  }

  Widget _deptCard(String name, String occStr, double pct, int staffCount, int alertsCount, bool isLocked, ValueChanged<bool> onToggle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [const Icon(Icons.local_hospital_outlined, color: AppTheme.primary), const Gap(8), Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                Switch(value: isLocked, onChanged: onToggle, activeColor: AppTheme.critical),
              ],
            ),
            const Gap(8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(occStr), Text('${(pct*100).toInt()}%')]),
            const Gap(4),
            LinearProgressIndicator(value: pct, backgroundColor: AppTheme.divider, color: pct > 0.8 ? AppTheme.critical : AppTheme.primary),
            const Gap(12),
            Row(children: [
              Text('Staff: $staffCount', style: const TextStyle(fontWeight: FontWeight.bold)), const Gap(16),
              Text('Alerts: $alertsCount', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.urgent)),
            ]),
            const Gap(8),
            const TextField(decoration: InputDecoration(hintText: 'Add supervisor note...', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8))),
          ],
        ),
      ),
    );
  }

  void _showStaffPerformance() {
    bool sortAsc = true; int sortIdx = 0;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.background, builder: (c) {
      return StatefulBuilder(builder: (ctx, setState) {
        final staff = ref.watch(staffProvider).toList();
        if (sortIdx == 3) {
          staff.sort((a,b) => sortAsc ? a.averageResponseTimeSecs.compareTo(b.averageResponseTimeSecs) : b.averageResponseTimeSecs.compareTo(a.averageResponseTimeSecs));
        } else if (sortIdx == 2) {
          staff.sort((a,b) => sortAsc ? a.patientCount.compareTo(b.patientCount) : b.patientCount.compareTo(a.patientCount));
        } else {
          staff.sort((a,b) => sortAsc ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
        }

        return Container(
          height: MediaQuery.of(c).size.height * 0.85,
          padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 16, right: 16, top: 24), 
          child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Performance & Shifts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Gap(16),
            Expanded(child: SingleChildScrollView(scrollDirection: Axis.vertical, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
              sortColumnIndex: sortIdx, sortAscending: sortAsc,
              columns: [
                DataColumn(label: const Text('Name'), onSort: (i,a)=>setState((){sortIdx=i;sortAsc=a;})),
                const DataColumn(label: Text('Role')),
                DataColumn(label: const Text('Workload'), onSort: (i,a)=>setState((){sortIdx=i;sortAsc=a;})),
                DataColumn(label: const Text('Avg Resp.'), onSort: (i,a)=>setState((){sortIdx=i;sortAsc=a;})),
                const DataColumn(label: Text('Action')),
              ],
              rows: staff.map((s) => DataRow(cells: [
                DataCell(Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(s.role)),
                DataCell(Text('${s.patientCount} pts handled')),
                DataCell(Text('${s.averageResponseTimeSecs}s', style: TextStyle(color: s.averageResponseTimeSecs < 60 ? AppTheme.stable : (s.averageResponseTimeSecs > 100 ? AppTheme.critical : AppTheme.urgent), fontWeight: FontWeight.bold))),
                DataCell(ElevatedButton(onPressed: ()=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reminder sent to ${s.name}'))), child: const Text('Remind'))),
              ])).toList(),
            )))),
        ])); 
      });
    });
  }

  void _showResourceInventory() {
    int bA = 4; int bB = 2; int bO = 14; int bAB = 7;
    int eqV = 2; int eqD = 5; int eqO = 1;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.background, builder: (c) {
      return StatefulBuilder(builder: (ctx, setState) {
        return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 24, right: 24, top: 24), child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Resource Inventory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Gap(16),
            const Text('Blood Bank (Units)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
            const Gap(8),
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.5,
              children: [
                _resCard('A+', bA, (v)=>setState(()=>bA=v)),
                _resCard('B+', bB, (v)=>setState(()=>bB=v)),
                _resCard('O+', bO, (v)=>setState(()=>bO=v)),
                _resCard('AB+', bAB, (v)=>setState(()=>bAB=v)),
              ],
            ),
            const Gap(24),
            const Text('Critical Equipment', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
            const Gap(8),
            _eqRow('Ventilators', eqV, (v)=>setState(()=>eqV=v)),
            _eqRow('Defibrillators', eqD, (v)=>setState(()=>eqD=v)),
            _eqRow('Oxygen Cylinders', eqO, (v)=>setState(()=>eqO=v)),
            const Gap(32),
        ]))); 
      });
    });
  }

  Widget _resCard(String t, int count, ValueChanged<int> onVal) {
    bool low = count < 5;
    return Container(
      decoration: BoxDecoration(color: low ? AppTheme.criticalLight : AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: low ? AppTheme.critical : AppTheme.divider)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(icon: const Icon(Icons.remove, size: 16), onPressed: ()=>onVal(count>0?count-1:0)),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.bold)), Text('$count', style: TextStyle(color: low?AppTheme.critical:AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18))]),
          IconButton(icon: const Icon(Icons.add, size: 16), onPressed: ()=>onVal(count+1)),
        ],
      )
    );
  }

  Widget _eqRow(String t, int count, ValueChanged<int> onVal) {
    bool low = count < 3;
    return Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: low ? AppTheme.critical : AppTheme.divider)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppTheme.textSecondary), onPressed: ()=>onVal(count>0?count-1:0)),
              Text('$count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: low?AppTheme.critical:AppTheme.textPrimary)),
              IconButton(icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary), onPressed: ()=>onVal(count+1)),
            ],
          )
        ],
      ),
    );
  }

  void _showAnnouncementsPanel() {
    String title=''; String msg=''; bool isPri=false;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.background, builder: (c) {
      return StatefulBuilder(builder: (ctx, setState) {
        return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 24, right: 24, top: 24), child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Post Announcement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Gap(16),
            TextField(decoration: const InputDecoration(labelText: 'Title'), onChanged: (v)=>title=v),
            const Gap(12),
            TextField(decoration: const InputDecoration(labelText: 'Message'), maxLines: 3, onChanged: (v)=>msg=v),
            const Gap(12),
            Row(children: [
              const Text('Priority Alert?'), const Spacer(),
              Switch(value: isPri, onChanged: (v)=>setState(()=>isPri=v), activeColor: AppTheme.critical),
            ]),
            const Gap(16),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: (){
              if(title.isNotEmpty && msg.isNotEmpty){
                ref.read(announcementsProvider.notifier).addAnnouncement(AnnouncementModel(
                  id: 'AN${DateTime.now().millisecond}', title: title, message: msg, isPriority: isPri, expiresAt: DateTime.now().add(const Duration(hours: 12))
                ));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement successfully posted.')));
              }
            }, child: const Text('Post Announcement'))),
            const Gap(32),
        ]))); 
      });
    });
  }
}
