import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/triage_engine.dart';
import '../../models/patient_model.dart';
import '../../mock/mock_data.dart';
import 'dart:math';

class TriageFormScreen extends ConsumerStatefulWidget {
  const TriageFormScreen({super.key});

  @override
  ConsumerState<TriageFormScreen> createState() => _TriageFormScreenState();
}

class _TriageFormScreenState extends ConsumerState<TriageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final patientNameController = TextEditingController(text: 'Incoming Patient ${Random().nextInt(100)}');
  final bpController = TextEditingController();
  final hrController = TextEditingController();
  final tempController = TextEditingController();
  final symController = TextEditingController();

  void _submitTriage() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // Simulate analysis
      await Future.delayed(const Duration(seconds: 1));
      
      int hr = int.tryParse(hrController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 80;
      double temp = double.tryParse(tempController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 37.0;

      TriageResult result = TriageEngine.classify(
        bp: bpController.text, 
        heartRate: hr, 
        temp: temp, 
        symptoms: symController.text
      );

      // Create patient in mock data automatically for display
      final p = PatientModel(
        id: 'P-${Random().nextInt(1000)}',
        name: patientNameController.text,
        age: 40 + Random().nextInt(30),
        gender: Random().nextBool() ? 'M' : 'F',
        triageLevel: result.level,
        vitalsSummary: 'BP: ${bpController.text}, HR: $hr, Temp: $temp',
        lastVitalsTime: DateTime.now(),
        vitalStatus: result.level == 'CRITICAL' ? 'critical' : (result.level == 'URGENT' ? 'warning' : 'normal')
      );
      
      // Assume Provider update
      ref.read(patientsProvider.notifier).state = [...ref.read(patientsProvider), p];

      if (mounted) {
        context.pushReplacement('/triage_result/${result.level}?reason=${Uri.encodeComponent(result.reason)}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF), // Eye strain fix
      appBar: AppBar(
        title: const Text('Patient Triage', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputCard('Patient Identifier', patientNameController, 'Name or ID'),
              const Gap(16),
              const Text('Vitals Input', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
              const Gap(8),
              
              _buildVitalCard(
                'Blood Pressure', 'e.g. 120/80', 'Normal: 90/60 - 120/80', 
                Icons.bloodtype, bpController,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (!val.contains('/')) return 'Format Sys/Dia (e.g. 120/80)';
                  return null;
                }
              ),
              const Gap(12),
              _buildVitalCard(
                'Heart Rate', 'bpm', 'Normal: 60-100 bpm', 
                Icons.favorite_border, hrController,
                type: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Required' : null
              ),
              const Gap(12),
              _buildVitalCard(
                'Temperature', '°C', 'Normal: 36.5 - 37.5 °C', 
                Icons.thermostat, tempController,
                type: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) => val!.isEmpty ? 'Required' : null
              ),
              const Gap(16),
              
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Symptoms & Observations', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Gap(12),
                      TextFormField(
                        controller: symController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Describe patient complaints (e.g. "chest pain", "unconscious")...',
                          filled: true,
                          fillColor: AppTheme.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(32),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: _isLoading ? null : _submitTriage,
                  child: _isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Run Triage Assessment', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVitalCard(String title, String hint, String range, IconData icon, TextEditingController controller, {TextInputType? type, String? Function(String?)? validator}) {
    // Dynamic border color based on value entered (live validation visual)
    Color activeColor = AppTheme.divider;
    if (controller.text.isNotEmpty) {
      if (title.contains('Blood')) {
        activeColor = TriageEngine.getVitalStatus('bp', controller.text) == 'critical' ? AppTheme.critical : (TriageEngine.getVitalStatus('bp', controller.text) == 'warning' ? AppTheme.urgent : AppTheme.stable);
      } else if (title.contains('Heart')) {
        activeColor = TriageEngine.getVitalStatus('hr', controller.text) == 'critical' ? AppTheme.critical : (TriageEngine.getVitalStatus('hr', controller.text) == 'warning' ? AppTheme.urgent : AppTheme.stable);
      } else if (title.contains('Temp')) {
        activeColor = TriageEngine.getVitalStatus('temp', controller.text) == 'critical' ? AppTheme.critical : (TriageEngine.getVitalStatus('temp', controller.text) == 'warning' ? AppTheme.urgent : AppTheme.stable);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: activeColor, width: 2),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppTheme.primaryDark),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                Text(range, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: TextFormField(
              controller: controller,
              keyboardType: type,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              onChanged: (_) => setState(() {}), // triggers color rebuild
              decoration: InputDecoration(
                hintText: hint,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.divider)),
              ),
              validator: validator,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(String title, TextEditingController controller, String hint) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
            border: InputBorder.none,
            hintText: hint,
          ),
        ),
      ),
    );
  }
}
