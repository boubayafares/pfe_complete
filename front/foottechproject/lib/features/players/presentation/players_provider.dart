import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/player_model.dart';
import '../data/players_repository.dart';

final playersRepositoryProvider = Provider<PlayersRepository>((ref) {
  return PlayersRepository(apiClient: ref.watch(apiClientProvider));
});

final teamPlayersProvider = FutureProvider.autoDispose<List<PlayerProfile>>((
  ref,
) async {
  final teamId = ref.watch(authControllerProvider).value?.teamId;
  if (teamId == null) return [];
  return ref.watch(playersRepositoryProvider).list();
});

final playerProfileProvider = FutureProvider.autoDispose
    .family<PlayerProfile, int>((ref, playerId) {
      return ref.watch(playersRepositoryProvider).getProfile(playerId);
    });

final playerGuardiansProvider = FutureProvider.autoDispose
    .family<List<Guardian>, int>((ref, playerId) {
      return ref.watch(playersRepositoryProvider).listGuardians(playerId);
    });

final playerAddressProvider = FutureProvider.autoDispose
    .family<PlayerAddress?, int>((ref, playerId) {
      return ref.watch(playersRepositoryProvider).getAddress(playerId);
    });

final playerSchoolInfoProvider = FutureProvider.autoDispose
    .family<SchoolInfo?, int>((ref, playerId) {
      return ref.watch(playersRepositoryProvider).getSchoolInfo(playerId);
    });

final playerSeasonProfilesProvider = FutureProvider.autoDispose
    .family<List<SeasonProfile>, int>((ref, playerId) {
      return ref.watch(playersRepositoryProvider).listSeasonProfiles(playerId);
    });

final playerInjuriesProvider = FutureProvider.autoDispose
    .family<List<PlayerInjury>, int>((ref, playerId) {
      return ref.watch(playersRepositoryProvider).listInjuries(playerId);
    });
