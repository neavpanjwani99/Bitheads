import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../mock/mock_data.dart';
import '../../widgets/frosted_glass.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String selectedRole = 'Admin';
  
  void handleLogin() {
    final staff = ref.read(staffProvider);
    final user = staff.firstWhere((s) => s.role == selectedRole, 
      orElse: () => staff.first);
    
    ref.read(currentUserProvider.notifier).setUser(user);
    
    if (selectedRole == 'Admin') context.go('/admin');
    else if (selectedRole == 'Doctor') context.go('/doctor');
    else context.go('/nurse');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDark, AppTheme.primary],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_box, size: 80, color: Colors.white)
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1500.ms, curve: Curves.easeInOut),
                const Gap(16),
                Text('RapidCare', style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.white)),
                Text('Every Second Counts', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
                const Gap(48),
                
                FrostedGlass(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        _buildGlassField('Email', Icons.email),
                        const Gap(16),
                        _buildGlassField('Password', Icons.lock, obscure: true),
                        const Gap(32),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: ['Admin', 'Doctor', 'Nurse'].map((role) {
                            bool isSel = selectedRole == role;
                            return GestureDetector(
                              onTap: () => setState(() => selectedRole = role),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSel ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white),
                                ),
                                child: Text(
                                  role, 
                                  style: TextStyle(
                                    color: isSel ? AppTheme.primaryDark : Colors.white,
                                    fontWeight: FontWeight.bold
                                  )
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const Gap(32),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primaryDark,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                            ),
                            onPressed: handleLogin,
                            child: const Text('Access System'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassField(String label, IconData icon, {bool obscure = false}) {
    return TextFormField(
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: false,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white54, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}
