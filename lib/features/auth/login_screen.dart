import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../app/theme.dart';
import '../../providers/session_provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _pwdController = TextEditingController();

  String selectedRole = 'Admin';
  bool _obscurePwd = true;
  bool _isLoading = false;

  String? _emailError;
  String? _pwdError;

  void _validateAndSubmit() {
    setState(() {
      _emailError = null;
      _pwdError = null;
    });

    final email = _emailController.text.trim();
    final pwd = _pwdController.text;

    bool valid = true;

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      _emailError = "Enter a valid staff email address";
      valid = false;
    }

    if (pwd.length < 6) {
      _pwdError = "Password must be at least 6 characters";
      valid = false;
    }

    if (!valid) return;

    _performLogin();
  }

  Future<void> _performLogin() async {
    setState(() => _isLoading = true);
    
    try {
      await ref.read(authNotifierProvider.notifier).login(
        _emailController.text.trim(),
        _pwdController.text,
      );

      if (!mounted) return;
      
      final user = ref.read(authNotifierProvider);
      if (user != null) {
        if (user.role != selectedRole) {
          throw 'Incorrect role selected for this account.';
        }
        
        ref.read(sessionProvider.notifier).startSession(user.role);

        if (user.role == 'Admin') {
          context.go('/admin');
        } else if (user.role == 'Doctor') {
          context.go('/doctor');
        } else {
          context.go('/nurse');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.critical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isFormFilled = _emailController.text.isNotEmpty && _pwdController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Top Section - Dark Solid Banner
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              color: AppTheme.primaryDark,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_hospital_outlined, size: 64, color: AppTheme.surface),
                      const Gap(16),
                      const Text('RapidCare', style: TextStyle(color: AppTheme.surface, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      const Gap(16),
                      Container(height: 1, color: AppTheme.divider.withValues(alpha: 0.2), width: 120),
                      const Gap(16),
                      const Text('Hospital Crisis Coordination System', style: TextStyle(color: AppTheme.primaryLight, fontSize: 16)),
                      const Spacer(),
                      const Text('Authorized Personnel Only', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      const Gap(24),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Bottom Section - Clean Form
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('System Login', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), textAlign: TextAlign.center),
                  const Gap(32),
                  
                  // Role Selector (Soft Pills)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['Admin', 'Doctor', 'Nurse'].map((role) {
                      bool isSel = selectedRole == role;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedRole = role),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel ? AppTheme.primaryLight : AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSel ? AppTheme.primary : AppTheme.divider),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              role, 
                              style: TextStyle(color: isSel ? AppTheme.primary : AppTheme.textSecondary, fontWeight: isSel ? FontWeight.w600 : FontWeight.normal)
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Gap(32),

                  _buildField('Staff Email', _emailController, hint: 'name@hospital.com', error: _emailError),
                  const Gap(20),
                  _buildField('Password', _pwdController, obscure: _obscurePwd, toggleObscure: () => setState(() => _obscurePwd = !_obscurePwd), error: _pwdError),
                  
                  const Gap(12),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('Contact IT Administrator for access', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ),
                  const Gap(40),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isFormFilled && !_isLoading ? _validateAndSubmit : null,
                      child: _isLoading 
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: AppTheme.surface, strokeWidth: 2))
                        : const Text('Login'),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      )
    );
  }

  Widget _buildField(String label, TextEditingController controller, {String? hint, bool obscure = false, VoidCallback? toggleObscure, String? error}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 13)),
        const Gap(8),
        TextField(
          controller: controller,
          obscureText: obscure,
          onChanged: (_) => setState((){}),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: toggleObscure != null 
              ? IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.textSecondary, size: 20), onPressed: toggleObscure)
              : null,
          ),
        ),
        if (error != null) ...[
          const Gap(4),
          Text(error, style: const TextStyle(color: AppTheme.critical, fontSize: 12)),
        ]
      ],
    );
  }
}
