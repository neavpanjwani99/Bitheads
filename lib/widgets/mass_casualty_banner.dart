import 'package:flutter/material.dart';
import '../app/theme.dart';

class MassCasualtyBanner extends StatefulWidget {
  const MassCasualtyBanner({super.key});

  @override
  State<MassCasualtyBanner> createState() => _MassCasualtyBannerState();
}

class _MassCasualtyBannerState extends State<MassCasualtyBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.3).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.critical,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _animation,
            child: const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'MASS CASUALTY MODE ACTIVE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          ScaleTransition(
            scale: _animation,
            child: const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
