import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'dart:math';
import '../../app/theme.dart';
import '../../mock/mock_data.dart';
import '../../models/alert_model.dart';
import 'widgets/alert_card.dart';

class AlertTriggerScreen extends ConsumerStatefulWidget {
  const AlertTriggerScreen({super.key});

  @override
  ConsumerState<AlertTriggerScreen> createState() => _AlertTriggerScreenState();
}

class _AlertTriggerScreenState extends ConsumerState<AlertTriggerScreen> {
  String selectedType = 'Mass Casualty';
  String selectedSeverity = 'CRITICAL';
  String selectedTarget = 'All Staff';
  final TextEditingController msgController = TextEditingController();

  void _sendAlert() {
    final alert = AlertModel(
      id: 'A${Random().nextInt(1000)}',
      type: selectedType,
      severity: selectedSeverity,
      target: selectedTarget,
      message: msgController.text.isEmpty ? 'No additional message' : msgController.text,
      createdAt: DateTime.now(),
      status: 'Active',
    );

    ref.read(alertsProvider.notifier).addAlert(alert);
    
    // Using HapticFeedback could be done here if dart:ui is available
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Crisis Alert Broadcast Activated'), backgroundColor: AppTheme.critical),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trigger Emergency Alert')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Live Preview', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
            const Gap(8),
            // Live building preview using the existing AlertCard layout
            ValueListenableBuilder(
              valueListenable: msgController,
              builder: (context, value, child) {
                return PointerInterceptor(
                  child: AlertCard(
                    alert: AlertModel(
                      id: 'preview',
                      type: selectedType,
                      severity: selectedSeverity,
                      target: selectedTarget,
                      message: msgController.text.isEmpty ? '(Message will appear here)' : msgController.text,
                      createdAt: DateTime.now(),
                      status: 'Active'
                    ),
                    onTap: (){},
                  ),
                );
              }
            ),
            const Gap(32),

            const Text('Severity Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Gap(12),
            Row(
              children: [
                Expanded(child: _buildSeverityCard('CRITICAL', AppTheme.critical)),
                const Gap(8),
                Expanded(child: _buildSeverityCard('URGENT', AppTheme.urgent)),
                const Gap(8),
                Expanded(child: _buildSeverityCard('STABLE', AppTheme.stable)),
              ],
            ),
            const Gap(32),
            
            const Text('Alert Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Gap(8),
            DropdownButtonFormField<String>(
              value: selectedType,
              items: ['Mass Casualty', 'Equipment Failure', 'Staff Emergency', 'Patient Code Red']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => selectedType = val!),
            ),
            const Gap(24),
            
            const Text('Target Audience', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Gap(8),
            DropdownButtonFormField<String>(
              value: selectedTarget,
              items: ['All Staff', 'Doctors Only', 'Nurses Only']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => selectedTarget = val!),
            ),
            const Gap(24),
            
            const Text('Additional Communication', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Gap(8),
            TextFormField(
              controller: msgController,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Enter specific emergency details...'),
            ),
            const Gap(40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.critical),
                onPressed: _sendAlert,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_rounded, size: 24),
                    Gap(12),
                    Text('BROADCAST ALERT', style: TextStyle(fontSize: 18, letterSpacing: 1)),
                  ],
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.02, 1.02))
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityCard(String level, Color color) {
    bool isSelected = selectedSeverity == level;
    return GestureDetector(
      onTap: () => setState(() => selectedSeverity = level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? color : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : AppTheme.divider, width: 2),
        ),
        child: Center(
          child: Text(
            level, 
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: isSelected ? Colors.white : AppTheme.textPrimary,
              fontSize: 13
            )
          )
        ),
      ),
    );
  }
}

// Prevents taps on the preview card
class PointerInterceptor extends StatelessWidget {
  final Widget child;
  const PointerInterceptor({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: child);
  }
}
