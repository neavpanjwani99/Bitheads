import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';

class TriageFormScreen extends StatefulWidget {
  const TriageFormScreen({super.key});

  @override
  State<TriageFormScreen> createState() => _TriageFormScreenState();
}

class _TriageFormScreenState extends State<TriageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final bpController = TextEditingController();
  final hrController = TextEditingController();
  final tempController = TextEditingController();
  final symController = TextEditingController();

  void _submitTriage() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      // Simulated API Delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Basic AI logic map for visuals
      String result = 'STABLE';
      int hr = int.tryParse(hrController.text) ?? 80;
      if (hr > 120 || hr < 40) result = 'CRITICAL';
      else if (hr > 100) result = 'URGENT';
      
      if (mounted) {
        context.push('/triage_result/$result');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monitor_heart, color: AppTheme.primaryDark),
            Gap(8),
            Text('Patient Triage Assessment'),
          ],
        )
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildVitalCard(
                'Blood Pressure', 'e.g. 120/80', '(Sys/Dia) Normal: 120/80', 
                Icons.bloodtype, bpController,
                validator: (val) => val!.isEmpty || !val.contains('/') ? 'Invalid format' : null
              ),
              const Gap(16),
              _buildVitalCard(
                'Heart Rate', 'bpm', 'Normal: 60-100 bpm', 
                Icons.favorite_border, hrController,
                type: TextInputType.number,
                validator: (val) {
                  int? v = int.tryParse(val ?? '');
                  if (v == null) return 'Required';
                  if (v > 100 || v < 60) return 'Abnormal Range Detected';
                  return null;
                }
              ),
              const Gap(16),
              _buildVitalCard(
                'Temperature', '°C', 'Normal: 36.5 - 37.5 °C', 
                Icons.thermostat, tempController,
                type: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  double? v = double.tryParse(val ?? '');
                  if (v == null) return 'Required';
                  return null;
                }
              ),
              const Gap(16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.record_voice_over, color: AppTheme.primary),
                          const Gap(8),
                          Text('Symptoms & Observations', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      const Gap(16),
                      TextFormField(
                        controller: symController,
                        maxLines: 4,
                        decoration: const InputDecoration(hintText: 'Describe patient complaints...'),
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ).animate().fade().slideY(begin: 0.1, duration: 400.ms),
              const Gap(32),
              
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                  borderRadius: BorderRadius.circular(26)
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                  onPressed: _isLoading ? null : _submitTriage,
                  child: _isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome),
                            Gap(8),
                            Text('Analyze Patient', style: TextStyle(fontSize: 18)),
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

  Widget _buildVitalCard(String title, String hint, String range, IconData icon, TextEditingController controller, {TextInputType? type, String? Function(String?)? validator}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primary),
                const Gap(8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(range, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
            const Gap(16),
            TextFormField(
              controller: controller,
              keyboardType: type,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(hintText: hint, suffixIcon: InkWell(child: const Icon(Icons.clear), onTap: ()=>controller.clear())),
              validator: validator,
            ),
          ],
        ),
      ),
    ).animate().fade().slideY(begin: 0.2, duration: 300.ms);
  }
}
