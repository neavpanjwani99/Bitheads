import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/work_shift_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';

// Real-time Firestore-backed provider for the current nurse's shift history
final workHistoryProvider = StreamProvider.autoDispose<List<WorkShiftModel>>((ref) {
  final user = ref.watch(authNotifierProvider);
  if (user == null) return const Stream.empty();
  return ref.read(firestoreServiceProvider).getStaffShifts(user.uid);
});
