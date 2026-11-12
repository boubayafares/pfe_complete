import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'team_model.dart';

/// HTTP-backed team management against the FootTech v2 backend.
class TeamsRepository {
  TeamsRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<Team>> listMine() async {
    final body = await _api.get(
      ApiConstants.teams,
      queryParameters: const {'limit': 100},
    );
    return (body['data'] as List<dynamic>)
        .map((row) => Team.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<Team?> getMyTeam(int teamId) async {
    final body = await _api.get('${ApiConstants.teams}/$teamId');
    return Team.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Team> create({
    required String name,
    String? category,
    String? description,
  }) async {
    final body = await _api.post(
      ApiConstants.teams,
      data: {'name': name, 'category': ?category, 'description': ?description},
    );
    return Team.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Team> update(int id, Map<String, dynamic> body) async {
    final resp = await _api.patch('${ApiConstants.teams}/$id', data: body);
    return Team.fromJson(resp['data'] as Map<String, dynamic>);
  }

  Future<void> remove(int id) async {
    await _api.delete('${ApiConstants.teams}/$id');
  }

  Future<List<TeamStaffMember>> getStaff(int teamId) async {
    final body = await _api.get('${ApiConstants.teams}/$teamId/staff');
    final data = body['data'] as List<dynamic>;
    return data
        .map((e) => TeamStaffMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates an Adjoint account (INACTIVE) and links it to the team. The
  /// Adjoint then self-activates via /auth/adjoint/activate (phone+code).
  Future<TeamStaffMember> addAdjoint(
    int teamId, {
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
  }) async {
    final body = await _api.post(
      '${ApiConstants.teams}/$teamId/staff',
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
      },
    );
    return TeamStaffMember.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> removeAdjoint(int teamId, int adjointId) async {
    await _api.delete('${ApiConstants.teams}/$teamId/staff/$adjointId');
  }
}
