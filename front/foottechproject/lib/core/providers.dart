import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'network/api_client.dart';
import 'network/socket_service.dart';
import 'services/local_auth_service.dart';
import 'storage/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final sessionExpiredProvider = StateProvider<int>((ref) => 0);

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(
    tokenStorage: storage,
    onSessionExpired: () => ref.read(sessionExpiredProvider.notifier).state++,
  );
});

final socketServiceProvider = Provider<SocketService>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final service = SocketService(tokenStorage: storage);
  ref.onDispose(service.disconnect);
  return service;
});

final localAuthServiceProvider = Provider<LocalAuthService>(
  (ref) => LocalAuthService(),
);
