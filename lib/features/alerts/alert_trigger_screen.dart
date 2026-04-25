import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'dart:math';
import '../../app/theme.dart';
import '../../mock/mock_data.dart';
import '../../models/alert_model.dart';
import '../../services/firestore_service.dart';
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
    {'name': 'Mass Casualty', 'icon': Icons.emergency_share_outlined},
    {'name': 'Fire Emergency', 'icon': Icons.local_fire_department_outlined},
    {'name': 'Drug Shortage', 'icon': Icons.medication_outlined},
    {'name': 'Power Failure', 'icon': Icons.power_off_outlined},
    {'name': 'Blood Low', 'icon': Icons.water_drop_outlined},
    {'name': 'Staff Emer.', 'icon': Icons.medical_services_outlined},
    {'name': 'Infection', 'icon': Icons.coronavirus_outlined},
    {'name': 'Custom Alert', 'icon': Icons.assignment_outlined},
  ];

  void _sendAlert() async {
    final alert = AlertModel(
      id: '', // Firestore will generate
      type: selectedType,
      severity: selectedSeverity,
      target: selectedTarget,
      message: msgController.text.isEmpty ? 'No additional message' : msgController.text,
      createdAt: DateTime.now(),
      status: 'Active',
    );

    await ref.read(firestoreServiceProvider).addAlert(alert);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Crisis Alert Broadcast Activated to $selectedTarget'), backgroundColor: AppTheme.critical),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Trigger Emergency Alert')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Live Preview', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
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
              
              const Text('Alert Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const Gap(16),
              GridView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.9, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemCount: alertTypes.length,
                itemBuilder: (ctx, i) {
                  bool isSel = selectedType == alertTypes[i]['name'];
                  return InkWell(
                    onTap: () => setState(() => selectedType = alertTypes[i]['name']),
                    child: Container(
                      decoration: BoxDecoration(color: isSel ? AppTheme.primaryLight : AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSel ? AppTheme.primary : AppTheme.divider, width: 1)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(alertTypes[i]['icon'], size: 28, color: isSel ? AppTheme.primary : AppTheme.textSecondary),
                          const Gap(8),
                          Text(alertTypes[i]['name'], textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: isSel ? FontWeight.w600 : FontWeight.normal, color: isSel ? AppTheme.primaryDark : AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }
              ),
              const Gap(32),

              const Text('Severity Level', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const Gap(16),
              Row(
                children: [
                  Expanded(flex:2, child: _buildSeverityCard('CRITICAL', AppTheme.critical)),
                ]
              ),
              const Gap(12),
              Row(
                children: [
                  Expanded(child: _buildSeverityCard('URGENT', AppTheme.urgent)),
                  const Gap(12),
                  Expanded(child: _buildSeverityCard('STABLE', AppTheme.stable)),
                ],
              ),
              const Gap(32),
              
              const Text('Target Audience', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const Gap(8),
              Wrap(
                spacing: 8,
                children: ['All Staff', 'Doctors Only', 'Nurses Only'].map((e) {
                  bool selected = selectedTarget == e;
                  return ChoiceChip(
                    label: Text(e, style: TextStyle(color: selected ? AppTheme.surface : AppTheme.textSecondary)),
                    selected: selected,
                    selectedColor: AppTheme.primary,
                    onSelected: (val) => setState(() => selectedTarget = e),
                  );
                }).toList(),
              ),
              const Gap(24),
              
              const Text('Additional Communication', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Gap(8),
              TextFormField(
                controller: msgController,
                maxLines: 3,
                onChanged: (_) => setState((){}),
                decoration: const InputDecoration(
                  hintText: 'Enter specific emergency details, ward locations, or instructions...',
                  filled: true,
                  fillColor: AppTheme.surface,
                ),
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
                      Icon(Icons.warning_amber_rounded, size: 24, color: Colors.white),
                      Gap(12),
                      Text('Broadcast Alert Now', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              )
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? color : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : AppTheme.divider, width: 1),
        ),
        child: Center(
          child: Text(
            level, 
            style: TextStyle(
              fontWeight: FontWeight.w600, 
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontSize: 14
            )
          )
        ),
      ),
    );
  }
}
