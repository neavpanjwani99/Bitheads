import 'package:flutter/material.dart';
import '../../app/theme.dart';

class RoleAvatar extends StatelessWidget {
  final String name;
  final String role; // Admin, Doctor, Nurse
  final bool isAvailable;
  final double radius;

  const RoleAvatar({
    super.key,
    required this.name,
    required this.role,
    this.isAvailable = false,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    String initials = name.trim().isNotEmpty 
        ? name.trim().split(' ').where((s) => s.isNotEmpty).map((e) => e[0]).take(2).join().toUpperCase() 
        : '?';

    Color bgColor = AppTheme.primary;
    if (role == 'Nurse') bgColor = AppTheme.accent;
    if (role == 'Admin') bgColor = AppTheme.textSecondary;

    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: bgColor.withOpacity(0.2),
          child: Text(
            initials,
            style: TextStyle(
              color: bgColor,
              fontWeight: FontWeight.bold,
              fontSize: radius * 0.8,
            ),
          ),
        ),
        if (role != 'Admin')
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: radius * 0.6,
              height: radius * 0.6,
              decoration: BoxDecoration(
                color: isAvailable ? AppTheme.stable : AppTheme.critical,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          )
      ],
    );
  }
}
