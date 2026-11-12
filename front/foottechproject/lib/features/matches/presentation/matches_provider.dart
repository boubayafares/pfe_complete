import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/match_model.dart';
import '../data/matches_repository.dart';

final matchesRepositoryProvider = Provider<MatchesRepository>((ref) {
  return MatchesRepository(client: ref.watch(apiClientProvider));
});

final teamMatchesProvider = FutureProvider.autoDispose<List<MatchInfo>>((
  ref,
) async {
  final teamId = ref.watch(authControllerProvider).value?.teamId;
  if (teamId == null) return [];
  return ref.watch(matchesRepositoryProvider).list();
});

final matchLineupProvider = FutureProvider.autoDispose
    .family<List<LineupEntry>, int>((ref, matchId) {
      return ref.watch(matchesRepositoryProvider).getLineup(matchId);
    });

final matchRecommendationsProvider = FutureProvider.autoDispose
    .family<List<AiRecommendation>, int>((ref, matchId) {
      return ref.watch(matchesRepositoryProvider).getRecommendations(matchId);
    });

/// Loads the match via REST, then joins its socket room and applies
/// match:update events (goal/card/status/lineup) pushed by the backend.
class MatchLiveController extends FamilyAsyncNotifier<MatchInfo, int> {
  late int _matchId;

  @override
  Future<MatchInfo> build(int matchId) async {
    _matchId = matchId;
    final socketService = ref.read(socketServiceProvider);
    final socket = await socketService.connect();
    socketService.joinMatch(matchId);

    socket.on('match:update', _handleUpdate);
    ref.onDispose(() {
      socket.off('match:update', _handleUpdate);
      socketService.leaveMatch(matchId);
    });

    return ref.read(matchesRepositoryProvider).getById(matchId);
  }

  void _handleUpdate(dynamic payload) {
    if (payload is! Map) return;
    final type = payload['type'];
    if (type == 'LINEUP') {
      ref.invalidate(matchLineupProvider(_matchId));
    } else if (type == 'EVENT') {
      ref.invalidate(matchEventsProvider(_matchId));
    }
    final matchJson = payload['match'];
    if (matchJson is Map) {
      state = AsyncData(
        MatchInfo.fromJson(Map<String, dynamic>.from(matchJson)),
      );
    }
  }
}

final matchLiveControllerProvider =
    AsyncNotifierProvider.family<MatchLiveController, MatchInfo, int>(
      MatchLiveController.new,
    );

final matchEventsProvider = FutureProvider.autoDispose
    .family<List<MatchEvent>, int>((ref, matchId) {
      ref.watch(
        matchLiveControllerProvider(matchId),
      ); // re-fetch events whenever the live match updates
      return ref.watch(matchesRepositoryProvider).getEvents(matchId);
    });
