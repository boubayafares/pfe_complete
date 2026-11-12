import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/team_model.dart';
import '../data/teams_repository.dart';

final teamsRepositoryProvider = Provider<TeamsRepository>((ref) {
  return TeamsRepository(apiClient: ref.watch(apiClientProvider));
});

final myTeamsProvider = FutureProvider.autoDispose<List<Team>>((ref) async {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return [];
  return ref.watch(teamsRepositoryProvider).listMine();
});

final myTeamProvider = FutureProvider.autoDispose<Team?>((ref) async {
  final teamId = ref.watch(authControllerProvider).value?.teamId;
  if (teamId == null) return null;
  return ref.watch(teamsRepositoryProvider).getMyTeam(teamId);
});

final teamStaffProvider = FutureProvider.autoDispose<List<TeamStaffMember>>((
  ref,
) async {
  final teamId = ref.watch(authControllerProvider).value?.teamId;
  if (teamId == null) return [];
  return ref.watch(teamsRepositoryProvider).getStaff(teamId);
});
