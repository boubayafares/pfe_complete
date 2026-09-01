import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/profile_model.dart';
import '../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(apiClient: ref.watch(apiClientProvider));
});

final myProfileProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
  final userId = ref.watch(authControllerProvider).value?.id;
  if (userId == null) return null;
  return ref.watch(profileRepositoryProvider).getById(userId);
});
