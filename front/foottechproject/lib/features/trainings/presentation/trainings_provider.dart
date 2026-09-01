import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/training_model.dart';
import '../data/trainings_repository.dart';

final trainingsRepositoryProvider = Provider<TrainingsRepository>((ref) {
  return TrainingsRepository(client: ref.watch(apiClientProvider));
});

final teamTrainingsProvider = FutureProvider.autoDispose<List<Training>>((ref) async {
  final teamId = ref.watch(authControllerProvider).value?.teamId;
  if (teamId == null) return [];
  return ref.watch(trainingsRepositoryProvider).list(teamId: teamId);
});

final trainingSheetProvider = FutureProvider.autoDispose.family<TrainingSheet?, int>((ref, trainingId) {
  return ref.watch(trainingsRepositoryProvider).getSheet(trainingId);
});

final trainingSituationsProvider = FutureProvider.autoDispose.family<List<TrainingSituation>, int>((ref, trainingId) {
  return ref.watch(trainingsRepositoryProvider).listSituations(trainingId);
});
