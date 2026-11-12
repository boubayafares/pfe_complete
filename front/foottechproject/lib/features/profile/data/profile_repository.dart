import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'profile_model.dart';

/// HTTP-backed profile management against the FootTech v2 backend.
class ProfileRepository {
  ProfileRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<UserProfile> getById(int userId) async {
    final body = await _api.get('${ApiConstants.users}/$userId');
    return UserProfile.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile(
    int userId, {
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    final body = await _api.patch(
      '${ApiConstants.users}/$userId',
      data: {'firstName': ?firstName, 'lastName': ?lastName, 'email': ?email},
    );
    return UserProfile.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Uploads the avatar as multipart with field "avatar" (matches the backend
  /// multer route). [filePath] is used on mobile/desktop; on Web pass [bytes].
  Future<UserProfile> uploadAvatar(
    int userId, {
    String? filePath,
    List<int>? bytes,
    String? fileName,
  }) async {
    final body = await _api.uploadFile(
      '${ApiConstants.users}/$userId/avatar',
      fieldName: 'avatar',
      filePath: filePath,
      bytes: bytes,
      fileName: fileName,
    );
    return UserProfile.fromJson(body['data'] as Map<String, dynamic>);
  }
}
