import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../mock/mock_data.dart';
import '../../widgets/severity_badge.dart';

class AlertDetailScreen extends ConsumerStatefulWidget {
  final String alertId;

  const AlertDetailScreen({super.key, required this.alertId});

  @override
  ConsumerState<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends ConsumerState<AlertDetailScreen> {
  late Timer _timer;
  String _activeTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => _updateTime());
  }
  
  void _updateTime() {
    if (!mounted) return;
    // We update UI every second for live timers.
    setState(() {});
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(alertsProvider);
    final alert = alerts.firstWhere((a) => a.id == widget.alertId, orElse: () => alerts.first);
    final currentUser = ref.watch(currentUserProvider);

    Color bannerColor = AppTheme.stable;
    if (alert.severity == 'CRITICAL') bannerColor = AppTheme.critical;
    if (alert.severity == 'URGENT') bannerColor = AppTheme.urgent;

    final diff = DateTime.now().difference(alert.createdAt);
    _activeTime = '${diff.inMinutes}m ${(diff.inSeconds % 60).toString().padLeft(2, '0')}s';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: bannerColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [bannerColor, bannerColor.withValues(alpha: 0.8)]
                  )
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SeverityBadge(severity: alert.severity, fontSize: 16),
                      const Gap(12),
                      Text(alert.type, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.timer, color: AppTheme.textSecondary),
                            const Gap(8),
                            Text('Active for $_activeTime', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const Gap(16),
                        Text(alert.message, style: const TextStyle(fontSize: 16, height: 1.5)),
                        const Gap(16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Icon(Icons.group, color: AppTheme.primary),
                              const Gap(8),
                              Text('Target: ${alert.target}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ).animate().fade().slideY(begin: 0.1),
                
                const Gap(32),
                const Text('Response Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Gap(16),
                
                _buildTimelineStep('Alert Triggered', '${alert.createdAt.toIso8601String().substring(11,19)}', true, isFirst: true),
                if (alert.status == 'Acknowledged')
                  _buildTimelineStep('Acknowledged by ${alert.assignedTo}', 'Response time: ${diff.inMinutes}m', true, isFirst: false)
                else
                  _buildTimelineStep('Awaiting Response', '...', false, isFirst: false),
                  
                const Gap(40),
                if (currentUser != null && currentUser.role != 'Admin' && alert.status == 'Active')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.critical, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 18)
                          ),
                          onPressed: () => context.pop(),
                          child: const Text('Decline', style: TextStyle(color: AppTheme.critical)),
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.stable),
                          onPressed: () {
                            ref.read(alertsProvider.notifier).updateAlertStatus(alert.id, 'Acknowledged', assignedTo: currentUser.uid);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alert Acknowledged'), backgroundColor: AppTheme.stable));
                          },
                          child: const Text('Accept Response'),
                        ),
                      ),
                    ],
                  )
              ]),
            ),
          )
        ],
      )
    );
  }

  Widget _buildTimelineStep(String title, String subtitle, bool isCompleted, {required bool isFirst}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, 
              color: isCompleted ? AppTheme.primary : AppTheme.textSecondary
            ),
            if (!isFirst)
              Container(width: 2, height: 40, color: AppTheme.divider),
          ],
        ),
        const Gap(16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isCompleted ? AppTheme.textPrimary : AppTheme.textSecondary)),
            const Gap(4),
            Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary)),
            const Gap(30),
          ],
        )
      ],
    );
  }
}
