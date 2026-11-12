import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../data/ai_insights_repository.dart';

final aiInsightsRepositoryProvider = Provider<AiInsightsRepository>((ref) {
  return AiInsightsRepository(apiClient: ref.watch(apiClientProvider));
});

final playerTrendProvider = FutureProvider.autoDispose.family<PlayerTrend, int>(
  (ref, playerId) {
    return ref.watch(aiInsightsRepositoryProvider).getPlayerTrend(playerId);
  },
);

final expertProjectModelProvider =
    FutureProvider.autoDispose<ExpertProjectModel>((ref) {
      return ref.watch(aiInsightsRepositoryProvider).getExpertProjectModel();
    });
