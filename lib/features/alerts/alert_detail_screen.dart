import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../app/theme.dart';
import '../../mock/mock_data.dart';
import '../../models/alert_model.dart';
import 'package:intl/intl.dart';

class AlertDetailScreen extends ConsumerWidget {
  final String alertId;
  const AlertDetailScreen({super.key, required this.alertId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wrap to rebuild if changes happen
    final alerts = ref.watch(alertsProvider);
    final alert = alerts.firstWhere((a) => a.id == alertId, orElse: () => alerts.first);
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Alert Dispatch')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
              child: Column(
                children: [
                  Icon(Icons.warning_rounded, size: 64, color: alert.severity == 'CRITICAL' ? AppTheme.critical : AppTheme.urgent),
                  const Gap(16),
                  Text(alert.type, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const Gap(8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: alert.severity == 'CRITICAL' ? AppTheme.critical : AppTheme.urgent, borderRadius: BorderRadius.circular(16)),
                    child: Text(alert.severity, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const Gap(32),

            const Text('Dispatch Message', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const Gap(8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
              child: Text(alert.message, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
            ),
            const Gap(24),

            const Text('Dispatch Metadata', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const Gap(8),
            Card(
              child: Column(
                children: [
                  ListTile(title: const Text('Target Audience', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)), subtitle: Text(alert.target, style: const TextStyle(fontWeight: FontWeight.w500))),
                  ListTile(title: const Text('Timestamp', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)), subtitle: Text(DateFormat('HH:mm').format(alert.createdAt), style: const TextStyle(fontWeight: FontWeight.w500))),
                  ListTile(title: const Text('Status', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)), subtitle: Text(alert.status, style: TextStyle(fontWeight: FontWeight.bold, color: alert.status == 'Acknowledged' ? AppTheme.stable : (alert.status == 'Declined' ? AppTheme.textSecondary : AppTheme.urgent)))),
                ],
              ),
            ),
            const Gap(40),

            if (alert.status == 'Active')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: AppTheme.divider)),
                      onPressed: () {
                        ref.read(alertsProvider.notifier).updateStatus(alert.id, 'Declined');
                        context.pop();
                      },
                      child: const Text('Decline', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                    )
                  ),
                  const Gap(16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.stable, padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () {
                        ref.read(alertsProvider.notifier).updateStatus(alert.id, 'Acknowledged');
                      },
                      child: const Text('Acknowledge'),
                    )
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }
}
