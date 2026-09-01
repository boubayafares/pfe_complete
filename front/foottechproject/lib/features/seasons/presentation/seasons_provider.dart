import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../data/seasons_model.dart';
import '../data/seasons_repository.dart';

final seasonsRepositoryProvider = Provider<SeasonsRepository>((ref) {
  return SeasonsRepository(apiClient: ref.watch(apiClientProvider));
});

final seasonsListProvider = FutureProvider.autoDispose<List<Season>>((ref) {
  return ref.watch(seasonsRepositoryProvider).list();
});

final seasonProvider = FutureProvider.autoDispose.family<Season, int>((ref, id) {
  return ref.watch(seasonsRepositoryProvider).getById(id);
});
