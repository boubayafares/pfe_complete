import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../data/attendance_model.dart';
import '../data/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(client: ref.watch(apiClientProvider));
});

final attendanceListProvider = FutureProvider.autoDispose
    .family<List<AttendanceRecord>, int>((ref, trainingId) {
      return ref.watch(attendanceRepositoryProvider).listByTraining(trainingId);
    });
