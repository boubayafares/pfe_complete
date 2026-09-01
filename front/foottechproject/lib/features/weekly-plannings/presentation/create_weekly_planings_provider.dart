import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/weekly_planing_model.dart';
import '../data/weekly_planings_repository.dart';

final weeklyPlanningRepositoryProvider = Provider<WeeklyPlanningRepository>((ref) {
  return WeeklyPlanningRepository(client: ref.watch(apiClientProvider));
});

/// Lists the weekly plannings scoped to the current user's team.
final weeklyPlanningsProvider = FutureProvider.autoDispose<List<WeeklyPlanning>>((ref) {
  final teamId = ref.watch(authControllerProvider).value?.teamId;
  if (teamId == null) return Future.value(const <WeeklyPlanning>[]);
  return ref.watch(weeklyPlanningRepositoryProvider).list(teamId: teamId);
});

final weeklyPlanningProvider =
    FutureProvider.autoDispose.family<WeeklyPlanning, int>((ref, id) {
  return ref.watch(weeklyPlanningRepositoryProvider).getById(id);
});
