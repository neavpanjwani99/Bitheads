import 'package:flutter/material.dart';
import '../../app/theme.dart';

class SeverityBadge extends StatelessWidget {
  final String severity; // CRITICAL, URGENT, STABLE
  final double fontSize;

  const SeverityBadge({super.key, required this.severity, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor = Colors.white;

    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        bgColor = AppTheme.critical;
        break;
      case 'URGENT':
        bgColor = AppTheme.urgent;
        break;
      case 'STABLE':
        bgColor = AppTheme.stable;
        break;
      default:
        bgColor = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
