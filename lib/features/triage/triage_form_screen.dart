import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../app/theme.dart';
import '../../core/triage_engine.dart';

class TriageFormScreen extends ConsumerStatefulWidget {
  const TriageFormScreen({super.key});

  @override
  ConsumerState<TriageFormScreen> createState() => _TriageFormScreenState();
}

class _TriageFormScreenState extends ConsumerState<TriageFormScreen> {
  final TextEditingController bpController = TextEditingController();
  final TextEditingController hrController = TextEditingController();
  final TextEditingController tempController = TextEditingController();
  final TextEditingController keywordsController = TextEditingController();
  
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  
  String currentStatus = 'Evaluating...';
  Color statusColor = AppTheme.textSecondary;

  @override
  void initState() {
    super.initState();
    
    // Pre-fill from query parameters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = GoRouterState.of(context).uri;
      final name = uri.queryParameters['name'];
      final age = uri.queryParameters['age'];
      final gender = uri.queryParameters['gender'];
      final id = uri.queryParameters['id'];

      if (name != null) nameController.text = name;
      if (age != null) ageController.text = age;
      if (gender != null) genderController.text = gender;
      
      _evaluateForm();
    });

    bpController.addListener(_evaluateForm);
    hrController.addListener(_evaluateForm);
    tempController.addListener(_evaluateForm);
    keywordsController.addListener(_evaluateForm);
  }

  void _evaluateForm() {
    final bp = bpController.text;
    final hrStr = hrController.text;
    final tempStr = tempController.text;
    
    int? systolic;
    int? diastolic;
    if (bp.contains('/')) {
      final parts = bp.split('/');
      systolic = int.tryParse(parts[0]);
      diastolic = int.tryParse(parts[1]);
    }

    final hr = int.tryParse(hrStr);
    final temp = double.tryParse(tempStr);
    
    final result = TriageEngine.classify(
      bp: systolic != null && diastolic != null ? '$systolic/$diastolic' : bp, 
      heartRate: hr ?? 80, 
      temp: temp ?? 37.0, 
      symptoms: keywordsController.text
    );
    final level = result.level;

    setState(() {
      currentStatus = level;
      if (level == 'CRITICAL') statusColor = AppTheme.critical;
      else if (level == 'URGENT') statusColor = AppTheme.urgent;
      else statusColor = AppTheme.stable;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Clinical Triage Assessment')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  border: Border.all(color: statusColor, width: 2),
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Column(
                  children: [
                    const Text('Live Pre-Condition Class', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    const Gap(8),
                    Text(currentStatus, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: statusColor)),
                  ],
                ),
              ),
              const Gap(32),

              const Text('Patient Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const Gap(16),
              _buildInputRow('Full Name', nameController, 'e.g., John Doe', Icons.person_outline),
              const Gap(16),
              Row(
                children: [
                  Expanded(child: _buildInputRow('Age', ageController, 'e.g., 45', Icons.calendar_today_outlined, keyboardType: TextInputType.number)),
                  const Gap(16),
                  Expanded(child: _buildInputRow('Gender', genderController, 'e.g., Male', Icons.wc_outlined)),
                ],
              ),
              const Gap(32),

              const Text('Vitals Entry', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const Gap(16),
              _buildInputRow('Blood Pressure', bpController, 'e.g., 120/80', Icons.monitor_heart_outlined),
              const Gap(16),
              _buildInputRow('Heart Rate (BPM)', hrController, 'e.g., 75', Icons.favorite_border_outlined, keyboardType: TextInputType.number),
              const Gap(16),
              _buildInputRow('Temperature (°C)', tempController, 'e.g., 36.6', Icons.device_thermostat_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const Gap(32),

              const Text('Symptomatic Keywords', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Gap(16),
              TextField(
                controller: keywordsController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Enter comma-separated identifiers (e.g. bleeding, chest pain)'),
              ),
              const Gap(40),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    final id = GoRouterState.of(context).uri.queryParameters['id'] ?? '';
                    
                    String toTitleCase(String text) => text.trim().split(' ').where((w) => w.isNotEmpty).map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
                    
                    final formattedName = toTitleCase(nameController.text);
                    final formattedGender = toTitleCase(genderController.text);

                    final nameArgs = formattedName.isNotEmpty ? 'name=${Uri.encodeComponent(formattedName)}&' : '';
                    final ageArgs = ageController.text.isNotEmpty ? 'age=${Uri.encodeComponent(ageController.text)}&' : '';
                    final genderArgs = formattedGender.isNotEmpty ? 'gender=${Uri.encodeComponent(formattedGender)}&' : '';
                    final idArg = id.isNotEmpty ? 'id=$id' : '';
                    context.push('/triage_result/$currentStatus?$nameArgs$ageArgs$genderArgs$idArg');
                  }, 
                  child: const Text('Finalize Assessment')
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputRow(String label, TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
        const Gap(8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}
