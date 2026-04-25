import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/staff_model.dart';
import '../mock/mock_data.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider((ref) {
  return ref.watch(authServiceProvider).userStream;
});

class AuthNotifier extends Notifier<StaffModel?> {
  @override
  StaffModel? build() {
    return null;
  }

  Future<void> login(String email, String password) async {
    final authService = ref.read(authServiceProvider);
    try {
      final staff = await authService.signIn(email, password);
      if (staff != null) {
        state = staff;
        ref.read(currentUserProvider.notifier).setUser(staff);
      } else {
        throw 'User data not found in registration.';
      }
    } catch (e) {
      state = null;
      rethrow;
    }
  }

  void logout() async {
    await ref.read(authServiceProvider).signOut();
    state = null;
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, StaffModel?>(AuthNotifier.new);
