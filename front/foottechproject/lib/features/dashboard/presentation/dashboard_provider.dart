import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(client: ref.watch(apiClientProvider));
});

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) {
  return ref.watch(dashboardRepositoryProvider).getMyDashboard();
});

final seasonBilanProvider = FutureProvider.autoDispose<List<SeasonBilanEntry>>((ref) {
  final teamId = ref.watch(authControllerProvider).value?.teamId;
  if (teamId == null) return Future.value(<SeasonBilanEntry>[]);
  return ref.watch(dashboardRepositoryProvider).getSeasonBilan(teamId: teamId);
});
