import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../app/theme.dart';

class TriageResultScreen extends StatelessWidget {
  final String triageLevel;

  const TriageResultScreen({super.key, required this.triageLevel});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String rationale;
    IconData rIcon;

    switch (triageLevel.toUpperCase()) {
      case 'CRITICAL':
        badgeColor = AppTheme.critical;
        rationale = 'Reasoning: Severe deviations in heart rate indicate potential hemodynamic instability requiring immediate intervention. Prioritization level 1.';
        rIcon = Icons.warning_amber_rounded;
        break;
      case 'URGENT':
        badgeColor = AppTheme.urgent;
        rationale = 'Reasoning: Symptoms and vitals indicate need for prompt intervention within 1-2 hours. Vitals holding steady but abnormal. Prioritization level 2.';
        rIcon = Icons.timer;
        break;
      case 'STABLE':
      default:
        badgeColor = AppTheme.stable;
        rationale = 'Reasoning: Vitals are within normal ranges. Monitor per protocol. Prioritization level 3.';
        rIcon = Icons.check_circle_outline;
        break;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.45,
            pinned: true,
            backgroundColor: badgeColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [badgeColor, badgeColor.withValues(alpha: 0.7)],
                  )
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Gap(40),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                        child: Icon(rIcon, size: 80, color: Colors.white),
                      ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                      const Gap(16),
                      Text(
                        triageLevel.toUpperCase(),
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
                      ).animate().fade().slideY(begin: 0.5, curve: Curves.easeOutBack),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.psychology, color: AppTheme.primary),
                            Gap(8),
                            Text('AI Assessment Reasoning', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Gap(16),
                        Text(rationale, style: const TextStyle(fontSize: 16, height: 1.5)),
                      ],
                    ),
                  ),
                ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
                const Gap(24),
                const Text('Vitals Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                const Gap(8),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12, mainAxisSpacing: 12,
                  childAspectRatio: 2,
                  children: [
                    _buildVitalMini('BP', '120/80'),
                    _buildVitalMini('HR', '85 bpm'),
                    _buildVitalMini('Temp', '37.1 °C'),
                    _buildVitalMini('O2', '98%'),
                  ].animate(interval: 50.ms).fade().scale(),
                ),
                const Gap(40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Patient Record')));
                      context.pop();
                    },
                    child: const Text('Save to Patient Record'),
                  ),
                ).animate().fade(delay: 400.ms),
                const Gap(16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primary, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    onPressed: () => context.pop(),
                    child: const Text('New Triage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ).animate().fade(delay: 500.ms),
                const Gap(40),
              ]),
            ),
          )
        ],
      )
    );
  }

  Widget _buildVitalMini(String label, String val) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
