import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/bed_model.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import 'package:gap/gap.dart';

class BedCard extends ConsumerWidget {
  final BedModel bed;
  final VoidCallback onTap;

  const BedCard({super.key, required this.bed, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color statusColor;
    String helperText = '';
    IconData icon = Icons.bed;
    
    switch (bed.status) {
      case 'Available':
        statusColor = AppTheme.stable;
        final currentUser = ref.watch(authNotifierProvider);
        helperText = currentUser?.role == 'Admin' ? 'Tap to assign' : '';
        icon = Icons.bed;
        break;
      case 'Occupied':
        statusColor = AppTheme.critical;
        helperText = 'Patient Active';
        icon = Icons.person;
        break;
      case 'Maintenance':
        statusColor = Colors.orange;
        helperText = 'Under Repair';
        icon = Icons.build_outlined;
        break;
      default:
        statusColor = AppTheme.textSecondary;
        icon = Icons.bed;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(bed.id, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: -1)),
              const Gap(4),
              if (bed.status == 'Occupied')
                Flexible(
                  child: Text(
                    bed.patientName ?? 'Patient',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                )
              else
                Flexible(child: Icon(icon, color: statusColor, size: 36)),
              const Gap(4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bed.status.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const Gap(4),
              if (helperText.isNotEmpty)
                Text(helperText, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
