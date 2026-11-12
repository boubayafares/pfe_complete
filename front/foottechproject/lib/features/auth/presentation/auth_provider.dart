import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    ref.listen(sessionExpiredProvider, (previous, next) {
      if (previous != next) state = const AsyncData(null);
    });
    return ref.read(authRepositoryProvider).restoreSession();
  }

  Future<void> registerCoach({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .registerCoach(
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            email: email,
            password: password,
          );
      // Coach is INACTIVE until OTP confirm; don't log them in yet.
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  /// Returns `true` when the account is INACTIVE and must confirm via OTP
  /// before it can log in (drives the UI to the Coach OTP screen).
  Future<bool> login({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      if (user == null) {
        state = const AsyncData(null);
        return true;
      }
      state = AsyncData(user);
      return false;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<void> verifyPlayerOtp({
    required String phone,
    required String code,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .verifyPlayerOtp(phone: phone, code: code),
    );
  }

  Future<void> requestPlayerOtp({required String phone}) {
    return ref.read(authRepositoryProvider).requestPlayerOtp(phone: phone);
  }

  Future<void> requestCoachOtp({required String email}) {
    return ref.read(authRepositoryProvider).requestCoachOtp(email: email);
  }

  Future<void> requestAdjointOtp({required String phone}) {
    return ref.read(authRepositoryProvider).requestAdjointOtp(phone: phone);
  }

  Future<void> verifyCoachOtp({
    required String email,
    required String code,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .verifyCoachOtp(email: email, code: code),
    );
  }

  /// BUG CORRIGÉ: prenait {userId, password} — voir AuthRepository et
  /// ActivateAdjointScreen. N'appelle plus le repository qu'avec la forme
  /// {phone, code, password} attendue par le backend patché. Ne touche pas
  /// `state` : réussir cet appel n'authentifie pas l'Adjoint, ça active
  /// juste son compte — il doit ensuite se connecter via /login.
  Future<void> setAdjointPassword({
    required String phone,
    required String code,
    required String password,
  }) {
    return ref
        .read(authRepositoryProvider)
        .setAdjointPassword(phone: phone, code: code, password: password);
  }

  /// Call after creating the Coach's first team so the cached profile's
  /// teamId stops being null without waiting for the next token refresh.
  Future<void> refreshProfile() async {
    final user = await ref.read(authRepositoryProvider).refreshProfile();
    state = AsyncData(user);
  }

  Future<void> selectTeam(int teamId) async {
    final previous = state.value;
    try {
      final user = await ref.read(authRepositoryProvider).selectTeam(teamId);
      state = AsyncData(user);
    } catch (error, stackTrace) {
      if (previous != null) state = AsyncData(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);
