import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../app/theme.dart';
import '../../mock/mock_data.dart';
import '../../models/alert_model.dart';
import 'package:intl/intl.dart';
import '../../providers/firestore_providers.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlertDetailScreen extends ConsumerWidget {
  final String alertId;
  const AlertDetailScreen({super.key, required this.alertId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(realAlertsProvider);
    
    return alertsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (alerts) {
        final alert = alerts.firstWhere((a) => a.id == alertId, orElse: () => alerts.first);
        final color = alert.severity == 'CRITICAL' ? AppTheme.critical : (alert.severity == 'URGENT' ? AppTheme.urgent : AppTheme.stable);

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Emergency Dispatch Detail'),
            backgroundColor: AppTheme.surface,
            foregroundColor: AppTheme.textPrimary,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Priority Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.emergency_outlined, size: 48, color: color),
                      const Gap(16),
                      Text(alert.type.toUpperCase(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.2)),
                      const Gap(8),
                      Text(alert.severity, style: TextStyle(fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
                const Gap(32),

                // Message
                const Text('INCIDENT REPORT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary, letterSpacing: 1.1)),
                const Gap(12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
                  child: Text(
                    alert.message,
                    style: const TextStyle(fontSize: 16, height: 1.5, color: AppTheme.textPrimary),
                  ),
                ),
                const Gap(32),

                // Dispatch Info
                const Text('DISPATCH METADATA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary, letterSpacing: 1.1)),
                const Gap(12),
                _buildInfoRow('Broadcast Target', alert.target),
                _buildInfoRow('Received Time', DateFormat('HH:mm:ss').format(alert.createdAt)),
                _buildInfoRow('Current Status', alert.status, isStatus: true, statusColor: alert.status == 'Active' ? AppTheme.urgent : AppTheme.stable),
                
                const Gap(48),

                if (alert.status == 'Active') ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final staffName = ref.read(authNotifierProvider)?.name ?? 'Staff';
                      final updated = alert.copyWith(status: 'Acknowledged', assignedTo: staffName);
                      await ref.read(firestoreServiceProvider).updateAlert(updated);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Alert Acknowledged by $staffName')));
                      }
                    },
                    child: const Text('ACKNOWLEDGE & ASSIGN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  ),
                  const Gap(16),
                ],
                
                if (alert.status == 'Acknowledged')
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.stable,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final updated = alert.copyWith(status: 'Resolved');
                      await ref.read(firestoreServiceProvider).updateAlert(updated);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alert marked as RESOLVED.')));
                        context.pop();
                      }
                    },
                    child: const Text('MARK AS RESOLVED', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStatus = false, Color? statusColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.divider))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: isStatus ? (statusColor ?? AppTheme.textPrimary) : AppTheme.textPrimary
            )
          ),
        ],
      ),
    );
  }
}
