import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import 'auth_models.dart';

/// HTTP-backed authentication against the FootTech v2 backend.
///
/// Registration, login, adjoint activation and player OTP all call the
/// Express API and store the returned JWT pair + user profile via
/// [TokenStorage]. [ApiClient] transparently refreshes on 401.
class AuthRepository {
  AuthRepository({required ApiClient apiClient, required this._tokenStorage})
    : _api = apiClient;

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  /// Creates the Coach account (INACTIVE). Does NOT persist tokens — the
  /// account must be confirmed via OTP before the user can log in.
  Future<void> registerCoach({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
  }) async {
    await _api.post(
      '${ApiConstants.auth}/register-coach',
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
        'password': password,
      },
    );
  }

  /// Email + password login for COACH / ADJOINT.
  ///
  /// Returns the logged-in [AuthUser] and persists tokens on success, or
  /// `null` when the backend reports `needsActivation: true` (an INACTIVE
  /// coach/adjoint that must first confirm via OTP before logging in).
  Future<AuthUser?> login({
    required String email,
    required String password,
  }) async {
    final body = await _api.post(
      '${ApiConstants.auth}/login',
      data: {'email': email, 'password': password},
    );
    final data = body['data'] as Map<String, dynamic>;
    if (data['needsActivation'] == true) return null;
    return _persistLoginBody(body);
  }

  /// Public adjoint self-activation (phone + code + password).
  Future<void> requestAdjointOtp({
    required String phone,
    String channel = 'SMS',
  }) async {
    await _api.post(
      '${ApiConstants.auth}/adjoint/request-otp',
      data: {'phone': phone, 'channel': channel},
    );
  }

  Future<void> setAdjointPassword({
    required String phone,
    required String code,
    required String password,
  }) async {
    await _api.post(
      '${ApiConstants.auth}/adjoint/activate',
      data: {'phone': phone, 'code': code, 'password': password},
    );
  }

  /// Request OTP to activate an INACTIVE Coach / Adjoint (email + flow).
  Future<void> requestCoachOtp({
    required String email,
    String channel = 'SMS',
  }) async {
    await _api.post(
      '${ApiConstants.auth}/coach/request-otp',
      data: {'email': email, 'channel': channel},
    );
  }

  /// Verify OTP to activate an INACTIVE Coach / Adjoint and log them in.
  Future<AuthUser> verifyCoachOtp({
    required String email,
    required String code,
  }) async {
    final body = await _api.post(
      '${ApiConstants.auth}/coach/verify-otp',
      data: {'email': email, 'code': code},
    );
    return _persistLoginBody(body);
  }

  Future<void> requestPlayerOtp({
    required String phone,
    String channel = 'SMS',
  }) async {
    await _api.post(
      '${ApiConstants.auth}/player/request-otp',
      data: {'phone': phone, 'channel': channel},
    );
  }

  Future<AuthUser> verifyPlayerOtp({
    required String phone,
    required String code,
  }) async {
    final body = await _api.post(
      '${ApiConstants.auth}/player/verify-otp',
      data: {'phone': phone, 'code': code},
    );
    return _persistLoginBody(body);
  }

  /// Refreshes the cached profile (teamId, status...) from GET /auth/me.
  Future<AuthUser> refreshProfile() async {
    final current = await restoreSession();
    if (current == null) {
      throw const ApiException(message: 'Session not found.');
    }
    final body = await _api.get('${ApiConstants.auth}/me');
    final user = AuthUser.fromJson(body['data'] as Map<String, dynamic>);
    await _persistUser(user);
    return user;
  }

  /// Selects one of the authenticated user's teams and rotates both JWTs so
  /// every team-scoped endpoint uses the same explicit context.
  Future<AuthUser> selectTeam(int teamId) async {
    final body = await _api.post(
      '${ApiConstants.auth}/select-team',
      data: {'teamId': teamId},
    );
    return _persistLoginBody(body);
  }

  Future<AuthUser?> restoreSession() async {
    final cached = await _tokenStorage.userProfileJson;
    if (cached == null) return null;
    try {
      final json = jsonDecode(cached) as Map<String, dynamic>;
      return AuthUser.fromJson(json['user'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('${ApiConstants.auth}/logout');
    } on ApiException {
      // Ignore network issues on logout; local tokens are cleared regardless.
    } finally {
      await _tokenStorage.clear();
    }
  }

  Future<AuthUser> _persistLoginBody(Map<String, dynamic> body) async {
    final data = body['data'] as Map<String, dynamic>;
    final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    final tokens = data['tokens'] as Map<String, dynamic>;
    await _tokenStorage.saveTokens(
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
    );
    await _persistUser(user);
    return user;
  }

  Future<void> _persistUser(AuthUser user) async {
    await _tokenStorage.saveUserProfileJson(
      jsonEncode({
        'user': {
          'id': user.id,
          'firstName': user.firstName,
          'lastName': user.lastName,
          'phone': user.phone,
          'email': user.email,
          'role': user.role,
          'accountStatus': user.accountStatus,
          'teamId': user.teamId,
        },
      }),
    );
  }
}
