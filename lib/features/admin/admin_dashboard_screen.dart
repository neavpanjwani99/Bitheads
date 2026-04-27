import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
// SharedPreferences removed for Firestore-backed dismissal
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
  final Set<String> _dismissedTriageIds = {};

    @override
    void initState() {
      super.initState();
      _updateTime();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) => _updateTime());
    }
  
    Future<void> _dismissTriage(String patientId) async {
      final user = ref.read(authNotifierProvider);
      if (user != null) {
        await ref.read(firestoreServiceProvider).dismissTriage(user.uid, patientId);
      }
    }

  void _updateTime() {
    if (!mounted) return;
    setState(() => _currentTime = DateFormat('dd MMM yyyy — HH:mm:ss').format(DateTime.now()));
  }

  void _confirmDeletePatient(PatientModel p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Patient Record?'),
        content: Text('Are you sure you want to permanently remove ${p.name} from the queue? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (p.assignedBedId != null) {
                await ref.read(firestoreServiceProvider).updateBedStatus(p.assignedBedId!, 'Available');
              }
              await ref.read(firestoreServiceProvider).updatePatientFields(p.id, {'attendanceStatus': 'Deleted'});
              if (ctx.mounted) Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.name} removed from queue and bed freed.')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.critical),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
    final dismissedAsync = currentUser != null 
        ? ref.watch(dismissedTriageIdsProvider(currentUser.uid)) 
        : const AsyncValue<List<String>>.data([]);

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
                  _buildActiveDispatchSection(alertsAsync),
                  const Gap(32),
                  _buildTriageActivityFeed(patientsAsync, dismissedAsync),
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
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: icuT, color: Colors.blue.shade100, width: 14), BarChartRodData(toY: icuO, color: Colors.indigoAccent, width: 14)]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: genT, color: Colors.blue.shade100, width: 14), BarChartRodData(toY: genO, color: Colors.indigoAccent, width: 14)]),
            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: emrT, color: Colors.blue.shade100, width: 14), BarChartRodData(toY: emrO, color: Colors.indigoAccent, width: 14)]),
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
        // Show All-Time History to make the graph meaningful and rich
        double c = alerts.where((a)=>a.severity=='CRITICAL').length.toDouble();
        double u = alerts.where((a)=>a.severity=='URGENT').length.toDouble();
        double s = alerts.where((a)=>a.severity=='STABLE').length.toDouble();

        return StatefulBuilder(
          builder: (context, setState) {
            int touchedIndex = -1;

            return Column(
              children: [
                Expanded(
                  child: PieChart(PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        value: c == 0 ? 0.5 : c, 
                        color: AppTheme.critical, 
                        title: c.toInt().toString(), 
                        radius: touchedIndex == 0 ? 45 : 35, 
                        titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        badgeWidget: touchedIndex == 0 ? _buildPieTooltip('CRI', c.toInt()) : null,
                        badgePositionPercentageOffset: 1.2,
                      ),
                      PieChartSectionData(
                        value: u == 0 ? 0.5 : u, 
                        color: AppTheme.urgent, 
                        title: u.toInt().toString(), 
                        radius: touchedIndex == 1 ? 45 : 35, 
                        titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        badgeWidget: touchedIndex == 1 ? _buildPieTooltip('URG', u.toInt()) : null,
                        badgePositionPercentageOffset: 1.2,
                      ),
                      PieChartSectionData(
                        value: s == 0 ? 0.5 : s, 
                        color: AppTheme.stable, 
                        title: s.toInt().toString(), 
                        radius: touchedIndex == 2 ? 45 : 35, 
                        titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        badgeWidget: touchedIndex == 2 ? _buildPieTooltip('STB', s.toInt()) : null,
                        badgePositionPercentageOffset: 1.2,
                      ),
                    ]
                  )),
                ),
                const Gap(12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem('Critical', AppTheme.critical),
                    _buildLegendItem('Urgent', AppTheme.urgent),
                    _buildLegendItem('Stable', AppTheme.stable),
                  ]
                )
              ]
            );
          }
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Icon(Icons.error),
    );
  }

  Widget _buildPieTooltip(String title, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]
      ),
      child: Text('$title: $value', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLegendItem(String title, Color c) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const Gap(4),
        Text(title, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
      ],
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
            return Column(children: incoming.map((p) => _buildIncomingQueueCard(p)).toList().cast<Widget>());
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildIncomingQueueCard(PatientModel p) {
    bool isTriaging = p.attendanceStatus == 'Triaging';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isTriaging ? AppTheme.accent : AppTheme.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: isTriaging ? AppTheme.accent.withValues(alpha: 0.05) : AppTheme.surface, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?', style: TextStyle(color: isTriaging ? AppTheme.accent : AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textPrimary)),
                const Gap(4),
                Text('${p.age}y • ${p.vitalsSummary}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isTriaging)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Triaging...', style: TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              Row(
                children: [
                  if (!isTriaging)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.textSecondary, size: 20),
                      onPressed: () => _confirmDeletePatient(p),
                    ),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isTriaging ? const Color(0xFFE0E0E0) : const Color(0xFF4A90E2), // Light Blue
                        foregroundColor: isTriaging ? const Color(0xFF9E9E9E) : Colors.white,
                        elevation: isTriaging ? 0 : 2,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isTriaging ? null : () => context.push('/triage?id=${p.id}&name=${Uri.encodeComponent(p.name)}&age=${p.age}&gender=${p.gender}'),
                      child: const Text('Start Triage', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActiveDispatchSection(AsyncValue<List<AlertModel>> alertsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Active Dispatch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const Gap(16),
        alertsAsync.when(
          data: (alerts) {
            final active = alerts.where((a) => a.status != 'Resolved').toList();
            if (active.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No active dispatches', style: TextStyle(color: AppTheme.textSecondary))));
            return Column(
              children: active.map((a) {
                bool isAck = a.status == 'Acknowledged';
                Color color = a.severity == 'CRITICAL' ? AppTheme.critical : AppTheme.urgent;
                final duration = DateTime.now().difference(a.createdAt);
                final minutes = duration.inMinutes;
                final seconds = duration.inSeconds % 60;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.1)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Container(width: 8, color: color), // Thick Left Border from Image 2
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                                      child: Text(a.severity, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                    ),
                                  ],
                                ),
                                const Gap(12),
                                Text(a.type, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                Text(a.message, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                                const Gap(16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.timer_outlined, size: 14, color: color),
                                        const Gap(6),
                                        Text('$minutes:${seconds.toString().padLeft(2, '0')}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                                      ],
                                    ),
                                    if (isAck)
                                      Row(
                                        children: [
                                          const Icon(Icons.verified_user_rounded, size: 16, color: AppTheme.primary),
                                          const Gap(6),
                                          Text(
                                            'Assigned to ${a.assignedTo ?? "Staff"}', 
                                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)
                                          ),
                                        ],
                                      )
                                    else
                                      const Text('PENDING ASSIGNMENT', style: TextStyle(color: AppTheme.critical, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList().cast<Widget>(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildTriageActivityFeed(AsyncValue<List<PatientModel>> patientsAsync, AsyncValue<List<String>> dismissedAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Triage Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const Gap(16),
        dismissedAsync.when(
          data: (dismissedIds) => patientsAsync.when(
            data: (patients) {
              final recentTriage = patients
                  .where((p) => p.triagedBy != null && 
                                (p.attendanceStatus == 'Attended' || p.attendanceStatus == 'Pending') && 
                                !dismissedIds.contains(p.id))
                  .toList()
                ..sort((a, b) => (b.lastVitalsTime ?? DateTime.now()).compareTo(a.lastVitalsTime ?? DateTime.now()));
              
              final displayList = recentTriage.take(3).toList(); 
              if (displayList.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No recent activity', style: TextStyle(color: AppTheme.textSecondary))));
              
              return Column(
                children: displayList.map((p) => Dismissible(
                  key: Key('triage_${p.id}'),
                  onDismissed: (_) => _dismissTriage(p.id),
                  direction: DismissDirection.horizontal,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
                      ),
                      title: Text('Dr. ${p.triagedBy ?? "Staff"} triaged ${p.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('Triage: ${p.triageLevel} • ${DateFormat('HH:mm').format(p.lastVitalsTime ?? DateTime.now())}', style: const TextStyle(fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
                        onPressed: () => _dismissTriage(p.id),
                      ),
                    ),
                  ),
                )).toList().cast<Widget>(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
          ),
          loading: () => const SizedBox.shrink(),
          error: (e, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _showDepartmentControlPanel() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.background, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (c) {
      return Consumer(builder: (ctx, ref, child) {
        final deptsAsync = ref.watch(realDepartmentsProvider);
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text('Strategic Response Hub', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Gap(8),
              const Text('Monitor occupancy and trigger emergency drills', style: TextStyle(color: AppTheme.textSecondary)),
              const Gap(24),
              deptsAsync.when(
                data: (depts) => ListView.builder(
                  shrinkWrap: true,
                  itemCount: depts.length,
                  itemBuilder: (context, i) {
                    final d = depts[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(Icons.business_outlined, color: d.isDrillActive ? Colors.orange : AppTheme.primary),
                        title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Occupancy: ${d.occupiedBeds}/${d.totalBeds} (${d.occupancyRate.toStringAsFixed(1)}%)'),
                        trailing: Switch(
                          activeColor: Colors.orange,
                          value: d.isDrillActive,
                          onChanged: (v) => ref.read(firestoreServiceProvider).updateDrillStatus(d.id, v),
                        ),
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              const Gap(24),
            ],
          ),
          ),
        );
      });
    });
  }

  void _showStaffPerformance() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.background, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (c) {
      return Consumer(builder: (ctx, ref, child) {
        final staffAsync = ref.watch(realStaffProvider);
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text('Care Activity Tracker', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Gap(8),
              const Text('Monitor performance scores and nudge staff', style: TextStyle(color: AppTheme.textSecondary)),
              const Gap(24),
              staffAsync.when(
                data: (staff) {
                  final list = staff.where((s) => s.role != 'Admin').toList()
                    ..sort((a, b) => b.performanceScore.compareTo(a.performanceScore));
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final s = list[i];
                      bool isInactive = s.lastActivityAt != null && DateTime.now().difference(s.lastActivityAt!).inMinutes > 45;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isInactive ? AppTheme.critical : AppTheme.stable,
                            child: Text('${s.performanceScore}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${s.role} • ${isInactive ? "Inactive 45m+" : "Active Now"}'),
                          trailing: ElevatedButton(
                            onPressed: () {
                              ref.read(firestoreServiceProvider).sendNudge(s.uid, 'Your ward needs an update!');
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nudge sent to ${s.name}')));
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(horizontal: 12)),
                            child: const Text('Nudge', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              const Gap(24),
            ],
          ),
          ),
        );
      });
    });
  }

  void _showResourceInventory() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.background, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (c) {
      return Consumer(builder: (ctx, ref, child) {
        final invAsync = ref.watch(realInventoryProvider);
        final patientsAsync = ref.watch(realPatientsProvider);
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text('Predictive Supply Hub', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Gap(8),
              const Text('Predictive survival timer based on patient load', style: TextStyle(color: AppTheme.textSecondary)),
              const Gap(24),
              invAsync.when(
                data: (items) {
                  final patientCount = patientsAsync.asData?.value.length ?? 0;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      double hours = item.calculateSurvivalHours(patientCount);
                      bool isCritical = item.currentStock <= item.minThreshold;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(isCritical ? Icons.warning_amber_rounded : Icons.inventory_2, color: isCritical ? AppTheme.critical : AppTheme.primary),
                          title: Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Stock: ${item.currentStock} ${item.unit}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Survival Timer', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                              Text('${(hours / 24).toStringAsFixed(1)} Days', style: TextStyle(fontWeight: FontWeight.bold, color: hours < 48 ? AppTheme.critical : AppTheme.stable)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              const Gap(16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showBloodMatchSearch,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Find Emergency Blood Donors (Hero Feature)'),
                ),
              ),
              const Gap(32),
            ],
          ),
          ),
        );
      });
    });
  }

  void _showBloodMatchSearch() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.background, builder: (c) {
      return Consumer(builder: (ctx, ref, child) {
        final staffAsync = ref.watch(realStaffProvider);
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              const Text('Hero Feature: Donor Match', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.critical)),
              const Gap(12),
              const Text('Staff members eligible for emergency blood donation', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
              const Gap(24),
              staffAsync.when(
                data: (staff) {
                  final donors = staff.where((s) => s.bloodGroup == 'O-' || s.bloodGroup == 'O+').toList();
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: donors.length,
                    itemBuilder: (context, i) {
                      final s = donors[i];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: AppTheme.critical, child: Icon(Icons.water_drop, color: Colors.white, size: 16)),
                          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${s.role} • Dept: ${s.specialization}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.critical.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(s.bloodGroup, style: const TextStyle(color: AppTheme.critical, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
              const Gap(24),
            ],
          ),
          ),
        );
      });
    });
  }

  void _showAddPatientSheet() {
    String pName=''; String pAge='30'; String pCond=''; String pPri='STABLE'; String pGen='Female'; String pPhone='';
    String? pDoc, pBed, pNurse;
    String? phoneError;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.background, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (c) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 24, right: 24, top: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Admit Patient', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      IconButton(icon: const Icon(Icons.close, color: AppTheme.textSecondary), onPressed: () => Navigator.pop(c)),
                    ],
                  ),
                  const Gap(24),
                  TextField(decoration: const InputDecoration(labelText: 'Patient Name*'), onChanged: (v)=>pName=v),
                  const Gap(16),
                  Row(
                    children: [
                      Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Age*'), keyboardType: TextInputType.number, onChanged: (v)=>pAge=v)),
                      const Gap(16),
                      Expanded(child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Gender*'),
                        value: pGen, items: ['Male','Female','Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (v){ setState(() => pGen = v!); }
                      )),
                    ],
                  ),
                  const Gap(16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Contact Number*',
                      errorText: phoneError,
                      prefixText: '+91 ',
                      hintText: '10-digit number',
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onChanged: (v) {
                      pPhone = v;
                      if (v.length == 10) {
                        setState(() => phoneError = null);
                      }
                    },
                  ),
                  const Gap(16),
                  TextField(decoration: const InputDecoration(labelText: 'Reporting Condition*'), maxLines: 2, onChanged: (v)=>pCond=v),
                  const Gap(20),
                  const Text('Priority*', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                  const Gap(12),
                  Wrap(spacing: 8, children: ['Critical', 'High', 'Medium', 'Low'].map((pri) {
                    bool sel = pPri == pri.toUpperCase();
                    Color chipColor = Colors.grey[200]!;
                    if (sel) {
                      if (pri == 'Critical') chipColor = AppTheme.critical.withValues(alpha: 0.15);
                      else if (pri == 'High') chipColor = AppTheme.urgent.withValues(alpha: 0.15);
                      else if (pri == 'Medium') chipColor = AppTheme.primary.withValues(alpha: 0.15);
                      else chipColor = AppTheme.stable.withValues(alpha: 0.15);
                    }
                    Color textColor = sel ? (pri == 'Critical' ? AppTheme.critical : (pri == 'High' ? AppTheme.urgent : (pri == 'Medium' ? AppTheme.primary : AppTheme.stable))) : AppTheme.textSecondary;

                    return ChoiceChip(
                      label: Text(pri), 
                      selected: sel, 
                      selectedColor: chipColor,
                      labelStyle: TextStyle(color: textColor, fontWeight: sel ? FontWeight.bold : FontWeight.normal),
                      onSelected: (_)=>setState(()=>pPri=pri.toUpperCase())
                    );
                  }).toList()),
                  const Gap(20),
                  Consumer(
                    builder: (context, ref, child) {
                      final staff = ref.watch(realStaffProvider).asData?.value ?? [];
                      // Force rebuild when availability changes
                      final staffKey = staff.fold<String>('', (prev, s) => '$prev${s.uid}${s.available}');
                      
                      return DropdownButtonFormField<String>(
                        key: ValueKey('doc_dropdown_$staffKey'),
                        decoration: const InputDecoration(labelText: 'Assign Doctor'),
                        items: staff.where((s)=>s.role=='Doctor').map((d) => DropdownMenuItem(
                          value: d.uid, 
                          child: Text('${d.name} (${d.available ? 'Available' : 'Busy'})', style: TextStyle(color: d.available ? AppTheme.textPrimary : AppTheme.critical)),
                        )).toList(),
                        onChanged: (v)=>pDoc=v
                      );
                    },
                  ),
                  const Gap(16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Assign Bed'),
                    items: (ref.read(realBedsProvider).asData?.value ?? []).where((b)=>b.status=='Available' || b.id == pBed).map((b) => DropdownMenuItem(value: b.id, child: Text(b.id))).toList(),
                    onChanged: (v)=>pBed=v
                  ),
                  const Gap(16),
                  Consumer(
                    builder: (context, ref, child) {
                      final staff = ref.watch(realStaffProvider).asData?.value ?? [];
                      final staffKey = staff.fold<String>('', (prev, s) => '$prev${s.uid}${s.available}');
                      
                      return DropdownButtonFormField<String>(
                        key: ValueKey('nurse_dropdown_$staffKey'),
                        decoration: const InputDecoration(labelText: 'Assign Nurse'),
                        items: staff.where((s)=>s.role=='Nurse').map((n) => DropdownMenuItem(
                          value: n.uid, 
                          child: Text('${n.name} (${n.available ? 'Available' : 'Busy'})', style: TextStyle(color: n.available ? AppTheme.textPrimary : AppTheme.critical)),
                        )).toList(),
                        onChanged: (v)=>pNurse=v
                      );
                    },
                  ),
                  const Gap(32),
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async {
                    if (pPhone.length != 10) {
                      setState(() => phoneError = 'Enter exactly 10 digits');
                      return;
                    }
                    if(pName.isNotEmpty && pCond.isNotEmpty){
                      // Title Case Formatting: Nisha
                      String formattedName = pName.trim().split(' ').where((w) => w.isNotEmpty).map((word) {
                        return word[0].toUpperCase() + word.substring(1).toLowerCase();
                      }).join(' ');

                      final newPatient = PatientModel(
                        id: 'P-${DateTime.now().millisecondsSinceEpoch}',
                        name: formattedName, age: int.parse(pAge), gender: pGen,
                        triageLevel: pPri == 'HIGH' ? 'URGENT' : (pPri=='LOW'?'STABLE':pPri),
                        vitalsSummary: pCond,
                        assignedStaffId: pDoc, assignedBedId: pBed,
                        assignedNurseId: pNurse,
                        assignedNurseName: pNurse != null ? (ref.read(realStaffProvider).asData?.value ?? []).firstWhere((s)=>s.uid==pNurse).name : null,
                        attendanceStatus: 'Incoming',
                        lastVitalsTime: DateTime.now(),
                        careStartedAt: DateTime.now(),
                        phone: pPhone,
                      );
                      await ref.read(firestoreServiceProvider).addPatient(newPatient);
                      if (pBed != null) {
                        await ref.read(firestoreServiceProvider).updateBedStatus(pBed!, 'Occupied', patientName: formattedName);
                      }
                      Navigator.pop(c);
                    }
                  }, child: const Text('Complete Admittance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                  const Gap(40),
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
        _extraCard('Strategic Response Hub', Icons.admin_panel_settings_outlined, _showDepartmentControlPanel),
        _extraCard('Care Activity Tracker', Icons.table_chart_outlined, _showStaffPerformance),
        _extraCard('Predictive Supply Hub',Icons.inventory_2_outlined, _showResourceInventory),
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
    final TextEditingController registerController = TextEditingController();
    String registerId = '';
    String bedType = 'General';
    final Map<String, String> renameDrafts = {};

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.background, builder: (c) {
      String? inModalMessage;
      return Consumer(builder: (ctx, ref, child) {
        final bedsAsync = ref.watch(realBedsProvider);
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(builder: (stContext, setLocalState) {
              void showLocalFeedback(String msg) {
                setLocalState(() => inModalMessage = msg);
                Future.delayed(const Duration(seconds: 2), () {
                  if (stContext.mounted) setLocalState(() => inModalMessage = null);
                });
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Stack(
                  children: [
                    SingleChildScrollView(
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
                                  controller: registerController,
                                  decoration: const InputDecoration(labelText: 'Bed ID (e.g. ICU-05)'),
                                  textCapitalization: TextCapitalization.characters,
                                  onChanged: (v) => setLocalState(() => registerId = v.trim().toUpperCase()),
                                ),
                                const Gap(8),
                                if (registerId.isNotEmpty)
                                  Builder(builder: (context) {
                                    final existingBeds = bedsAsync.asData?.value ?? [];
                                    bool exists = existingBeds.any((b) => b.id == registerId);
                                    return Row(
                                      children: [
                                        Icon(exists ? Icons.error_outline : Icons.check_circle_outline, 
                                             size: 14, color: exists ? AppTheme.critical : Colors.green),
                                        const Gap(4),
                                        Text(
                                          exists ? 'Bed ID "$registerId" already exists!' : 'Bed ID "$registerId" is available.',
                                          style: TextStyle(fontSize: 12, color: exists ? AppTheme.critical : Colors.green, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    );
                                  }),
                                const Gap(12),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(labelText: 'Bed Type'),
                                  value: bedType,
                                  items: ['ICU', 'General', 'Emergency'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                  onChanged: (v) => setLocalState(() => bedType = v!),
                                ),
                                const Gap(16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (registerId.isNotEmpty) {
                                        final existingBeds = bedsAsync.asData?.value ?? [];
                                        if (existingBeds.any((b) => b.id == registerId)) {
                                          showLocalFeedback('Error: Bed ID exists!');
                                          return;
                                        }
                                        
                                        showLocalFeedback('Bed Registered!');
                                        final newBed = BedModel(id: registerId, type: bedType, status: 'Available');
                                        ref.read(firestoreServiceProvider).addBed(newBed);
                                        
                                        registerController.clear();
                                        setLocalState(() => registerId = ''); 
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
                                final draftId = renameDrafts[bed.id] ?? '';

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
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(child: TextField(
                                                  decoration: InputDecoration(hintText: isOccupied ? 'Occupied (Read Only)' : 'New ID'),
                                                  enabled: !isOccupied,
                                                  textCapitalization: TextCapitalization.characters,
                                                  onChanged: (v) => setLocalState(() => renameDrafts[bed.id] = v.trim().toUpperCase()),
                                                )),
                                                const Gap(12),
                                                IconButton(
                                                  icon: Icon(Icons.check_circle, color: isOccupied || draftId.isEmpty ? AppTheme.divider : AppTheme.primary),
                                                  onPressed: isOccupied || draftId.isEmpty ? null : () {
                                                    if (beds.any((b) => b.id == draftId)) {
                                                      showLocalFeedback('Error: ID taken!');
                                                      return;
                                                    }
                                                    
                                                    showLocalFeedback('Bed Renamed!');
                                                    final updatedBed = bed.copyWith(id: draftId);
                                                    ref.read(firestoreServiceProvider).addBed(updatedBed);
                                                    ref.read(firestoreServiceProvider).deleteBed(bed.id);
                                                    
                                                    setLocalState(() => renameDrafts.remove(bed.id));
                                                  },
                                                ),
                                              ],
                                            ),
                                            if (draftId.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                                                child: Builder(builder: (context) {
                                                  bool exists = beds.any((b) => b.id == draftId);
                                                  return Row(
                                                    children: [
                                                      Icon(exists ? Icons.error_outline : Icons.check_circle_outline, 
                                                           size: 14, color: exists ? AppTheme.critical : Colors.green),
                                                      const Gap(4),
                                                      Text(
                                                        exists ? 'ID "$draftId" taken!' : 'ID "$draftId" available.',
                                                        style: TextStyle(fontSize: 11, color: exists ? AppTheme.critical : Colors.green, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  );
                                                }),
                                              ),
                                            const Gap(16),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text('Bed Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                                                    const Gap(8),
                                                    Row(
                                                      children: [
                                                        _statusChip(
                                                          'Available', 
                                                          bed.status == 'Available', 
                                                          AppTheme.stable, 
                                                          isOccupied ? null : () {
                                                            showLocalFeedback('${bed.id} is Available');
                                                            ref.read(firestoreServiceProvider).updateBedStatus(bed.id, 'Available');
                                                          }
                                                        ),
                                                        const Gap(8),
                                                        _statusChip(
                                                          'Maintenance', 
                                                          bed.status == 'Maintenance', 
                                                          Colors.orange, 
                                                          isOccupied ? null : () {
                                                            showLocalFeedback('${bed.id} in Maintenance');
                                                            ref.read(firestoreServiceProvider).updateBedStatus(bed.id, 'Maintenance');
                                                          }
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                IconButton(
                                                  onPressed: isOccupied ? null : () {
                                                    showLocalFeedback('Bed Deleted');
                                                    ref.read(firestoreServiceProvider).deleteBed(bed.id);
                                                  },
                                                  icon: Icon(Icons.delete_forever, color: isOccupied ? AppTheme.divider : AppTheme.critical, size: 28),
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
                    if (inModalMessage != null)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: inModalMessage!.contains('Error') ? AppTheme.critical : AppTheme.primary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))],
                            ),
                            child: Text(inModalMessage!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            });
          },
        );
      });
    });
  }

  Widget _resCard(String t, int count, ValueChanged<int> onVal) {
    bool low = count < 5;
    return Container(
      decoration: BoxDecoration(color: low ? AppTheme.critical.withValues(alpha: 0.1) : AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: low ? AppTheme.critical : AppTheme.divider)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(icon: const Icon(Icons.remove, size: 16), onPressed: ()=>onVal(count>0?count-1:0)),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.bold)), Text('$count', style: TextStyle(color: low?AppTheme.critical:AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18))]),
          IconButton(icon: const Icon(Icons.add, size: 16), onPressed: ()=>onVal(count+1)),
        ],
      ),
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

  Widget _statusChip(String label, bool isActive, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
