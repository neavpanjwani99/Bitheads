import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../app/theme.dart';
import '../../../models/patient_model.dart';
import '../../../services/gemini_service.dart';
import '../../../mock/mock_data.dart';

class AIClinicalAnalysisScreen extends ConsumerStatefulWidget {
  final PatientModel patient;
  const AIClinicalAnalysisScreen({super.key, required this.patient});

  @override
  ConsumerState<AIClinicalAnalysisScreen> createState() => _AIClinicalAnalysisScreenState();
}

class _AIClinicalAnalysisScreenState extends ConsumerState<AIClinicalAnalysisScreen> {
  bool _isLoading = true;
  List<String> _sections = [];
  String _rawOutput = '';

  @override
  void initState() {
    super.initState();
    _performAnalysis();
  }

  Future<void> _performAnalysis() async {
    final patientData = '''
Patient: ${widget.patient.name} (${widget.patient.age}y ${widget.patient.gender})
Triage Level: ${widget.patient.triageLevel}
Current Status: ${widget.patient.attendanceStatus}
Primary Concern: ${widget.patient.vitalsSummary}

Vitals History (Recent Trend):
${widget.patient.vitalsTrend.join(' -> ')}

Clinical Progress Notes: 
${widget.patient.notes.isNotEmpty ? widget.patient.notes.join('\n- ') : 'No notes recorded.'}

Active Medical Orders:
${widget.patient.orders.isNotEmpty ? widget.patient.orders.join('\n- ') : 'No orders pending.'}
''';

    try {
      final result = await GeminiService.analyzeClinical(patientData: patientData);
      
      if (!mounted) return;

      setState(() {
        _rawOutput = result;
        final parts = result.split('---SECTION---');
        _sections = parts.map((s) => s.trim()).toList();
        while (_sections.length < 4) {
          _sections.add('Information unavailable for this section.');
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _rawOutput = 'Analysis Error: $e';
        _sections = ['Error','Error','Error','Error'];
        _isLoading = false;
      });
    }
  }

  void _saveToNotes() {
    final reportNote = 'AI Clinical Synthesis — ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}:\n$_rawOutput';
    final updated = widget.patient.copyWith(notes: [...widget.patient.notes, reportNote]);
    ref.read(patientsProvider.notifier).updatePatient(updated);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI Synthesis saved to Patient Notes.')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading ? _buildLoading() : _buildContent(),
          ),
          if (!_isLoading) _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(color: AppTheme.surface, border: Border(bottom: BorderSide(color: AppTheme.divider))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.psychology_outlined, color: AppTheme.primaryDark, size: 24),
          ),
          const Gap(12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Clinical Synthesizer', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              Text('Analyzing ${widget.patient.name}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const Gap(24),
          const Text('Synthesizing Differential Diagnoses...', style: TextStyle(color: AppTheme.textSecondary)),
          const Gap(8),
          const Text('Processing clinical context via Gemini Flash', style: TextStyle(fontSize: 10, color: AppTheme.divider)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final titles = [
      'Differential Diagnoses',
      'Immediate Interventions',
      'Priority Monitoring',
      'Discharge/Transfer Criteria'
    ];
    final icons = [
      Icons.troubleshoot_outlined,
      Icons.medical_information_outlined,
      Icons.monitor_heart_outlined,
      Icons.exit_to_app_outlined
    ];
    final colors = [
      AppTheme.critical,
      AppTheme.primary,
      AppTheme.urgent,
      AppTheme.stable
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colors[index].withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(icons[index], color: colors[index], size: 20),
                    const Gap(12),
                    Text(titles[index], style: TextStyle(fontWeight: FontWeight.bold, color: colors[index])),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _sections[index],
                  style: const TextStyle(fontSize: 14, height: 1.5, color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppTheme.surface, border: Border(top: BorderSide(color: AppTheme.divider))),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Discard'),
            ),
          ),
          const Gap(12),
          Expanded(
            child: ElevatedButton(
              onPressed: _saveToNotes,
              child: const Text('Save to Notes'),
            ),
          ),
        ],
      ),
    );
  }
}
