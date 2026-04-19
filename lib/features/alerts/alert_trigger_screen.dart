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

  final List<Map<String,dynamic>> alertTypes = [
    {'name': 'Mass Casualty', 'icon': '🚑'},
    {'name': 'Fire Emergency', 'icon': '🔥'},
    {'name': 'Drug Shortage', 'icon': '💊'},
    {'name': 'Power Failure', 'icon': '⚡'},
    {'name': 'Blood Low', 'icon': '🩸'},
    {'name': 'Staff Emer.', 'icon': '👨‍⚕️'},
    {'name': 'Infection', 'icon': '🦠'},
    {'name': 'Custom Alert', 'icon': '📋'},
  ];

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
    
    // Using simple mock tactile feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Crisis Alert Broadcast Activated to $selectedTarget'), backgroundColor: AppTheme.critical),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(title: const Text('Trigger Emergency Alert', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black)),
      body: SingleChildScrollView(
        child: Padding(
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
                  return IgnorePointer(
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
              
              const Text('Alert Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Gap(12),
              GridView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.8, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: alertTypes.length,
                itemBuilder: (ctx, i) {
                  bool isSel = selectedType == alertTypes[i]['name'];
                  return InkWell(
                    onTap: () => setState(() => selectedType = alertTypes[i]['name']),
                    child: Container(
                      decoration: BoxDecoration(color: isSel ? AppTheme.primary.withValues(alpha: 0.1) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSel ? AppTheme.primary : AppTheme.divider, width: isSel ? 2 : 1)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(alertTypes[i]['icon'], style: const TextStyle(fontSize: 24)),
                          const Gap(4),
                          Text(alertTypes[i]['name'], textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? AppTheme.primaryDark : AppTheme.textPrimary)),
                        ],
                      ),
                    ),
                  );
                }
              ),
              const Gap(32),

              const Text('Severity Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Gap(12),
              Row(
                children: [
                  Expanded(flex:2, child: _buildSeverityCard('CRITICAL', AppTheme.critical)),
                ]
              ),
              const Gap(8),
              Row(
                children: [
                  Expanded(child: _buildSeverityCard('URGENT', AppTheme.urgent)),
                  const Gap(8),
                  Expanded(child: _buildSeverityCard('STABLE', AppTheme.stable)),
                ],
              ),
              const Gap(32),
              
              const Text('Target Audience', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Gap(8),
              Wrap(
                spacing: 8,
                children: ['All Staff', 'Doctors Only', 'Nurses Only'].map((e) {
                  return ChoiceChip(
                    label: Text(e),
                    selected: selectedTarget == e,
                    onSelected: (val) => setState(() => selectedTarget = e),
                  );
                }).toList(),
              ),
              const Gap(24),
              
              if (selectedType == 'Custom Alert') ...[
                const Text('Additional Communication', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Gap(8),
                TextFormField(
                  controller: msgController,
                  maxLines: 4,
                  onChanged: (_) => setState((){}),
                  decoration: const InputDecoration(hintText: 'Enter specific emergency details...', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                ),
                const Gap(40),
              ],

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.critical),
                  onPressed: _sendAlert,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_rounded, size: 24, color: Colors.white),
                      Gap(12),
                      Text('🚨 Send Alert Now', style: TextStyle(fontSize: 18, letterSpacing: 1, color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.05, duration: 1.seconds)
            ],
          ),
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
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : AppTheme.divider, width: 2),
        ),
        child: Center(
          child: Text(
            level, 
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: isSelected ? Colors.white : AppTheme.textPrimary,
              fontSize: 16
            )
          )
        ),
      ),
    );
  }
}
