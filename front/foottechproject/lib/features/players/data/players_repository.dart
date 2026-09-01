import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'player_model.dart';

/// HTTP-backed player management against the FootTech v2 backend.
class PlayersRepository {
  PlayersRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<PlayerProfile>> list({int? teamId, String? search}) async {
    final body = await _api.get(ApiConstants.players, queryParameters: {
      if (teamId != null) 'teamId': teamId,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    });
    final data = body['data'] as List<dynamic>;
    return data
        .map((e) => PlayerProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PlayerProfile> getProfile(int id) async {
    final body = await _api.get('${ApiConstants.players}/$id');
    return PlayerProfile.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<PlayerProfile> create({
    required String firstName,
    required String lastName,
    required String phone,
    required int teamId,
    String? posteP,
    String? piedFort,
    int? numeroMaillot,
  }) async {
    final body = await _api.post(ApiConstants.players, data: {
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'teamId': teamId,
      if (posteP != null) 'posteP': posteP,
      if (piedFort != null) 'piedFort': piedFort,
      if (numeroMaillot != null) 'numeroMaillot': numeroMaillot,
    });
    return PlayerProfile.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<PlayerProfile> update(int id, Map<String, dynamic> body) async {
    final resp = await _api.patch('${ApiConstants.players}/$id', data: body);
    return PlayerProfile.fromJson(resp['data'] as Map<String, dynamic>);
  }

  // --- Guardians -----------------------------------------------------------

  Future<List<Guardian>> listGuardians(int id) async {
    final body = await _api.get('${ApiConstants.players}/$id/guardians');
    final data = body['data'];
    if (data == null) return [];
    return (data as List<dynamic>)
        .map((e) => Guardian.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsertGuardian(int id, Map<String, dynamic> body) async {
    await _api.put('${ApiConstants.players}/$id/guardians', data: body);
  }

  // --- Address ---------------------------------------------------------------

  Future<PlayerAddress?> getAddress(int id) async {
    final body = await _api.get('${ApiConstants.players}/$id/address');
    final data = body['data'];
    if (data == null) return null;
    return PlayerAddress.fromJson(data as Map<String, dynamic>);
  }

  Future<void> upsertAddress(int id, Map<String, dynamic> body) async {
    await _api.put('${ApiConstants.players}/$id/address', data: body);
  }

  // --- School info ------------------------------------------------------------

  Future<SchoolInfo?> getSchoolInfo(int id) async {
    final body = await _api.get('${ApiConstants.players}/$id/school-info');
    final data = body['data'];
    if (data == null) return null;
    return SchoolInfo.fromJson(data as Map<String, dynamic>);
  }

  Future<void> upsertSchoolInfo(int id, Map<String, dynamic> body) async {
    await _api.put('${ApiConstants.players}/$id/school-info', data: body);
  }

  // --- Season profile ----------------------------------------------------------

  Future<List<SeasonProfile>> listSeasonProfiles(int id) async {
    final body = await _api.get('${ApiConstants.players}/$id/season-profile');
    final data = body['data'];
    if (data == null) return [];
    return (data as List<dynamic>)
        .map((e) => SeasonProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsertSeasonProfile(int id, Map<String, dynamic> body) async {
    await _api.put('${ApiConstants.players}/$id/season-profile', data: body);
  }

  // --- Injuries ---------------------------------------------------------------

  Future<List<PlayerInjury>> listInjuries(int id) async {
    final body = await _api.get('${ApiConstants.players}/$id/injuries');
    final data = body['data'];
    if (data == null) return [];
    return (data as List<dynamic>)
        .map((e) => PlayerInjury.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createInjury(int id, Map<String, dynamic> body) async {
    await _api.post('${ApiConstants.players}/$id/injuries', data: body);
  }
}
