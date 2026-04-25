import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../models/alert_model.dart';
import '../../../app/theme.dart';
import '../../../widgets/severity_badge.dart';

class AlertCard extends StatefulWidget {
  final AlertModel alert;
  final VoidCallback onTap;

  const AlertCard({super.key, required this.alert, required this.onTap});

  @override
  State<AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<AlertCard> {
  late Timer _timer;
  String _activeTime = '';
  bool _escalating = false;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => _updateTime());
  }

  void _updateTime() {
    if (!mounted) return;
    final diff = DateTime.now().difference(widget.alert.createdAt);
    
    setState(() {
      _activeTime = '${diff.inMinutes}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}';
      if (diff.inMinutes >= 2 && widget.alert.status == 'Active') {
        _escalating = true;
      } else {
        _escalating = false;
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bColor = Colors.grey;
    if (widget.alert.severity == 'CRITICAL') bColor = AppTheme.critical;
    if (widget.alert.severity == 'URGENT') bColor = AppTheme.urgent;
    if (widget.alert.severity == 'STABLE') bColor = AppTheme.stable;

    bool isCritical = widget.alert.severity == 'CRITICAL';

    Widget card = Card(
      color: isCritical ? AppTheme.critical.withValues(alpha: 0.05) : AppTheme.surface,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCritical 
          ? BorderSide(color: AppTheme.critical.withValues(alpha: 0.5), width: 1.5)
          : BorderSide(color: AppTheme.divider, width: 1),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: bColor, width: 8)),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SeverityBadge(severity: widget.alert.severity),
                  if (_escalating)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.critical, borderRadius: BorderRadius.circular(4)),
                      child: const Text('⚠️ ESCALATING', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ).animate(onPlay: (c)=>c.repeat(reverse: true)).fade(begin: 0.5, end: 1),
                ],
              ),
              const Gap(12),
              Text(widget.alert.type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Gap(4),
              Text(widget.alert.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
              const Gap(12),
              Row(
                children: [
                   const Icon(Icons.timer_outlined, size: 14, color: AppTheme.critical),
                   const Gap(4),
                   Text(_activeTime, style: const TextStyle(color: AppTheme.critical, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                   const Spacer(),
                    if (widget.alert.status == 'Acknowledged' && widget.alert.assignedTo != null)
                      Row(
                        children: [
                          const Icon(Icons.verified_user, size: 14, color: AppTheme.primary),
                          const Gap(4),
                          Text('Assigned to ${widget.alert.assignedTo}', style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      )
                   else
                     const Text('Unassigned', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              )
            ],
          ),
        ),
      ),
    );

    if (isCritical) {
      return card.animate(onPlay: (c) => c.repeat()).shimmer(duration: 2000.ms, color: Colors.white24);
    }
    return card;
  }
}
