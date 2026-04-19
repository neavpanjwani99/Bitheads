import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../app/theme.dart';
import '../../mock/mock_data.dart';
import 'dart:math';

// Custom Shake animation widget for errors
class ShakeWidget extends StatefulWidget {
  final Widget child;
  final bool shake;
  const ShakeWidget({super.key, required this.child, required this.shake});

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void didUpdateWidget(ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final sineValue = sin(3 * pi * _controller.value);
        return Transform.translate(
          offset: Offset(sineValue * 10, 0),
          child: child,
        );
      },
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _idController = TextEditingController();
  final _pwdController = TextEditingController();

  String selectedRole = 'Admin';
  bool _obscurePwd = true;
  bool _isLoading = false;
  bool _hasError = false;

  String? _emailError;
  String? _idError;
  String? _pwdError;

  void _validateAndSubmit() {
    setState(() {
      _emailError = null;
      _idError = null;
      _pwdError = null;
      _hasError = false;
    });

    final email = _emailController.text;
    final id = _idController.text;
    final pwd = _pwdController.text;

    bool valid = true;

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      _emailError = "Enter a valid staff email address";
      valid = false;
    }

    if (!id.startsWith('HOSP-')) {
      _idError = "Invalid Hospital ID format (e.g. HOSP-XXX)";
      valid = false;
    }

    if (pwd.length < 6) {
      _pwdError = "Password must be at least 6 characters";
      valid = false;
    }

    if (!valid) {
      setState(() => _hasError = true);
      return;
    }

    _performLogin();
  }

  Future<void> _performLogin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Mock DB check

    if (!mounted) return;
    
    final staff = ref.read(staffProvider);
    final user = staff.firstWhere((s) => s.role == selectedRole, orElse: () => staff.first);
    ref.read(currentUserProvider.notifier).setUser(user);

    if (selectedRole == 'Admin') context.go('/admin');
    else if (selectedRole == 'Doctor') context.go('/doctor');
    else context.go('/nurse');
  }

  void _showBiometricSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return const BiometricSheet();
      }
    ).then((success) {
      if (success == true) {
        _performLogin();
      }
    });
  }

  void _triggerEmergencyOverride() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: AppTheme.critical),
              Gap(8),
              Text('Emergency Override', style: TextStyle(color: AppTheme.critical, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text("This access is logged, timestamped, and monitored. Use only in emergencies."),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.critical),
              onPressed: () {
                Navigator.pop(context);
                final staff = ref.read(staffProvider);
                final overrideAdmin = staff.firstWhere((s) => s.role == 'Admin', orElse: () => staff.first);
                ref.read(currentUserProvider.notifier).setUser(overrideAdmin);
                context.go('/admin');
              }, 
              child: const Text('Confirm Override')
            )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isFormFilled = _emailController.text.isNotEmpty && _idController.text.isNotEmpty && _pwdController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628), // Navy blue solid
      body: Column(
        children: [
          // Top Section
          Expanded(
            flex: 4,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_box, size: 72, color: Colors.white),
                    const Gap(16),
                    const Text('RapidCare', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    const Gap(16),
                    Container(height: 1, color: Colors.white24, width: double.infinity),
                    const Gap(16),
                    const Text('Hospital Crisis Coordination System', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const Spacer(),
                    const Text('⚠️ Authorized Personnel Only', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                    const Gap(16),
                  ],
                ),
              ),
            ),
          ),
          // Bottom Section
          Expanded(
            flex: 6,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ShakeWidget(
                  shake: _hasError,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Role Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ['Admin', 'Doctor', 'Nurse'].map((role) {
                          bool isSel = selectedRole == role;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => selectedRole = role),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSel ? AppTheme.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.primary, width: 1.5),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  role, 
                                  style: TextStyle(
                                    color: isSel ? Colors.white : AppTheme.primary,
                                    fontWeight: FontWeight.bold
                                  )
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const Gap(32),

                      _buildCleanField('Staff Email', _emailController, hint: 'name@hospital.com', errorText: _emailError),
                      const Gap(16),
                      _buildCleanField('Hospital ID', _idController, hint: 'e.g. HOSP-MUM-001', errorText: _idError),
                      const Gap(16),
                      _buildCleanField('Password', _pwdController, obscure: _obscurePwd, toggleObscure: () => setState(() => _obscurePwd = !_obscurePwd), errorText: _pwdError),
                      
                      const Gap(8),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text('Forgot credentials? Contact IT Admin', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ),
                      const Gap(32),

                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            disabledBackgroundColor: Colors.grey.shade400,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: isFormFilled && !_isLoading ? _validateAndSubmit : null,
                          child: _isLoading 
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const Gap(16),

                      SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.textSecondary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _showBiometricSheet,
                          icon: const Icon(Icons.fingerprint, color: AppTheme.textPrimary),
                          label: const Text('Login with Biometric', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      
                      const Gap(40),
                      Center(
                        child: TextButton.icon(
                          onPressed: _triggerEmergencyOverride,
                          icon: const Icon(Icons.emergency, color: AppTheme.critical, size: 16),
                          label: const Text('🚨 Emergency Override Access', style: TextStyle(color: AppTheme.critical, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      )
    );
  }

  Widget _buildCleanField(String label, TextEditingController controller, {String? hint, bool obscure = false, VoidCallback? toggleObscure, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14)),
        const Gap(8),
        TextField(
          controller: controller,
          obscureText: obscure,
          onChanged: (_) => setState((){}),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.critical, width: 2)),
            suffixIcon: toggleObscure != null 
              ? IconButton(
                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary),
                  onPressed: toggleObscure,
                )
              : null,
          ),
        )
      ],
    );
  }
}

class BiometricSheet extends StatefulWidget {
  const BiometricSheet({super.key});

  @override
  State<BiometricSheet> createState() => _BiometricSheetState();
}

class _BiometricSheetState extends State<BiometricSheet> {
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _simulateScan();
  }

  void _simulateScan() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _success = true);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text('Biometric Authentication', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            Icon(
              _success ? Icons.check_circle : Icons.fingerprint, 
              size: 80, 
              color: _success ? AppTheme.stable : AppTheme.primary
            ),
            const Spacer(),
            Text(
              _success ? 'Authentication Verified' : 'Place finger on sensor',
              style: TextStyle(color: _success ? AppTheme.stable : AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 16)
            ),
          ],
        ),
      ),
    );
  }
}
