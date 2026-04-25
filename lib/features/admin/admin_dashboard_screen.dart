import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app/theme.dart';
import '../../models/patient_model.dart';
import '../../models/alert_model.dart';
import '../../models/bed_model.dart';
import '../../models/staff_model.dart';
import '../../providers/firestore_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clinical_status_providers.dart';
import '../../providers/incoming_patients_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/mass_casualty_banner.dart';
import '../../core/dsa/action_stack.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  late Timer _timer;
  String _currentTime = '';
  Map<String, int>? _inventoryDraft;

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
    final massCasualty = ref.watch(massCasualtyProvider);
    final patientsAsync = ref.watch(realPatientsProvider);
    final staffAsync = ref.watch(realStaffProvider);
    final bedsAsync = ref.watch(realBedsProvider);
    final alertsAsync = ref.watch(realAlertsProvider);
    final currentUser = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildHeader(massCasualty, currentUser),
          if (massCasualty) const SliverToBoxAdapter(child: MassCasualtyBanner()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMassCasualtyToggle(massCasualty),
                  const Gap(24),
                  _buildGraphsGrid(patientsAsync, bedsAsync, staffAsync, alertsAsync),
                  const Gap(32),
                  if (massCasualty) ...[
                    _buildDischargeSuggestions(patientsAsync),
                    const Gap(32),
                  ],
                  _buildPatientQueueSection(patientsAsync),
                  const Gap(32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Administrative Controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      if (!ref.watch(actionStackProvider).isEmpty)
                        TextButton.icon(
                          onPressed: () => ref.read(actionStackProvider.notifier).undo(),
                          icon: const Icon(Icons.undo, size: 16),
                          label: const Text('Undo Last Action'),
                        ),
                    ],
                  ),
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
        backgroundColor: AppTheme.urgent,
        onPressed: () => context.push('/trigger_alert'),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        label: const Text('Broadcast Alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildHeader(bool massCasualty, StaffModel? user) {
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
                  Text('City General Hospital | ${user?.hospitalId ?? 'HOSP-ADM-001'}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [IconButton(icon: const Icon(Icons.logout_outlined, color: Colors.white), onPressed: () => context.go('/login'))],
    );
  }

  Widget _buildMassCasualtyToggle(bool active) {
    return InkWell(
      onTap: () => _handleMassCasualtyMode(active),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: active ? AppTheme.divider : AppTheme.critical, 
          borderRadius: BorderRadius.circular(12),
          border: active ? Border.all(color: AppTheme.textSecondary) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          active ? 'DEACTIVATE MASS CASUALTY MODE' : 'ACTIVATE MASS CASUALTY MODE', 
          style: TextStyle(color: active ? AppTheme.textPrimary : Colors.white, fontSize: 16, fontWeight: FontWeight.w600)
        ),
      ),
    );
  }

  void _handleMassCasualtyMode(bool currentActive) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(currentActive ? 'Deactivate Mass Casualty Mode' : 'Activate Mass Casualty Mode'),
        content: Text(currentActive 
          ? 'Are you sure you want to resume normal operations?' 
          : 'This will alert ALL available staff and broadcast emergency status across all dashboards.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (currentActive) {
                ref.read(massCasualtyProvider.notifier).deactivate();
              } else {
                ref.read(massCasualtyProvider.notifier).activate();
                final alert = AlertModel(
                  id: 'MCE${DateTime.now().millisecondsSinceEpoch}',
                  type: 'MASS CASUALTY EVENT',
                  target: 'All Staff',
                  message: 'Mass Casualty Mode activated. Report to your stations immediately.',
                  severity: 'CRITICAL',
                  status: 'Active',
                  createdAt: DateTime.now(),
                );
                await ref.read(firestoreServiceProvider).addAlert(alert);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: currentActive ? AppTheme.primary : AppTheme.critical),
            child: Text(currentActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }

  Widget _buildDischargeSuggestions(AsyncValue<List<PatientModel>> patientsAsync) {
    return patientsAsync.when(
      data: (patients) {
        final dischargeCandidates = patients.where((p) => p.triageLevel == 'STABLE' && p.attendanceStatus == 'Attended').toList();
        if (dischargeCandidates.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Consider Discharge to Free Beds', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.critical)),
            const Gap(8),
            ...dischargeCandidates.take(3).map((p) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Bed: ${p.assignedBedId} • Status: Stable'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    await ref.read(firestoreServiceProvider).updatePatientFields(p.id, {'attendanceStatus': 'Discharged'});
                    if (p.assignedBedId != null) {
                      await ref.read(firestoreServiceProvider).updateBedStatus(p.assignedBedId!, 'Available');
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.name} recommended for discharge.')));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.stable),
                  child: const Text('Discharge', style: TextStyle(fontSize: 12)),
                ),
              ),
            )),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildGraphsGrid(
    AsyncValue<List<PatientModel>> patients, 
    AsyncValue<List<BedModel>> beds,
    AsyncValue<List<StaffModel>> staff,
    AsyncValue<List<AlertModel>> alerts
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.85,
      children: [
        _buildGraphCard('Bed Occupancy', _buildBedChart(beds)),
        _buildGraphCard('Alert Distribution', _buildAlertChart(alerts)),
        _buildGraphCard('Staff Availability', _buildStaffChart(staff)),
        _buildGraphCard('Patient Triage', _buildTriageChart(patients)),
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

  Widget _buildBedChart(AsyncValue<List<BedModel>> bedsAsync) {
    return bedsAsync.when(
      data: (beds) {
        double icuT = beds.where((b)=>b.type=='ICU').length.toDouble();
        double icuO = beds.where((b)=>b.type=='ICU' && b.status!='Available').length.toDouble();
        double genT = beds.where((b)=>b.type=='General').length.toDouble();
        double genO = beds.where((b)=>b.type=='General' && b.status!='Available').length.toDouble();
        double emrT = beds.where((b)=>b.type=='Emergency').length.toDouble();
        double emrO = beds.where((b)=>b.type=='Emergency' && b.status!='Available').length.toDouble();

        return BarChart(BarChartData(
          alignment: BarChartAlignment.spaceEvenly,
          maxY: (icuT + genT + emrT) > 0 ? (icuT + genT + emrT) : 10,
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(), rightTitles: const AxisTitles(), leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v,m)=>Text(['ICU','GEN','EMR'][v.toInt()], style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)))),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: icuT, color: AppTheme.primaryLight, width: 12), BarChartRodData(toY: icuO, color: AppTheme.primary, width: 12)]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: genT, color: AppTheme.primaryLight, width: 12), BarChartRodData(toY: genO, color: AppTheme.primary, width: 12)]),
            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: emrT, color: AppTheme.primaryLight, width: 12), BarChartRodData(toY: emrO, color: AppTheme.primary, width: 12)]),
          ]
        ));
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Icon(Icons.error),
    );
  }

  Widget _buildAlertChart(AsyncValue<List<AlertModel>> alertsAsync) {
    return alertsAsync.when(
      data: (alerts) {
        double c = alerts.where((a)=>a.severity=='CRITICAL' && a.status != 'Resolved').length.toDouble();
        double u = alerts.where((a)=>a.severity=='URGENT' && a.status != 'Resolved').length.toDouble();
        double s = alerts.where((a)=>a.severity=='STABLE' && a.status != 'Resolved').length.toDouble();
        double r = alerts.where((a)=>a.status=='Resolved').length.toDouble();

        return BarChart(BarChartData(
          alignment: BarChartAlignment.spaceEvenly,
          maxY: (c+u+s+r) > 0 ? (c+u+s+r) : 10,
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(), rightTitles: const AxisTitles(), leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v,m)=>Text(['CRI','URG','STB','RES'][v.toInt()], style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)))),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: c, color: AppTheme.critical, width: 16)]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: u, color: AppTheme.urgent, width: 16)]),
            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: s, color: AppTheme.stable, width: 16)]),
            BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: r, color: AppTheme.textSecondary, width: 16)]),
          ]
        ));
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Icon(Icons.error),
    );
  }

  Widget _buildStaffChart(AsyncValue<List<StaffModel>> staffAsync) {
    return staffAsync.when(
      data: (staff) {
        double dAv = staff.where((s)=>s.role=='Doctor' && s.available).length.toDouble();
        double dUn = staff.where((s)=>s.role=='Doctor' && !s.available).length.toDouble();
        double nAv = staff.where((s)=>s.role=='Nurse' && s.available).length.toDouble();
        double nUn = staff.where((s)=>s.role=='Nurse' && !s.available).length.toDouble();

        return BarChart(BarChartData(
          alignment: BarChartAlignment.spaceEvenly,
          maxY: staff.length > 0 ? staff.length.toDouble() : 10,
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(), rightTitles: const AxisTitles(), leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v,m)=>Text(['DOC','NRS'][v.toInt()], style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)))),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: dAv, color: AppTheme.accent, width: 12), BarChartRodData(toY: dUn, color: AppTheme.divider, width: 12)]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: nAv, color: AppTheme.accent, width: 12), BarChartRodData(toY: nUn, color: AppTheme.divider, width: 12)]),
          ]
        ));
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Icon(Icons.error),
    );
  }

  Widget _buildTriageChart(AsyncValue<List<PatientModel>> patientsAsync) {
    return patientsAsync.when(
      data: (p) {
        final active = p.where((i) => i.attendanceStatus != 'Attended').toList();
        double c = active.where((i)=>i.triageLevel=='CRITICAL').length.toDouble();
        double u = active.where((i)=>i.triageLevel=='URGENT').length.toDouble();
        double s = active.where((i)=>i.triageLevel=='STABLE').length.toDouble();

        return BarChart(BarChartData(
          alignment: BarChartAlignment.spaceEvenly,
          maxY: active.length > 0 ? active.length.toDouble() : 10,
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(), rightTitles: const AxisTitles(), leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v,m)=>Text(['CRI','URG','STB'][v.toInt()], style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)))),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: c, color: AppTheme.critical, width: 16)]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: u, color: AppTheme.urgent, width: 16)]),
            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: s, color: AppTheme.stable, width: 16)]),
          ]
        ));
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Icon(Icons.error),
    );
  }

  Widget _buildPatientQueueSection(AsyncValue<List<PatientModel>> patientsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Incoming Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ElevatedButton.icon(
              onPressed: _showAddPatientSheet, 
              icon: const Icon(Icons.add, size: 16), 
              label: const Text('New Admit')
            ),
          ],
        ),
        const Gap(16),
        patientsAsync.when(
          data: (patients) {
            final incoming = patients.where((p) => p.attendanceStatus == 'Incoming' || p.attendanceStatus == 'Triaging').toList();
            if (incoming.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    Icon(Icons.airline_seat_flat_outlined, size: 48, color: AppTheme.divider),
                    const Gap(8),
                    const Text('No incoming patients', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                  ],
                )
              );
            }
            return Column(children: incoming.map((p) => _buildIncomingQueueCard(p)).toList());
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildIncomingQueueCard(PatientModel p) {
    bool isTriaging = p.attendanceStatus == 'Triaging';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isTriaging ? AppTheme.accent : AppTheme.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isTriaging ? AppTheme.accent.withValues(alpha: 0.1) : AppTheme.primaryLight,
              child: Text(p.name[0], style: TextStyle(color: isTriaging ? AppTheme.accent : AppTheme.primaryDark, fontWeight: FontWeight.bold)),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  Text('${p.age}y • ${p.vitalsSummary}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isTriaging)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Triaging...', style: TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                const Gap(8),
                SizedBox(
                  height: 35,
                  child: ElevatedButton(
                    onPressed: isTriaging ? null : () => context.push('/triage?id=${p.id}&name=${Uri.encodeComponent(p.name)}&age=${p.age}&gender=${p.gender}'),
                    child: const Text('Start Triage', style: TextStyle(fontSize: 12)),
                  ),
                )
              ],
            )
          ],
        )
      ),
    );
  }

  void _showAddPatientSheet() {
    String pName=''; String pAge='30'; String pCond=''; String pPri='STABLE'; String pGen='Female';
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
                        value: pGen, items: ['Male','Female','Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (v){ setState(() => pGen = v!); }
                      )),
                    ],
                  ),
                  const Gap(12),
                  TextField(decoration: const InputDecoration(labelText: 'Reporting Condition*'), maxLines: 2, onChanged: (v)=>pCond=v),
                  const Gap(12),
                  const Text('Priority*'),
                  const Gap(8),
                  Wrap(spacing: 8, children: ['Critical', 'High', 'Medium', 'Low'].map((pri) {
                    bool sel = pPri == pri.toUpperCase();
                    return ChoiceChip(label: Text(pri), selected: sel, onSelected: (_)=>setState(()=>pPri=pri.toUpperCase()));
                  }).toList()),
                  const Gap(12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Assign Doctor'),
                    items: (ref.read(realStaffProvider).asData?.value ?? []).where((s)=>s.role=='Doctor').map((d) => DropdownMenuItem(value: d.uid, child: Text(d.name))).toList(),
                    onChanged: (v)=>pDoc=v
                  ),
                  const Gap(12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Assign Bed'),
                    items: (ref.read(realBedsProvider).asData?.value ?? []).where((b)=>b.status=='Available').map((b) => DropdownMenuItem(value: b.id, child: Text(b.id))).toList(),
                    onChanged: (v)=>pBed=v
                  ),
                  const Gap(24),
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async {
                    if(pName.isNotEmpty && pCond.isNotEmpty){
                      final newPatient = PatientModel(
                        id: 'P-${DateTime.now().millisecondsSinceEpoch}',
                        name: pName, age: int.parse(pAge), gender: pGen,
                        triageLevel: pPri == 'HIGH' ? 'URGENT' : (pPri=='LOW'?'STABLE':pPri),
                        vitalsSummary: pCond,
                        assignedStaffId: pDoc, assignedBedId: pBed,
                        attendanceStatus: 'Incoming',
                        lastVitalsTime: DateTime.now()
                      );
                      await ref.read(firestoreServiceProvider).addPatient(newPatient);
                      if (pBed != null) {
                        await ref.read(firestoreServiceProvider).updateBedStatus(pBed!, 'Occupied', patientName: pName);
                      }
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
        _extraCard('Manage Hospital Beds', Icons.bed_outlined, _showManageBedsSheet),
        _extraCard('Department Control Panel', Icons.admin_panel_settings_outlined, _showDepartmentControlPanel),
        _extraCard('Staff Performance & Shifts', Icons.table_chart_outlined, _showStaffPerformance),
        _extraCard('Resource Inventory Explorer',Icons.inventory_2_outlined, _showResourceInventory),
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

  void _showManageBedsSheet() {
    String bedId = '';
    String bedType = 'General';
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.background, builder: (c) {
      return StatefulBuilder(builder: (ctx, setSheetState) {
        final bedsAsync = ref.watch(realBedsProvider);
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Bed Management Center', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const Gap(24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Register New Bed', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          const Gap(16),
                          TextField(
                            decoration: const InputDecoration(labelText: 'Bed ID (e.g. ICU-05)'),
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (v) => bedId = v,
                          ),
                          const Gap(12),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Bed Type'),
                            value: bedType,
                            items: ['ICU', 'General', 'Emergency'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (v) => setSheetState(() => bedType = v!),
                          ),
                          const Gap(16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final finalId = bedId.trim().toUpperCase();
                                if (finalId.isNotEmpty) {
                                  final existingBeds = ref.read(realBedsProvider).asData?.value ?? [];
                                  if (existingBeds.any((b) => b.id == finalId)) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppTheme.critical, content: Text('Error: Bed ID already exists!')));
                                    return;
                                  }
                                  final newBed = BedModel(id: finalId, type: bedType, status: 'Available');
                                  await ref.read(firestoreServiceProvider).addBed(newBed);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bed Registered!')));
                                }
                              },
                              child: const Text('Add Bed'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(32),
                    const Text('Existing Beds Inventory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Gap(16),
                    bedsAsync.when(
                      data: (beds) => ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: beds.length,
                        itemBuilder: (context, index) {
                          final bed = beds[index];
                          bool isOccupied = bed.status == 'Occupied';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              leading: Icon(Icons.bed, color: bed.status == 'Available' ? AppTheme.stable : (bed.status == 'Occupied' ? AppTheme.critical : Colors.orange)),
                              title: Text(bed.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${bed.type} • ${bed.status} ${isOccupied ? "(${bed.patientName})" : ""}'),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: TextField(
                                            decoration: InputDecoration(hintText: isOccupied ? 'Occupied (Read Only)' : 'New ID'),
                                            enabled: !isOccupied,
                                            onChanged: (v) => bedId = v,
                                          )),
                                          const Gap(12),
                                          IconButton(
                                            icon: Icon(Icons.edit, color: isOccupied ? AppTheme.divider : AppTheme.primary),
                                            onPressed: isOccupied ? null : () async {
                                              final finalNewId = bedId.trim().toUpperCase();
                                              if (finalNewId.isNotEmpty && finalNewId != bed.id) {
                                                await ref.read(firestoreServiceProvider).addBed(bed.copyWith(id: finalNewId));
                                                await ref.read(firestoreServiceProvider).deleteBed(bed.id);
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bed Renamed!')));
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      const Gap(16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(children: [
                                            const Text('Maintenance: '),
                                            Switch(value: bed.status == 'Maintenance', onChanged: isOccupied ? null : (v) async {
                                              await ref.read(firestoreServiceProvider).updateBedStatus(bed.id, v ? 'Maintenance' : 'Available');
                                            }),
                                          ]),
                                          TextButton.icon(
                                            onPressed: isOccupied ? null : () async {
                                              await ref.read(firestoreServiceProvider).deleteBed(bed.id);
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bed Deleted!')));
                                            },
                                            icon: Icon(Icons.delete_outline, color: isOccupied ? AppTheme.divider : AppTheme.critical),
                                            label: Text('Delete', style: TextStyle(color: isOccupied ? AppTheme.divider : AppTheme.critical)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      });
    });
  }

  void _showDepartmentControlPanel() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.background, builder: (c) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Padding(padding: const EdgeInsets.all(24), child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('Department Control Center', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Gap(16),
                _deptCard('ICU', 'High Load', 0.9, 12, 1),
                _deptCard('General', 'Stable', 0.65, 30, 0),
                _deptCard('Emergency', 'Critical', 0.33, 24, 3),
                const Gap(32),
            ]),
          ));
        }
      );
    });
  }

  Widget _deptCard(String name, String status, double pct, int staffCount, int alertsCount) {
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
                Text(status, style: TextStyle(color: pct > 0.8 ? AppTheme.critical : AppTheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            const Gap(12),
            LinearProgressIndicator(value: pct, backgroundColor: AppTheme.divider, color: pct > 0.8 ? AppTheme.critical : AppTheme.primary),
            const Gap(12),
            Row(children: [
              Text('Staff: $staffCount'), const Gap(16),
              Text('Alerts: $alertsCount', style: const TextStyle(color: AppTheme.urgent)),
            ]),
          ],
        ),
      ),
    );
  }

  void _showStaffPerformance() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.background, builder: (c) {
      return ref.watch(realStaffProvider).when(
        data: (staff) => Container(
          height: MediaQuery.of(c).size.height * 0.85,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Staff Performance & Shifts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Gap(16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Role')),
                        DataColumn(label: Text('Workload')),
                        DataColumn(label: Text('Avg Resp.')),
                      ],
                      rows: staff.map((s) => DataRow(cells: [
                        DataCell(Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(s.role)),
                        DataCell(Text('${s.patientCount} pts')),
                        DataCell(Text('${s.averageResponseTimeSecs}s')),
                      ])).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
      );
    });
  }

  void _showResourceInventory() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.background, builder: (c) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Resource Inventory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Gap(24),
            Expanded(
              child: ListView(
                children: [
                  _inventoryRow('Ventilators', 18, 20),
                  _inventoryRow('Oxygen Tanks', 42, 50),
                  _inventoryRow('Blood (O+)', 12, 15),
                  _inventoryRow('ICU Kits', 5, 10),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _inventoryRow(String item, int current, int total) {
    double pct = current / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(item, style: const TextStyle(fontWeight: FontWeight.bold)), Text('$current/$total')]),
          const Gap(8),
          LinearProgressIndicator(value: pct, backgroundColor: AppTheme.divider, color: pct < 0.3 ? AppTheme.critical : AppTheme.primary, minHeight: 8),
        ],
      ),
    );
  }
}